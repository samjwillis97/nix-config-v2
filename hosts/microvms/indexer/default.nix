{ config, ... }:
{
  imports = [
    ../../../modules/media/prowlarr
    ../../../modules/networking/vpn
  ];

  networking.hostName = "indexer";

  modules = {
    networking.vpn = {
      enable = false;
    };

    media.prowlarr = {
      enable = true;
      config = {
        port = 7000;
      };
    };
  };

  services.nginx = {
    enable = true;

    recommendedProxySettings = true;
    recommendedTlsSettings = false;

    virtualHosts."${config.networking.hostName}" = {
      forceSSL = false;
      enableACME = false;

      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.modules.media.prowlarr.config.port}";
        extraConfig = ''
          proxy_set_header    Upgrade     $http_upgrade;
          proxy_set_header    Connection  "upgrade";
        '';
      };
    };
  };
}
