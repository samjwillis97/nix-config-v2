{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.media.sonarr;
  postgresCfg = config.modules.database.postgres;
in
{
  options.modules.media.sonarr = {
    enable = mkEnableOption "Enables Sonarr";

    openFirewall = mkEnableOption "Open firewall for Prowlarr";

    port = mkOption {
      default = 8989;
      type = types.port;
    };
    apiKey = mkOption {
      default = "00000000000000000000000000000000";
      type = types.string;
    };

    database = {
      postgres = {
        enable = mkEnableOption "Use PostgreSQL for Prowlarr";

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
    modules.database.postgres = mkIf cfg.database.postgres.enable {
      databases = ["sonarr" "sonarr-logs"];
    };

    services.sonarr = {
      enable = true;
      openFirewall = cfg.openFirewall;
      settings = {
        server = {
         port = cfg.port;
        };
        auth = {
          apikey = cfg.apiKey;
        };
        postgres = mkIf cfg.database.postgres.enable {
          host = "127.0.0.1";
          port = 5432;
          user = postgresCfg.user;
          password = postgresCfg.password;
          maindb = "sonarr";
          logdb = "sonarr-logs";
        };
      };
    };
  };
}
