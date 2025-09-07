{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.media.autoscan;

  dockerHostNetworkingEnabled = config.modules.virtualisation.docker.useHostNetwork;

  mediaUserEnabled = config.modules.system.users.media;
  user = if mediaUserEnabled then "media" else "docker";
  group = if mediaUserEnabled then "media" else "docker";

  puid = if mediaUserEnabled then config.users.users.media.uid else "1000";
  pgid = if mediaUserEnabled then config.users.groups.media.gid else "1000";

  plexTokenTemplate = "@plex-token@";

  finalConfigFile = "${cfg.dataDirectory}/config.yaml";
  configFile = pkgs.writers.writeYAML "config.yaml" {
    minimum-age = "0m";
    scan-delay = "5s";
    scan-stats = "1h";
    anchors = [
      "${cfg.debridMountLocation}/version.txt"
    ];
    port = cfg.port;
    triggers = {
      sonarr = [
        {
          name = "sonarr";
          priority = 1;
        }
      ];
    };
    targets = {
      plex = [] ++ (if cfg.plex.enable then [{
        url = cfg.plex.url;
        token = plexTokenTemplate;
      }] else []);
    };
  };
in
{
  options.modules.media.autoscan= {
    enable = mkEnableOption "Enables autoscan";

    openFirewall = mkEnableOption "Open firewall for autoscan";

    dataDirectory = mkOption {
      type = types.str;
      default = "/var/lib/autoscan";
      description = "Path to autoscan data directory";
    };

    port = mkOption {
      default = 3030;
      type = types.port;
      description = "Port for autoscan";
    };

    debridMountLocation = mkOption {
      type = types.str;
      default = "/mnt/decypharr/realdebrid";
      description = "Path where Real-Debrid fs is mounted";
    };

    plex = {
      enable = mkEnableOption "Enable Plex integration";

      url = mkOption {
        type = types.str;
        default = "http://localhost:32400";
        description = "URL to Plex server";
      };

      tokenFile = mkOption {
        type = types.str;
        default = "";
        description = "Path to Plex auth token file";
      };
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];

    system.activationScripts.setupAutopulseDirs = lib.stringAfter [ "var" ] ''
      ${pkgs.coreutils}/bin/mkdir -p ${cfg.dataDirectory}
      ${pkgs.coreutils}/bin/chown -R ${user}:${group} ${cfg.dataDirectory}
      ${pkgs.coreutils}/bin/cp ${configFile} ${finalConfigFile}

      ${optionalString cfg.plex.enable ''
        secret=$(cat "${cfg.plex.tokenFile}")
        ${pkgs.gnused}/bin/sed -i "s#${plexTokenTemplate}#$secret#" "${finalConfigFile}"
      ''}
    '';

    virtualisation.oci-containers.containers.autoscan = {
      pull = "missing";
      image = "saltydk/autoscan:latest";
      ports = [ "${toString cfg.port}:${toString cfg.port}" ];
      volumes = [
        "${cfg.debridMountLocation}:${cfg.debridMountLocation}"
        "${finalConfigFile}:/config/config.yml"
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
