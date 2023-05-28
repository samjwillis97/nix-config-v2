{ super, ... }: {
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
