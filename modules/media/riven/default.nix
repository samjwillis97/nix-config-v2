{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.media.riven;
  standardUserEnabled = config.modules.system.users.standardUser.enable;
  user = if standardUserEnabled then config.modules.system.users.standardUser.username else "docker";

  dockerHostNetworkingEnabled = config.modules.virtualisation.docker.useHostNetwork;
  boolToString = x: if x then "true" else "false";

  databaseUsername = config.modules.database.postgres.user;
  databasePassword = config.modules.database.postgres.password;
  databaseName = "riven";
in
{
  options.modules.media.riven = {
    enable = mkEnableOption "Enables Riven";

    openFirewall = mkEnableOption "Expose through firewall";

    webPort = mkOption {
      type = types.port;
      default = 3000;
      description = "Port for Riven web interface";
    };

    apiPort = mkOption {
      type = types.port;
      default = 8080;
      description = "Port for Riven API";
    };

    apiKey = mkOption {
      type = types.str;
      # Yes this is an API key, but its only used locally at the moment
      default = "VqohrdpIP7LQ0ZPp3CBq6YnZSQv3dg2o";
      description = "API key for Riven";
    };

    configDirectory = mkOption {
      type = types.str;
      default = "/opt/riven";
      description = "Directory for Riven configuration files";
    };

    libraryDirectory = mkOption {
      type = types.str;
      default = "${cfg.configDirectory}/library";
      description = "Directory for Riven library";
    };

    downloaders = {
      realDebrid = {
        enable = mkEnableOption "Enable Real-Debrid downloader";

        apiKeyFile = mkOption {
          type = types.str;
          default = "";
          description = "Real-Debrid API key file";
        };
      };
    };

    updaters = {
      plex = {
        enable = mkEnableOption "Enable Plex updater";

        url = mkOption {
          type = types.str;
          default = "http://127.0.0.1:32400";
          description = "URL for Plex server";
        };

        tokenFile = mkOption {
          type = types.str;
          default = "";
          description = "Plex API key file";
        };
      };
    };

    scrapers = {
      torrentio = {
        enable = mkEnableOption "Enable Torrentio scraper";
      };
    };
  };

  config = mkIf cfg.enable (
    {
      modules.database.postgres = {
        enable = true;
        databases = [
          databaseName
        ];
      };

      networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [
        cfg.webPort
        cfg.apiPort
      ];

      system.activationScripts.setupRivenDirs = lib.stringAfter [ "var" ]''
        ${pkgs.coreutils}/bin/mkdir -p ${cfg.libraryDirectory}
        ${pkgs.coreutils}/bin/chown -R ${user}:docker ${cfg.libraryDirectory}

        ${pkgs.coreutils}/bin/mkdir -p ${cfg.configDirectory}/frontend
        ${pkgs.coreutils}/bin/chown -R ${user}:docker ${cfg.configDirectory}/frontend
        ${pkgs.coreutils}/bin/mkdir -p ${cfg.configDirectory}/backend
        ${pkgs.coreutils}/bin/chown -R ${user}:docker ${cfg.configDirectory}/backend
      '';

      virtualisation.oci-containers.containers = {
        riven-frontend = let
          serverJson = pkgs.writers.writeJSON "server.json" {
            backendUrl = "http://127.0.0.1:${toString cfg.apiPort}";
            apiKey = cfg.apiKey;
          };
        in
        {
          pull = "missing";
          image = "spoked/riven-frontend:latest";
          autoStart = true;
          environment = {
            TZ = config.time.timeZone;
            ORIGIN = "http://localhost:${toString cfg.webPort}";
          };
          volumes = [
            "${cfg.configDirectory}/frontend:/riven/config"
            "${serverJson}:/riven/config/server.json"
          ];
          ports = [
            "${toString cfg.webPort}:${toString cfg.webPort}"
          ];
          extraOptions = mkIf dockerHostNetworkingEnabled [ "--network=host" ];
          dependsOn = [
            "riven-backend"
          ];
        };

        riven-backend = {
          pull = "missing";
          image = "spoked/riven:latest";
          autoStart = true;
          environment = {
            TZ = config.time.timeZone;
            API_KEY = cfg.apiKey;
            RIVEN_FORCE_ENV = boolToString true;
            RIVEN_SYMLINK_RCLONE_PATH = "/mnt/remote/zurg/__all__";
            RIVEN_SYMLINK_LIBRARY_PATH= "${cfg.libraryDirectory}"; # This is the path that symlinks will be placed in
            RIVEN_DATABASE_HOST = "postgresql+psycopg2://${databaseUsername}:${databasePassword}@127.0.0.1/${databaseName}";
            RIVEN_DOWNLOADERS_REAL_DEBRID_ENABLED = boolToString cfg.downloaders.realDebrid.enable;
            # Anti-pattern but i cbf
            RIVEN_DOWNLOADERS_REAL_DEBRID_API_KEY = lib.trim (builtins.readFile cfg.downloaders.realDebrid.apiKeyFile);

            RIVEN_UPDATERS_PLEX_ENABLED = boolToString cfg.updaters.plex.enable;
            RIVEN_UPDATERS_PLEX_URL = cfg.updaters.plex.url;
            # Anti-pattern but i cbf
            RIVEN_UPDATERS_PLEX_TOKEN = lib.trim (builtins.readFile cfg.updaters.plex.tokenFile);

            # RIVEN_CONTENT_OVERSEERR_ENABLED=true
            # RIVEN_CONTENT_OVERSEERR_URL=http://overseerr:5055
            # RIVEN_CONTENT_OVERSEERR_API_KEY=xxxxx # set your overseerr token

            RIVEN_SCRAPING_TORRENTIO_ENABLED = boolToString cfg.scrapers.torrentio.enable;

            # RIVEN_SCRAPING_ZILEAN_ENABLED=true
            # RIVEN_SCRAPING_ZILEAN_URL=http://zilean:8181
          };
          volumes = [
            "/mnt/remote/zurg/__all__:/mnt/remote/zurg/__all__"
            "${cfg.libraryDirectory}:${cfg.libraryDirectory}"
            "${cfg.configDirectory}/backend:/riven/data"
          ];
          ports = [
            "${toString cfg.webPort}:${toString cfg.webPort}"
          ];
          extraOptions = mkIf dockerHostNetworkingEnabled [ "--network=host" ];
          dependsOn = [
          ];
        };
       };
    }
  );
}
