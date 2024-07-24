{ config, ... }:
{
  imports = [
    ../../../modules/monitoring/grafana
    ../../../modules/monitoring/exporters
    ../../../modules/monitoring/promtail
  ];

  networking.hostName = "graphy";

  modules = {
    monitoring = {
      grafana = {
        enable = true;
        dataSources = [
          {
            name = "Prometheus";
            type = "prometheus";
            url = "http://insights:9090";
          }
          {
            name = "Loki";
            type = "loki";
            url = "http://insights:3100";
          }
        ];
      };

      promtail = {
        enable = true;
        lokiUrl = "http://insights:3100";
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
