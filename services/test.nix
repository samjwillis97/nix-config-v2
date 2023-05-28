{ super, ... }: {
  # TODO: Fix me - why does my reverse proxy just not work :(
  services.nginx = {
    enable = true;

    # Use recommended settings
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
  };

  services.nginx.virtualHosts."nginx.${super.meta.hostname}" = {
    forceSSL = false;
    enableACME = false;

    locations."/" = {
      extraConfig = ''
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Host $host;
      '';
    };
  };

  virtualisation.oci-containers.containers = {
    hello-world = {
      image = "nginxdemos/hello";
      user = "root";
      ports = [ "8080:80" ]; # this should.. map container 80 to host 8080
    };
  };
}
