{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  inherit (import ../../../lib/curl.nix { inherit pkgs; }) mkCurlCommand;

  cfg = config.modules.media.radarr;
  radarrCfg = config.services.radarr;
  mediaUserEnabled = config.modules.system.users.media;

  mkRadarrRequest =
    args:
    let
      curlArgs = removeAttrs (
        args
        // {
          headers = {
            "X-Api-Key" = cfg.config.apiKey;
            "Content-Type" = "application/json";
          };
          url = if (hasAttr "uri" args) then "localhost:${toString cfg.config.port}${args.uri}" else args.url;
        }
      ) [ "uri" ];
    in
    mkCurlCommand (curlArgs);
in
{
  options.modules.media.radarr = {
    enable = mkEnableOption "Enables Radarr";

    prometheus = {
      enable = mkEnableOption "Enable prometheus exporter";

      port = mkOption {
        default = 9708;
        type = types.port;
      };
    };

    config = {
      port = mkOption {
        default = 7878;
        type = types.port;
      };
      apiKey = mkOption {
        default = "00000000000000000000000000000000";
        type = types.string;
      };

      logLevel = mkOption {
        default = "info";
        type = types.enum [
          "info"
          "debug"
          "trace"
        ];
      };

      rootPaths = mkOption {
        default = [ "/data/media/movies" ];
        type = types.listOf types.str;
      };

      torrentClient = {
        enable = mkEnableOption "Enable torrent client";

        implementation = mkOption {
          default = "Deluge";
          type = types.enum [ "Deluge" ];
        };

        host = mkOption {
          type = types.string;
          default = "localhost";
        };

        port = mkOption {
          type = types.port;
          default = 80;
        };

        useSSL = mkOption {
          type = types.bool;
          default = false;
        };

        password = mkOption {
          type = types.string;
          default = "password";
        };
      };
    };
  };

  # Be careful with permissions issues for data folder
  #   This will hurt down the road a bit when actually trying to use

  # Configuration:
  #   Here is one way using the API: https://github.com/kira-bruneau/nixos-config/blob/5de7ec5e225075f4237722e38c5ec9fa2ed63e6a/environments/media-server.nix#L565
  config = mkIf cfg.enable {
    services.radarr = {
      enable = true;

      user = if mediaUserEnabled then "media" else "radarr";
      group = if mediaUserEnabled then "media" else "radarr";
    };

    services.prometheus = {
      exporters =
        {

        }
        // (mkIf cfg.prometheus.enable {
          exportarr-radarr = {
            enable = true;
            url = "http://127.0.0.1:${toString cfg.config.port}";
            port = cfg.prometheus.port;
            user = if mediaUserEnabled then "media" else "radarr";
            group = if mediaUserEnabled then "media" else "radarr";
            apiKeyFile = pkgs.writeTextFile {
              name = "radarr-key";
              text = cfg.config.apiKey;
            };
          };
        });
    };

    system.activationScripts.makeRadarrConfig =
      let
        configFile = pkgs.writeTextFile {
          name = "radarr-config.xml";
          text = ''
            <Config>
              <BindAddress>*</BindAddress>
              <Port>${toString cfg.config.port}</Port>
              <ApiKey>${cfg.config.apiKey}</ApiKey>
              <AuthenticationMethod>External</AuthenticationMethod>
              <LogLevel>${cfg.config.logLevel}</LogLevel>
              <AnalyticsEnabled>False</AnalyticsEnabled>
              <LogDbEnabled>False</LogDbEnabled>
              <InstanceName>Radarr</InstanceName>
              <!-- <SslPort>9898</SslPort> -->
              <!-- <EnableSsl>False</EnableSsl> -->
              <!-- <LaunchBrowser>True</LaunchBrowser> -->
              <!-- <AuthenticationRequired>DisabledForLocalAddresses</AuthenticationRequired> -->
              <!-- <Branch>master</Branch> -->
              <!-- <SslCertPath></SslCertPath> -->
              <!-- <SslCertPassword></SslCertPassword> -->
              <!-- <UrlBase></UrlBase> -->
            </Config>'';
        };
        user = radarrCfg.user;
        group = radarrCfg.group;
        outputFile = "${radarrCfg.dataDir}/config.xml";
      in
      lib.stringAfter [ "var" ] ''
        ${pkgs.coreutils}/bin/cp ${configFile} ${outputFile}
        ${pkgs.coreutils}/bin/chown ${user}:${group} ${outputFile}
        ${pkgs.coreutils}/bin/chmod 444 ${outputFile}
      '';

    systemd.services.create-radarr-dl-client = mkIf cfg.config.torrentClient.enable {
      description = "configuring radarr torrent client";
      wants =
        [ "radarr.service" ]
        ++ (
          if (config.modules.networking.tailscale.enable) then [ "tailscale-autoconnect.service" ] else [ ]
        );
      after =
        [ "radarr.service" ]
        ++ (
          if (config.modules.networking.tailscale.enable) then [ "tailscale-autoconnect.service" ] else [ ]
        );
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "oneshot";
      script =
        let
          status = mkRadarrRequest { uri = "/ping"; };
          getAllClients = mkRadarrRequest { uri = "/api/v3/downloadclient"; };
          downloadClient = pkgs.writers.writeJSON "dl-client" {
            enable = true;
            protocol = "torrent";
            priority = 1;
            removeCompletedDownloads = true;
            removeFailedDownloads = true;
            name = cfg.config.torrentClient.implementation;
            fields = [
              {
                order = 0;
                name = "host";
                value = cfg.config.torrentClient.host;
              }
              {
                order = 1;
                name = "port";
                value = cfg.config.torrentClient.port;
              }
              {
                order = 2;
                name = "useSsl";
                value = cfg.config.torrentClient.useSSL;
              }
              {
                order = 3;
                name = "urlBase";
              }
              {
                order = 4;
                name = "password";
                value = cfg.config.torrentClient.password;
              }
              {
                order = 5;
                name = "movieCategory";
                value = "radarr";
              }
              {
                order = 6;
                name = "movieImportedCategory";
              }
              {
                order = 7;
                name = "recentMoviePriority";
                value = 0;
                selectOptions = [
                  {
                    value = 0;
                    name = "Last";
                    order = 0;
                    dividerAfter = false;
                  }
                  {
                    value = 1;
                    name = "First";
                    order = 1;
                    dividerAfter = false;
                  }
                ];
              }
              {
                order = 8;
                name = "olderMoviePriority";
                value = 0;
                selectOptions = [
                  {
                    value = 0;
                    name = "Last";
                    order = 0;
                    dividerAfter = false;
                  }
                  {
                    value = 1;
                    name = "First";
                    order = 1;
                    dividerAfter = false;
                  }
                ];
              }
              {
                order = 9;
                name = "addPaused";
                value = false;
              }
              {
                order = 10;
                name = "downloadDirectory";
              }
              {
                order = 11;
                name = "completedDirectory";
              }
            ];
            implementation = cfg.config.torrentClient.implementation;
            configContract = "${cfg.config.torrentClient.implementation}Settings";
            tags = [ ];
          };
          createDlClient = mkRadarrRequest {
            uri = "/api/v3/downloadclient";
            method = "POST";
            dataFile = downloadClient;
          };
        in
        ''
          echo "Checking Radarr status"
          ${status}

          # Just making sure hostname is available - will error out if not
          echo "Making sure Torrent client is available"
          ${pkgs.iputils}/bin/ping -c1 -W10 ${cfg.config.torrentClient.host}

          AllClients=$(${getAllClients})
          TorrentClient=$(echo $AllClients | ${pkgs.jq}/bin/jq '.[] | select(.name=="${cfg.config.torrentClient.implementation}") | .id')

          if [ ! -z ''${TorrentClient} ]; then
            echo "Deleting old torrent client"
            ${
              mkRadarrRequest {
                uri = "/api/v3/downloadclient/$TorrentClient";
                method = "DELETE";
              }
            }
          else
            echo "No torrent client exists"
          fi

          echo "Creating new torrent client"
          ${createDlClient}
        '';
    };

    systemd.services.radarr-root-paths = mkIf cfg.config.torrentClient.enable {
      description = "setting radarr root paths";
      wants = [ "radarr.service" ];
      after = [ "radarr.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "oneshot";
      script =
        let
          status = mkRadarrRequest { uri = "/ping"; };
          getRootPaths = mkRadarrRequest { uri = "/api/v3/rootfolder"; };
        in
        ''
          ${status}

          RootPaths=$(${getRootPaths})

          ${builtins.concatStringsSep "\n" (
            builtins.map (path: ''
              if [ ! -z "$(echo $RootPaths | ${pkgs.jq}/bin/jq '.[] | select(.path == "${path}")')" ]; then
                ${
                  mkRadarrRequest {
                    uri = ''/api/v3/rootfolder/$(echo $RootPaths | ${pkgs.jq}/bin/jq '.[] | select(.path == "${path}") | .id')'';
                    method = "DELETE";
                  }
                }
              fi

              ${mkRadarrRequest {
                uri = "/api/v3/rootfolder";
                method = "POST";
                dataFile = pkgs.writers.writeJSON "${path}-root-path" { path = path; };
              }}
            '') cfg.config.rootPaths
          )}
        '';
    };
  };
}
