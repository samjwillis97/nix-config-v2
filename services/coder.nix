{ pkgs, ... }:
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

  virtualisation.oci-containers.containers = {
    coder = {
      image = "ghcr.io/coder/coder:latest";
      user = "root";
      extraOptions = [ "--network=host" ];
      ports = [ "3000:3000" ];
      environment = {
        CODER_PG_CONNECTION_URL =
          "postgres://coder:coder@localhost/coder?sslmode=disable";
      };
    };
  };
}