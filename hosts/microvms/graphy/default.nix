{ config, ... }:
{
  imports = [ 
    ../../../modules/monitoring/grafana 
    ../../../modules/monitoring/exporters
  ];

  networking.hostName = "graphy";

  modules = {
    monitoring = {
      grafana = {
        enable = true;
      };

      exporters.system.enable = true;
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
        proxyPass = "http://127.0.0.1:${toString config.modules.monitoring.grafana.port}";
        extraConfig = ''
          proxy_set_header    Upgrade     $http_upgrade;
          proxy_set_header    Connection  "upgrade";
        '';
      };
    };
  };
}
