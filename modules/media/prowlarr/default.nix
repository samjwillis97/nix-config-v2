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
            "X-Api-Key" = cfg.apiKey;
            "Content-Type" = "application/json";
          };
          url = if (hasAttr "uri" args) then "localhost:${toString cfg.port}${args.uri}" else args.url;
        }
      ) [ "uri" ];
    in
    mkCurlCommand (curlArgs);

  prowlarrStatusCheck = mkProwlarrRequest { uri = "/ping"; };
in
{
  options.modules.media.prowlarr = {
    enable = mkEnableOption "Enables Prowlarr service";

    port = mkOption {
      default = 9696;
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

    indexers = mkOption {
      type = types.listOf types.attrs;
      default = [
        {
          name = "eztv";
          priority = 25;
          fields = {
            baseUrl = "https://eztvx.to/";
            torrentBaseSettings = {
              appMinimumSeeders = 10;
              seedRatio = 2;
            };
          };
        }
        {
          name = "isohunt2";
          priority = 25;
          fields = {
            torrentBaseSettings = {
              appMinimumSeeders = 10;
              seedRatio = 2;
            };
          };
        }
        # TODO: handle illegal chars in name
        # {
        #   name = "kickasstorrents-to";
        #   priority = 25;
        #   fields = {};
        # }
        {
          name = "limetorrents";
          priority = 25;
          fields = {
            torrentBaseSettings = {
              appMinimumSeeders = 10;
              seedRatio = 2;
            };
          };
        }
        {
          name = "thepiratebay";
          priority = 25;
          fields = {
            torrentBaseSettings = {
              appMinimumSeeders = 10;
              seedRatio = 2;
            };
          };
        }
        {
          name = "therarbg";
          priority = 25;
          fields = {
            torrentBaseSettings = {
              appMinimumSeeders = 10;
              seedRatio = 2;
            };
          };
        }
      ];
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

  # TODO: Sync Profiles
  config = mkIf cfg.enable {
    services.prowlarr.enable = true;

    system.activationScripts.makeProwlarrConfig =
      let
        configFile = pkgs.writeTextFile {
          name = "prowlarr-config.xml";
          text = ''
            <Config>
              <BindAddress>*</BindAddress>
              <Port>${toString cfg.port}</Port>
              <ApiKey>${cfg.apiKey}</ApiKey>
              <AuthenticationMethod>External</AuthenticationMethod>
              <LogLevel>${cfg.logLevel}</LogLevel>
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
          ${prowlarrStatusCheck}

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

    systemd.services.add-indexers = mkIf cfg.radarrConnection.enable {
      description = "adding indexers to prowlarr";
      wants = [
        "prowlarr.service"
        "tailscale-autoconnect.service"
        "create-radarr-prowlarr-connection.service"
      ];
      after = [
        "prowlarr.service"
        "tailscale-autoconnect.service"
        "create-radarr-prowlarr-connection.service"
      ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig.Type = "oneshot";
      script =
        let
          getIndexers = mkProwlarrRequest { uri = "/api/v1/indexer"; };
          getIndexerSchemas = mkProwlarrRequest { uri = "/api/v1/indexer/schema"; };
          flattenAttrs =
            attrs: prefix:
            let
              processAttr =
                attrName: attrValue:
                if builtins.isAttrs attrValue then
                  flattenAttrs attrValue (prefix + attrName + ".")
                else
                  [ (prefix + attrName) ];
            in
            builtins.concatLists (lib.mapAttrsToList processAttr attrs);

          getValueByPath =
            attrs: path:
            let
              components = lib.splitString "." path;
              traverse =
                attrSet: keys:
                if builtins.length keys == 0 then
                  attrSet
                else
                  traverse (attrSet.${builtins.head keys}) (builtins.tail keys);
            in
            traverse attrs components;
        in
        ''
          # Wait for prowlarr to be available
          ${prowlarrStatusCheck}

          Indexers=$(${getIndexers})
          Schemas=$(${getIndexerSchemas})

          echo "Starting to create missing indexers"
          ${builtins.concatStringsSep "\n" (
            builtins.map (v: ''
              ${v.name}Schema=$(echo $Schemas | ${pkgs.jq}/bin/jq '.[] | select(.definitionName == "${v.name}")')
              if [ -n "${v.name}Schema" ]; then

                if [ ! -z "$(echo $Indexers | ${pkgs.jq}/bin/jq '.[] | select(.definitionName == "${v.name}")')" ]; then
                  ${
                    mkProwlarrRequest {
                      uri = ''/api/v1/indexer/$(echo $Indexers | ${pkgs.jq}/bin/jq '.[] | select(.definitionName == "${v.name}") | .id')'';
                      method = "DELETE";
                    }
                  }
                fi

                echo "Creating ${v.name} indexer from schema"
                ${v.name}Indexer=$(echo "''$${v.name}Schema" | ${pkgs.jq}/bin/jq '.priority |= ${toString v.priority}')

                # TODO: think about letting appProfileId be configured
                ${v.name}Indexer=$(echo "''$${v.name}Schema" | ${pkgs.jq}/bin/jq '.appProfileId |= 1')
                ${
                  builtins.concatStringsSep "\n" (
                    builtins.map (fieldName: ''
                      ${v.name}Indexer=$(echo "''$${v.name}Indexer" | ${pkgs.jq}/bin/jq '.fields |= map(
                        if .name=="${fieldName}" then 
                          {name, value: ${
                            let
                              value = getValueByPath v.fields fieldName;
                            in
                            if builtins.typeOf value == "string" then
                              ''"${toString (getValueByPath v.fields fieldName)}"''
                            else
                              toString (getValueByPath v.fields fieldName)
                          }} 
                        else 
                          {name}  + (if .value then {value} else {} end)
                        end
                      )')
                    '') (flattenAttrs v.fields "")
                  )
                }

                echo "''$${v.name}Indexer" > /tmp/${v.name}-indexer
                ${
                  mkProwlarrRequest {
                    uri = "/api/v1/indexer";
                    method = "POST";
                    dataFile = "/tmp/${v.name}-indexer";
                  }
                }
              fi
            '') cfg.indexers
          )}
        '';
    };
  };
}
