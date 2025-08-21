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

    realDebridTokenFile = mkOption {
      type = types.str;
      default = "";
      description = "Auth token file for Real-Debrid";
    };

    mount = {
      enable = mkEnableOption "Mounts the zurg drive using rclone";

      path = mkOption {
        type = types.str;
        default = "/mnt/remote/zurg";
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

        rclone = mkIf cfg.mount.enable (
          let
            configFile = pkgs.writeText "rclone.conf" ''
              [zurg]
              type = webdav
              url = http://127.0.0.1:${toString cfg.port}/dav
              vendor = other
              pacer_min_sleep = 0
            '';
          in
          {
            pull = "missing";
            image = "rclone/rclone:latest";
            environment = {
              TZ = config.time.timeZone;
            };
            capabilities = {
              "SYS_ADMIN" = true;
            };
            devices = [
              "/dev/fuse:/dev/fuse:rwm"
            ];
            volumes = [
              "${cfg.mount.path}:/data:rshared"
              "${configFile}:/config/rclone/rclone.conf"
            ];
            cmd = [
              "mount"
              "zurg:"
              "/data"
              "--allow-non-empty"
              "--allow-other"
              "--uid=1000"
              "--gid=1000"
              "--umask=002"
              "--dir-cache-time"
              "10s"
            ];
            dependsOn = [ "zurg" ];
            extraOptions = mkIf dockerHostNetworkingEnabled [ "--network=host" ];
          }
        );
      };
  });
}
