{ config, ... }:
{
  imports = [
    ../../../modules/media/homepage-dashboard
    ../../../modules/monitoring/exporters
    ../../../modules/monitoring/promtail
  ];

  networking.hostName = "dash";

  modules.monitoring = {
    promtail = {
      enable = true;
      lokiUrl = "http://insights:3100";
    };

    exporters.system.enable = true;
  };

  modules.media = {
    homepage-dashboard = {
      enable = true;

      radarr = {
        enable = true;
        url = "http://curator";
      };

      deluge = {
        enable = true;
        url = "http://iso-grabber";
      };

      prowlarr = {
        enable = true;
        url = "http://indexer";
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
        proxyPass = "http://127.0.0.1:${toString config.modules.media.homepage-dashboard.port}";
        extraConfig = ''
          proxy_set_header    Upgrade     $http_upgrade;
          proxy_set_header    Connection  "upgrade";
        '';
      };
    };
  };
}
