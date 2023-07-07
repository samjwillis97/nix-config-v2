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

  # FIXME: So what I'm thinking is create a new nixos module for docker and nginx and import them into this
  # Include the oci-contianers backend in that too 

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
      extraConfig = ''
        proxy_pass http://localhost:3000;
        proxy_pass_header Authorization;
        proxy_http_version 1.1;
        proxy_ssl_server_name on;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Host $host;
      '';
    };
  };

  virtualisation.docker.enable = true;
  # virtualisation.docker.extraOptions = "--iptables=false --ip6tables=false";
  networking.firewall = {
    # always allow traffic from your docker0 network
    trustedInterfaces = [ "docker0" ];
  };

  # See: https://github.com/ghuntley/ghuntley/blob/c234e2180693304bc6ea17c4862bbb2f807e8727/.github/workflows/services-dev-ghuntley-templates-push.yml#L12
  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      coder = {
        image = "ghcr.io/coder/coder:latest";
        user = "root";
        extraOptions = [ "--network=host" ];
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
