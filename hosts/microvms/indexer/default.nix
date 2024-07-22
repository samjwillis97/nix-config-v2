{ config, ... }:
{
  imports = [
    ../../../modules/media/prowlarr
    ../../../modules/networking/vpn
    ../../../modules/monitoring/exporters
  ];

  networking.hostName = "indexer";

  modules.monitoring.exporters.system.enable = true;

  modules = {
    networking.vpn = {
      enable = false;
    };

    media.prowlarr = {
      enable = true;
      port = 7000;
      radarrConnection = {
        enable = true;
        hostname = "curator";
        port = 80;
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
        proxyPass = "http://127.0.0.1:${toString config.modules.media.prowlarr.port}";
        extraConfig = ''
          proxy_set_header    Upgrade     $http_upgrade;
          proxy_set_header    Connection  "upgrade";
        '';
      };
    };
  };
}
