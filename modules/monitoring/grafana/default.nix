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

    dataSources = mkOption {
      type = types.listOf types.attrs;
      default = [];
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
          {
            name = "Loki Promtail";
            options.path = ./dashboards/loki-promtail.json;
          }
          {
            name = "Loki Promtail Services";
            options.path = ./dashboards/loki-promtail-services.json;
          }
        ];

        datasources.settings.datasources = cfg.dataSources;
      };
    };
  };
}
