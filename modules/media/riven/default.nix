{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.media.riven;
  dockerHostNetworkingEnabled = config.modules.virtualisation.docker.useHostNetwork;
  boolToString = x: if x then "true" else "false";
in
{
  options.modules.media.riven = {
    enable = mkEnableOption "Enables Riven";

    openFirewall = mkEnableOption "Expose through firewall";
  };

  config = mkIf cfg.enable (
    {
      services.postgresql = {
        enable = true;
        # Adding postgres user with postgres password and creating initial DB
        initialScript = pkgs.writeText "init-sql-script" ''
          ALTER USER postgres with PASSWORD 'postgres';
          CREATE DATABASE riven WITH OWNER = postgres;
        '';

        # Allowing access from command line with `psql -U postgres -W -h localhost`
        authentication = pkgs.lib.mkAfter ''
          # TYPE  DATABASE        USER            ADDRESS         METHOD
          host    all             all             127.0.0.1/32    md5
        '';
      };

      virtualisation.oci-containers.containers = {
        riven-frontend = {
          pull = "missing";
          image = "spoked/riven-frontend:latest";
          autoStart = true;
          environment = {
            TZ = config.time.timeZone;
            ORIGIN = "http://localhost:3000";
            BACKEND_URL = "http://127.0.0.1:8080";
            DIALECT = "postgres";
            DATABASE_URL = "postgres://postgres:postgres@127.0.0.1/riven";
          };
          ports = [
            "3000:3000"
          ];
          extraOptions = mkIf dockerHostNetworkingEnabled [ "--network=host" ];
        };

        riven-backend = {
          pull = "missing";
          image = "spoked/riven:latest";
          autoStart = true;
          environment = {
            TZ = config.time.timeZone;
            RIVEN_FORCE_ENV = "true";
            RIVEN_DATABASE_HOST = "postgresql+psycopg2://postgres:postgres@127.0.0.1/riven";
          };
          volumes = [
            "/riven:/riven/data"
          ];
          ports = [
            "8080:8080"
          ];
          extraOptions = mkIf dockerHostNetworkingEnabled [ "--network=host" ];
        };
      };
    }
  );
}
