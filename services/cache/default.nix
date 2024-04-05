{ super, ... }:
{
  services.nix-serve = {
    enable = true;
    secretKeyFile = "/var/cache-priv-key.pem";
    port = 5000;
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    virtualHosts.${super.meta.hostname} = {
      locations."/".proxyPass = "http://localhost:5000";
    };
  };
}
