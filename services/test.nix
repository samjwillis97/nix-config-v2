{ super, ... }:
{
  # TODO: Fix me - why does my reverse proxy just not work :(
  services.nginx = {
    enable = true;

    # Use recommended settings
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
  };

  services.nginx.virtualHosts."${super.meta.hostname}" = {
    forceSSL = false;
    enableACME = false;

    locations."/" = {
      proxyPass = "http://localhost:8080";
      recommendedProxySettings = true;
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
