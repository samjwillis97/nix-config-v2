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

  realDebridTokenTemplate = "@real-debrid-token@";

  finalConfigFile = "${cfg.dataDirectory}/config.json";
  configFile = pkgs.writers.writeJSON "config.json" {
    bind_address = "";
    discord_webhook_url = "";
    url_base = "/";
    port = "${toString cfg.port}";
    log_level = "debug";
    qbittorrent = {
      download_folder = cfg.downloadDirectory;
      max_downloads = 0;
      refresh_interval = 30;
      skip_pre_cache = false;
    };
    repair = {
      auto_process = false;
      enabled = false;
      interval = "";
      strategy = "per_torrent";
      use_webdav = false;
      workers = 1;
      zurg_url = "";
    };
    webdav = {};
    rclone = {
      enabled = true;
      attr_timeout = "1s";
      buffer_size = "";
      cache_dir = "";
      dir_cache_time = "5m";
      gid = pgid;
      uid = puid;
      log_level = "DEBUG";
      mount_path = cfg.rclone.mountPath;
      no_checksum = false;
      no_modtime = false;
      umask = "002";
      vfs_cache_max_age = "1h";
      vfs_cache_max_size = "";
      vfs_cache_mode = "off";
      vfs_cache_poll_interval = "1m";
      vfs_read_ahead = "128k";
      vfs_read_chunk_size = "128M";
      vfs_read_chunk_size_limit = "off";
    };
    debrids = [
      {
        name = "realdebrid";
        add_samples = false;
        download_uncaches = false;
        unpack_rar = false;
        use_webdav = true;
        proxy = "";
        rclone_mount_path = "";
        api_key = realDebridTokenTemplate;
        rate_limit = "250/minute";
        folder = cfg.rclone.mountPath + "/realdebrid/__all__";
      }
    ];
    arrs = [];
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

    port = mkOption {
      default = 8282;
      type = types.port;
      description = "Port for Decypharr web interface";
    };

    dataDirectory = mkOption {
      type = types.str;
      default = "/var/lib/decypharr";
      description = "Directory for Decypharr data (config, database, etc)";
    };

    downloadDirectory = mkOption {
      type = types.str;
      default = "/var/lib/decypharr-downloads";
      description = "Directory for Decypharr downloads";
    };

    rclone = {
      mountPath = mkOption {
        type = types.str;
        default = "/mnt/decypharr";
        description = "Path where decypharr mounts remotes";
      };
    };

    realdebrid = {
      tokenFile = mkOption {
        type = types.str;
        default = "";
        description = "Path to Real-Debrid auth token file";
      };
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];

    boot.kernelModules = [
      "fuse"
    ];

    system.activationScripts.setupDecypharrDirs = lib.stringAfter [ "var" ]''
      ${pkgs.coreutils}/bin/mkdir -p ${cfg.dataDirectory}
      ${pkgs.coreutils}/bin/chown -R ${user}:${group} ${cfg.dataDirectory}
      ${pkgs.coreutils}/bin/cp ${configFile} ${finalConfigFile}

      secret=$(cat "${cfg.realdebrid.tokenFile}")
      ${pkgs.gnused}/bin/sed -i "s#${realDebridTokenTemplate}#$secret#" "${finalConfigFile}"

      ${pkgs.coreutils}/bin/mkdir -p ${cfg.downloadDirectory}
      ${pkgs.coreutils}/bin/chown -R ${user}:${group} ${cfg.downloadDirectory}

      ${pkgs.coreutils}/bin/mkdir -p ${cfg.rclone.mountPath}
      ${pkgs.coreutils}/bin/chown -R ${user}:${group} ${cfg.rclone.mountPath}
    '';

    systemd.services.docker-decypharr = {
      restartIfChanged = true;
      requiredBy = [ "docker-autoscan.service" ];
    };

    virtualisation.oci-containers.containers.decypharr = {
      pull = "missing";
      image = "cy01/blackhole:v1.1.3";
      ports = [ "${toString cfg.port}:${toString cfg.port}" ];
      volumes = [
        "${cfg.dataDirectory}:/app"
        "${cfg.downloadDirectory}:${cfg.downloadDirectory}"
        "${cfg.rclone.mountPath}:${cfg.rclone.mountPath}:rshared"
      ];
      devices = [
        "/dev/fuse:/dev/fuse:rwm"
      ];
      capabilities = {
        SYS_ADMIN = true;
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
