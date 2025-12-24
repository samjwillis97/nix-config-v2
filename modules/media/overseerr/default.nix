{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.media.overseerr;
  dockerHostNetworkingEnabled = config.modules.virtualisation.docker.useHostNetwork;
in
{
  options.modules.media.overseerr = {
    enable = mkEnableOption "Enables Overseerr";

    dependsOn = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "List of containers that required";
    };

    port = mkOption {
      type = types.port;
      default = 5055;
      description = "Port for Overseerr web interface";
    };

    openFirewall = mkEnableOption "Open firewall for Overseerr";

    configDirectory = mkOption {
      type = types.str;
      default = "/opt/overseerr";
      description = "Directory for Overseerr configuration files";
    };

    dmmBridge = {
      enable = mkEnableOption "Enable DMM bridge (seerrbridge)";

      sharedLogDirectory = mkOption {
        type = types.str;
        default = "/opt/seerrbridge/logs";
        description = "Directory for DMM bridge logs";
      };

      apiPort = mkOption {
        type = types.port;
        default = 8777;
        description = "Port for DMM bridge API";
      };

      overseerrApiKeyFile = mkOption {
        type = types.str;
        default = "";
        description = "Overseerr API key for DMM bridge";
      };

      dmmAccessTokenFile = mkOption {
        type = types.str;
        default = "";
        description = "DMM access token for DMM bridge";
      };

      dmmRefreshTokenFile = mkOption {
        type = types.str;
        default = "";
        description = "DMM refresh";
      };

      dmmClientIdFile = mkOption {
        type = types.str;
        default = "";
        description = "DMM client ID for DMM bridge";
      };

      dmmClientSecretFile = mkOption {
        type = types.str;
        default = "";
        description = "DMM client secret for DMM bridge";
      };

      traktApiKeyFile = mkOption {
        type = types.str;
        default = "";
        description = "Trakt API key for DMM bridge";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      virtualisation.oci-containers.containers = {
        overseerr = {
          pull = "missing";
          image = "sctx/overseerr:latest";
          autoStart = true;
          volumes = [
            "${cfg.configDirectory}:/app/config"
          ];
          environment = {
            TZ = config.time.timeZone;
          };
          ports = [
            "${toString cfg.port}:5055"
          ];
          extraOptions = mkIf dockerHostNetworkingEnabled [ "--network=host" ];
          dependsOn = cfg.dependsOn;
        };
      };
    }
    (mkIf cfg.openFirewall {
      networking.firewall.allowedTCPPorts = [
        cfg.port
      ];
    })
    (mkIf cfg.dmmBridge.enable (
      let
        overseerrApiKeyTemplate = "@overseerr-api-key@";
        traktApiKeyTemplate = "@trakt-api-key@";
        dmmAccessTokenTemplate = "@dmm-access-token@";
        dmmRefreshTokenTemplate = "@dmm-refresh-token@";
        dmmClientIdTemplate = "@dmm-client-id@";
        dmmClientSecretTemplate = "@dmm-client@";

        finalConfigDir = "/var/lib/seerrbridge";

        envFile = (filter: pkgs.writeText "seerrbridge-env" ''
          RD_ACCESS_TOKEN=${dmmAccessTokenTemplate}
          RD_REFRESH_TOKEN=${dmmRefreshTokenTemplate}
          RD_CLIENT_ID=${dmmClientIdTemplate}
          RD_CLIENT_SECRET=${dmmClientSecretTemplate}

          TRAKT_API_KEY=${traktApiKeyTemplate}

          OVERSEERR_API_KEY=${overseerrApiKeyTemplate}
          OVERSEERR_BASE=http://127.0.0.1:${toString cfg.port}

          HEADLESS_MODE=true

          ENABLE_AUTOMATIC_BACKGROUND_TASK=true
          ENABLE_SHOW_SUBSCRIPTION_TASK=true

          REFRESH_INTERVAL_MINUTES=120

          MAX_MOVIE_SIZE=0
          MAX_EPISODE_SIZE=0

          TORRENT_FILTER_REGEX=${filter}
        '');

        filterRegexes = {
          "1080p" = { 
            regex = "^(?=.*(1080p|720p))(?!.*【.*?】)(?!.*[\\u0400-\\u04FF])(?!.*\\[esp\\]).*";
            configFile = "${finalConfigDir}/1080p.env";
            port = 8777;
          };
          "4K" ={
            regex = "^(?=.*(4K|2160p))(?!.*【.*?】)(?!.*[\\u0400-\\u04FF])(?!.*\\[esp\\]).*";
            configFile = "${finalConfigDir}/4K.env";
            port = 8778;
          };
        };

        seerrBridgeContainers = listToAttrs (mapAttrsToList (
          filterName: setupValues: {
            name = "seerrbridge-${filterName}";
            value = {
              pull = "missing";
              image = "ghcr.io/woahai321/seerrbridge:latest";
              autoStart = true;
              environment = {
                TZ = config.time.timeZone;
              };
              volumes = [
                "${envFile setupValues.configFile}:/app/.env"
              ];
              ports = [
                "${toString setupValues.port}:${toString setupValues.port}"
              ];
              cmd = [
                "uvicorn"
                "main:app"
                "--host"
                "0.0.0.0"
                "--port"
                "${toString setupValues.port}"
              ];
              extraOptions = mkIf dockerHostNetworkingEnabled [ "--network=host" ];
              dependsOn = [ "overseerr" ];
          };
        }) filterRegexes);

        activationScripts = listToAttrs (mapAttrsToList (
          name: value: {
            name = "seerrbridge-${name}-runtime-config-builder";
            value = ''
              mkdir -p ${finalConfigDir}
              overseerrApiKey=$(cat "${cfg.dmmBridge.overseerrApiKeyFile}")
              dmmAccessToken=$(cat "${cfg.dmmBridge.dmmAccessTokenFile}")
              dmmRefreshToken=$(cat "${cfg.dmmBridge.dmmRefreshTokenFile}")
              dmmClientId=$(cat "${cfg.dmmBridge.dmmClientIdFile}")
              dmmClientSecret=$(cat "${cfg.dmmBridge.dmmClientSecretFile}")
              traktApiKey=$(cat "${cfg.dmmBridge.traktApiKeyFile}")

              envFile="${envFile value.regex}"

              ${pkgs.gnused}/bin/sed "s#${overseerrApiKeyTemplate}#$overseerrApiKey#" "$envFile" | \
              ${pkgs.gnused}/bin/sed "s#${dmmAccessTokenTemplate}#$dmmAccessToken#" | \
              ${pkgs.gnused}/bin/sed "s#${dmmRefreshTokenTemplate}#$dmmRefreshToken#" | \
              ${pkgs.gnused}/bin/sed "s#${dmmClientIdTemplate}#$dmmClientId#" | \
              ${pkgs.gnused}/bin/sed "s#${dmmClientSecretTemplate}#$dmmClientSecret#" | \
              ${pkgs.gnused}/bin/sed "s#${traktApiKeyTemplate}#$traktApiKey#" > ${value.configFile}
            '';
        }) filterRegexes);

        forwarderScript = pkgs.writeShellScriptBin "seerrbridge-forwarder" ''
          payload=$1

          echo "Received payload: $payload"

          ${
            concatStringsSep "\n" (
              mapAttrsToList (
                filterName: setupValues: ''
                  filterName="http://127.0.0.1:${toString setupValues.port}/jellyseer-webhook/"
                  echo "Forwarding payload to ${filterName}: $filterName"
                  ${pkgs.curl}/bin/curl -X POST -H "Content-Type: application/json" -d "$payload" "$filterName"
                ''
              ) filterRegexes
            )
          }
        '';
      in
      {
        virtualisation.oci-containers.containers = seerrBridgeContainers;

        system.activationScripts = activationScripts;

        services.webhook = {
          enable = true;
          port = 9000;
          hooks = {
            jellyseer-webhook = {
              execute-command = "${forwarderScript}/bin/seerrbridge-forwarder";
              response-message = "Webhook received and forwarded";
              pass-arguments-to-command = [
                {
                  source = "entire-payload";
                }
              ];
            };
          };
        };
      }
    ))
  ]);
}
