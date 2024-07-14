{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  inherit (import ../../../lib/curl.nix { inherit pkgs; }) mkCurlCommand;

  cfg = config.modules.media.prowlarr;

  mkProwlarrRequest =
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
  options.modules.media.prowlarr = {
    enable = mkEnableOption "Enables Prowlarr service";

    config = {
      port = mkOption {
        default = 9696;
        type = types.port;
      };
      apiKey = mkOption {
        default = "00000000000000000000000000000000";
        type = types.string;
      };
    };

    radarrConnection = {
      enable = mkEnableOption "enables radarr connection";

      useSSL = mkOption {
        default = false;
        type = types.bool;
      };

      hostname = mkOption {
        default = "localhost";
        type = types.string;
      };

      port = mkOption {
        default = 7878;
        type = types.port;
      };

      apiKey = mkOption {
        default = "00000000000000000000000000000000";
        type = types.string;
      };
    };
  };

  config = mkIf cfg.enable {
    services.prowlarr.enable = true;

    system.activationScripts.makeProwlarrConfig =
      let
        configFile = pkgs.writeTextFile {
          name = "prowlarr-config.xml";
          text = ''
            <Config>
              <BindAddress>*</BindAddress>
              <Port>${toString cfg.config.port}</Port>
              <ApiKey>${cfg.config.apiKey}</ApiKey>
              <AuthenticationMethod>External</AuthenticationMethod>
              <LogLevel>info</LogLevel>
              <AnalyticsEnabled>False</AnalyticsEnabled>
              <LogDbEnabled>False</LogDbEnabled>
              <InstanceName>Prowlarr</InstanceName>
            </Config>'';
        };
        owner = "prowlarr";
        group = "prowlarr";
        outputFile = "/var/lib/prowlarr/config.xml";
      in
      lib.stringAfter [ "var" ] ''
        ${pkgs.coreutils}/bin/cp ${configFile} ${outputFile}
        ${pkgs.coreutils}/bin/chown ${owner}:${group} ${outputFile}
        ${pkgs.coreutils}/bin/chmod 644 ${outputFile}
      '';

    systemd.services.create-radarr-prowlarr-connection = mkIf cfg.radarrConnection.enable {
      description = "setting radarr in prowlarr";
      wants = [
        "prowlarr.service"
        "tailscale-autoconnect.service"
      ];
      after = [
        "prowlarr.service"
        "tailscale-autoconnect.service"
      ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "oneshot";
      script =
        let
          status = mkProwlarrRequest { uri = "/ping"; };
          getAllApps = mkProwlarrRequest { uri = "/api/v1/applications"; };
          radarrApp = pkgs.writers.writeJSON "radarr-app" {
            syncLevel = "fullSync";
            name = "Radarr";
            fields = [
              {
                order = 0;
                name = "prowlarrUrl";
                value = "http://${config.networking.hostName}";
              }
              {
                order = 1;
                name = "baseUrl";
                value = "${
                  if cfg.radarrConnection.useSSL then "https://" else "http://"
                }${cfg.radarrConnection.hostname}:${toString cfg.radarrConnection.port}";
              }
              {
                order = 2;
                name = "apiKey";
                value = cfg.radarrConnection.apiKey;
              }
              {
                order = 3;
                name = "syncCategories";
                value = [
                  2000 # Movies
                  2010 # Movies/Foreign
                  2020 # Movies/Other
                  2030 # Movies/SD
                  2040 # Movies/HD
                  2045 # Movies/UHD
                  2050 # Movies/BluRay
                  2060 # Movies/3D
                  2070 # Movies/DVD
                  2080 # Movies/WEB-DL
                  2090 # Movies/x265
                ];
              }
              {
                order = 4;
                name = "syncRejectBlocklistedTorrentHashesWhileGrabbing";
                value = false;
              }
            ];
            implementationName = "Radarr";
            implementation = "Radarr";
            configContract = "RadarrSettings";
            infoLink = "https://wiki.servarr.com/prowlarr/supported#radarr";
            tags = [ ];
          };
          createRadarrApp = mkProwlarrRequest {
            uri = "/api/v1/applications";
            method = "POST";
            dataFile = radarrApp;
          };
        in
        ''
          # Wait for prowlarr to be available
          ${status}

          # Wait for radarr to be available
          ${pkgs.iputils}/bin/ping -c1 -W10 ${cfg.radarrConnection.hostname}

          AllApps=$(${getAllApps})
          RadarrApp=$(echo $AllApps | ${pkgs.jq}/bin/jq '.[] | select(.name=="Radarr") | .id')

          if [ ! -z ''${RadarrApp} ]; then
            echo "Deleting old radarr app"
            ${
              mkProwlarrRequest {
                uri = "/api/v1/applications/$RadarrApp";
                method = "DELETE";
              }
            }
          fi

          echo "Creating new radarr app"
          ${createRadarrApp}
        '';
    };
  };
}
