{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.media.dispatcharr;

  dockerHostNetworkingEnabled = config.modules.virtualisation.docker.useHostNetwork;

  mediaUserEnabled = config.modules.system.users.media;
  user = if mediaUserEnabled then "media" else "docker";
  group = if mediaUserEnabled then "media" else "docker";

  puid = if mediaUserEnabled then config.users.users.media.uid else "1000";
  pgid = if mediaUserEnabled then config.users.groups.media.gid else "1000";
in
{
  options.modules.media.dispatcharr = {
    enable = mkEnableOption "Enables Dispatcharr";

    openFirewall = mkEnableOption "Open firewall for Dispatcharr";

    port = mkOption {
      default = 9191;
      type = types.port;
      description = "Port for Dispatcharr web interface";
    };

    dataDirectory = mkOption {
      type = types.str;
      default = "/var/lib/dispatcharr";
      description = "Directory for Dispatcharr data (config, database, etc)";
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];

    system.activationScripts.setupDispatcharrDirs = lib.stringAfter [ "var" ] ''
      ${pkgs.coreutils}/bin/mkdir -p ${cfg.dataDirectory}
    '';

    virtualisation.oci-containers.containers.dispatcharr = {
      pull = "missing";
      image = "ghcr.io/dispatcharr/dispatcharr:latest";
      ports = [ "${toString cfg.port}:${toString cfg.port}" ];
      volumes = [
        "${cfg.dataDirectory}:/data"
      ];
      devices = [
      ];
      capabilities = {
      };
      environment = {
        PUID = toString puid;
        PGID = toString pgid;
        TZ = config.time.timeZone;
      };
      extraOptions = mkIf dockerHostNetworkingEnabled [ "--network=host" ];
    };
  };
}
