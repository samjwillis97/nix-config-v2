{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.media.zurg;
  dockerHostNetworkingEnabled = config.modules.virtualisation.docker.useHostNetwork;
in
{
  options.modules.media.zurg = {
    enable = mkEnableOption "Enables zurg";

    port = mkOption {
      type = types.port;
      default = 9999;
      description = "Port for the zurg service";
    };

    openFirewall = mkEnableOption "Open firewall for zurg port";

    realDebridTokenFile = mkOption {
      type = types.str;
      default = "";
      description = "Auth token file for Real-Debrid";
    };

    mount = {
      enable = mkEnableOption "Mounts the zurg drive using rclone";

      path = mkOption {
        type = types.str;
        default = "/mnt/zurg";
        description = "Path to mount the zurg drive";
      };
    };
  };

  config = mkIf cfg.enable (
    let 
      debridTokenTemplate = "@debrid-token@";
      finalConfigDir = "/var/lib/zurg";
      finalConfigFile = "${finalConfigDir}/settings.yaml";

      configFile = pkgs.writers.writeYAML "settings.yaml" {
        # Zurg configuration version
        zurg = "v1";

        token = debridTokenTemplate;

        host = "[::]";
        port = 9999;

        directories = {
          torrents = {
            group = 1;
            filters = [
              {
                regex = "/.*/";
              }
            ];
          };
        };
      };
    in
    {
      system.activationScripts."zurg-runtime-config-builder" = ''
        mkdir -p ${finalConfigDir}
        secret=$(cat "${cfg.realDebridTokenFile}")
        configFile="${configFile}"
        ${pkgs.gnused}/bin/sed "s#${debridTokenTemplate}#$secret#" "$configFile" > ${finalConfigFile}
      '';

      boot.kernelModules = mkIf cfg.mount.enable [
        "fuse"
      ];

      modules.storage.rclone = mkIf cfg.mount.enable {
        enable = true;
        mounts.zurg = {
          mountLocation = cfg.mount.path;
          settings = {
            type = "webdav";
            url = "http://127.0.0.1:${toString cfg.port}/dav";
            vendor = "other";
            pacer_min_sleep = "0";
          };
          deviceOptions = [
            "allow_non_empty"
            "allow_other"
          ];
        };
      };

      networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [
        cfg.port
      ];

      virtualisation.oci-containers.containers = {
        zurg =
          {
            pull = "missing";
            image = "ghcr.io/debridmediamanager/zurg-testing:v0.9.3-final"; # Jul 13 2024
            autoStart = true;
            environment = {
              TZ = config.time.timeZone;
            };
            ports = [ "${toString cfg.port}:9999" ];
            volumes = [
              "${finalConfigFile}:/app/config.yml"
            ];
            extraOptions = mkIf dockerHostNetworkingEnabled [ "--network=host" ];
          };
      };
  });
}
