{ config, ... }:
{
  imports = [ ../../modules/home-automation/hass.nix ];

  modules.home-automation.hass = {
    enable = true;
    reverseProxyOrigins = [ "127.0.0.1" ];
  };

  services.nginx = {
    enable = true;

    recommendedProxySettings = true;
    recommendedTlsSettings = false;

    virtualHosts.${config.networking.hostName} = {
      forceSSL = false;
      enableACME = false;

      locations."/" = {
        proxyPass = "http://127.0.0.1:8123";
        extraConfig = ''
          proxy_set_header    Upgrade     $http_upgrade;
          proxy_set_header    Connection  "upgrade";
        '';
      };
    };
  };
}
