{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.media.autopulse;
  postgresCfg = config.modules.database.postgres;

  dockerHostNetworkingEnabled = config.modules.virtualisation.docker.useHostNetwork;

  mediaUserEnabled = config.modules.system.users.media;

  user = if mediaUserEnabled then "media" else "docker";
  group = if mediaUserEnabled then "media" else "docker";

  puid = if mediaUserEnabled then config.users.users.media.uid else "1000";
  pgid = if mediaUserEnabled then config.users.groups.media.gid else "1000";

  plexTokenTemplate = "@plex-token@";

  finalConfigDir = "/var/lib/autopulse";
  finalConfigFile = "${finalConfigDir}/settings.yaml";

  configFile = pkgs.writers.writeYAML "settings.yaml" {
    auth = {
      username = cfg.auth.username;
      password = cfg.auth.password;
    };
    triggers = {
      sonarr = {
        type = "sonarr";
      };
    };
    targets = { } //
      (if cfg.plex.enable then {
        plex = {
          type = "plex";
          url = cfg.plex.url;
          token = plexTokenTemplate;
        };
      } else {});
  };

in
{
  options.modules.media.autopulse = {
    enable = mkEnableOption "Enables Autopulse";

    openFirewall = mkEnableOption "Open firewall for Autopulse port";

    port = mkOption {
      type = types.port;
      default = 2875;
      description = "Port for the Autopulse service";
    };

    auth = {
      username = mkOption {
        type = types.string;
        default = "admin";
        description = "Username for Autopulse API";
      };

      password = mkOption {
        type = types.string;
        default = "admin";
        description = "Password for Autopulse API";
      };
    };

    plex = {
      enable = mkEnableOption "Enable Plex integration";

      url = mkOption {
        type = types.string;
        default = "http://localhost:32400";
        description = "Plex server URL";
      };

      tokenFile = mkOption {
        type = types.string;
        default = "";
        description = "Plex server token";
      };
    };

    database = {
      postgres = {
        enable = mkEnableOption "Use Postgres for Autopulse database";

        user = mkOption {
          default = postgresCfg.user;
          type = types.string;
        };

        password = mkOption {
          default = postgresCfg.password;
          type = types.string;
        };
      };
    };
  };

  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];

    system.activationScripts.setupAutopulseDirs = lib.stringAfter [ "var" ] ''
      ${pkgs.coreutils}/bin/mkdir -p ${finalConfigDir}
      ${pkgs.coreutils}/bin/chown -R ${user}:${group} ${finalConfigDir}
      ${pkgs.coreutils}/bin/cp ${configFile} ${finalConfigFile}

      ${optionalString cfg.plex.enable ''
        secret=$(cat "${cfg.plex.tokenFile}")
        ${pkgs.gnused}/bin/sed -i "s#${plexTokenTemplate}#$secret#" "${finalConfigFile}"
      ''}
    '';

    modules.database.postgres = mkIf cfg.database.postgres.enable {
      databases = [ "autopulse" ];
    };

    virtualisation.oci-containers.containers.autopulse = {
      pull = "missing";
      image = "ghcr.io/dan-online/autopulse:latest";
      ports = [ "${toString cfg.port}:${toString cfg.port}" ];
      environment = {
        PUID = toString puid;
        PGID = toString pgid;
        TZ = config.time.timeZone;
        AUTOPULSE__APP__DATABASE_URL = "postgres://${cfg.database.postgres.user}:${cfg.database.postgres.password}@127.0.0.1/autopulse";
      };
      volumes = [
        "${finalConfigFile}:/app/config.yaml"
      ];
      extraOptions = mkIf dockerHostNetworkingEnabled [ "--network=host" ];
    };
  };
}
