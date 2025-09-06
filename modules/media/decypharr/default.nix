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

  configFile = pkgs.writers.writeJSON "config.json" {
    url_base = "/";
    port = "8282";
    log_level = "info";
    qbittorrent = {

    };
    repair = {
      strategy = "per_torrent";
    };
    webdav = {};
    rclone = {};
    allowed_file_types = [
      "mp4"
      "mkv"
      "srt"
      "avi"
      "mov"
      "divx"
    ];
  };
in
{
  options.modules.media.decypharr = {
    enable = mkEnableOption "Enables Decypharr";

    openFirewall = mkEnableOption "Open firewall for Decypharr";

    dataDirectory = mkOption {
      type = types.str;
      default = "/var/lib/decypharr";
      description = "Directory for Decypharr data (config, database, etc)";
    };

    port = mkOption {
      default = 8282;
      type = types.port;
      description = "Port for Decypharr web interface";
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];

    system.activationScripts.setupDecypharrDirs = lib.stringAfter [ "var" ]''
      ${pkgs.coreutils}/bin/mkdir -p ${cfg.dataDirectory}
      ${pkgs.coreutils}/bin/chown -R ${user}:${group} ${cfg.dataDirectory}
      ${pkgs.coreutils}/bin/cp ${configFile} ${cfg.dataDirectory}/config.json
    '';

    virtualisation.oci-containers.containers.decypharr = {
      pull = "missing";
      image = "cy01/blackhole:latest";
      ports = [ "${toString cfg.port}:8282" ];
      volumes = [
        "${cfg.dataDirectory}:/app"
      ];
      environment = {
        PUID = toString puid;
        PGID = toString pgid;
        TZ = config.time.timeZone;
      };
      extraOptions = mkIf dockerHostNetworkingEnabled [ "--network=host" ];
    };
  };
}
