{ super, pkgs, ... }:
let
  # FIXME: WHy doesn't ghuntely need all this user stuff?
  postgres_config = pkgs.writeTextFile {
    name = "postgres_config";
    text = ''
      CREATE ROLE coder LOGIN SUPERUSER PASSWORD 'coder';
      CREATE DATABASE coder;
    '';
  };
in {
  # TODO: Think about how this could interract if another service wanted postgres...
  # what would be the best way forward there?

  services.postgresql.package = pkgs.postgresql_14;
  services.postgresql.enable = true;
  services.postgresql.initialScript = postgres_config;

  services.postgresqlBackup.enable = true;
  services.postgresqlBackup.databases = [ "coder" ];
  services.postgresqlBackup.location = "/var/lib/postgresql/backups";

  services.nginx = {
    enable = true;

    # Use recommended settings
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
  };

  services.nginx.virtualHosts."${super.meta.hostname}.tailfba7c.ts.net" = {
    forceSSL = false;
    enableACME = false;

    locations."/" = {
      proxyPass = "http://localhost:3000";
      recommendedProxySettings = true;
    };
  };

  virtualisation.docker.enable = true;
  # See: https://github.com/ghuntley/ghuntley/blob/c234e2180693304bc6ea17c4862bbb2f807e8727/.github/workflows/services-dev-ghuntley-templates-push.yml#L12
  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      coder = {
        image = "ghcr.io/coder/coder:latest";
        user = "root";
        ports = [ "3000:3000" ];
        volumes = [
          "/srv/coder:/home/coder:cached"
          "/var/run/docker.sock:/var/run/docker.sock"
        ];
        environment = {
          CODER_ACCESS_URL = "http://${super.meta.hostname}.tailfba7c.ts.net";
          CODER_DISABLE_PASSWORD_AUTH = "false";
          CODER_PG_CONNECTION_URL =
            "postgres://coder:coder@localhost/coder?sslmode=disable";
        };
      };
    };
  };
}
