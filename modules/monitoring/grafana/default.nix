{ config, lib, ... }:
with lib;
let
  cfg = config.modules.monitoring.grafana;
in
{
  options.modules.monitoring.grafana = {
    enable = mkEnableOption "Enables Grafana";

    port = mkOption {
      type = types.port;
      default = 3000;
    };
  };

  config = mkIf cfg.enable {
    services.grafana = {
      enable = true;

      settings = {
        server = {
          http_addr = "127.0.0.1";
          domain = config.networking.hostName;
          root_url = "http://${config.networking.hostName}";
          http_port = cfg.port;
        };
      };

      provision = {
        enable = true;

        dashboards.settings.providers = [
          {
            name = "Node Exporter";
            options.path = ./dashboards/node-exporter.json;
          }
          {
            name = "Radarr";
            options.path = ./dashboards/radarr-exportarr.json;
          }
        ];

        datasources.settings.datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            url = "http://insights:9090";
          }
        ];
      };
    };
  };
}
