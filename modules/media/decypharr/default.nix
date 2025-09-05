{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.media.decypharr;

  dockerHostNetworkingEnabled = config.modules.virtualisation.docker.useHostNetwork;

  mediaUserEnabled = config.modules.system.users.media;
  user = if mediaUserEnabled then "media" else "docker";
  group = if mediaUserEnabled then "media" else "docker";

  puid = if mediaUserEnabled then config.users.users.media.uid else "1000";
  pgid = if mediaUserEnabled then config.users.groups.media.gid else "1000";
in
{
  options.modules.media.decypharr = {
    enable = mkEnableOption "Enables Decypharr";

    openFirewall = mkEnableOption "Open firewall for Decypharr";

    port = mkOption {
      default = 8282;
      type = types.port;
      description = "Port for Decypharr web interface";
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];

    virtualisation.oci-containers.containers.decypharr = {
      pull = "missing";
      image = "cy01/blackhole:latest";
      ports = [ "${toString cfg.port}:8282" ];
      volumes = [
        # "/var/lib/decypharr/config:/config"
      ];
      environment = {
        PUID = toString puid; # media user
        PGID = toString pgid; # media group
        TZ = config.time.timeZone;
      };
      extraOptions = mkIf dockerHostNetworkingEnabled [ "--network=host" ];
    };
  };
}
