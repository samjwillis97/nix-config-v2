{ config, lib, ... }:
with lib;
let
  cfg = config.modules.monitoring;
in
{
  options.modules.monitoring = {
    enable = mkEnableOption "Enables Monitoring with Grafana Alloy + Prometheus";

    alloyPort = mkOption {
      default = 12345;
      type= types.port;
    };

    prometheusPort = mkOption {
      default = 9090;
      type = types.port;
    };

    exporters = {
      system = mkEnableOption "Enable system exporter";
    };
  };

  config = mkIf cfg.enable {
    services.prometheus = {
      enable = true;
      port = cfg.prometheusPort;

      extraFlags = [
        "--web.enable-remote-write-receiver"
      ];

      retentionTime = "30d";

      exporters =
        {

        }
        // (mkIf cfg.exporters.system {
          node = {
            enable = true;
            port = 9091;
            enabledCollectors = [ "systemd" "processes" ];
          };
        });
    };

    services.alloy = {
      enable = true;

      extraFlags = [
        "--server.http.listen-addr=0.0.0.0:${toString cfg.alloyPort}"
      ];
    };

    environment.etc."alloy/config.alloy" = {
      text = ''
      prometheus.remote_write "default" {
        endpoint {
          url = "http://127.0.0.1:${toString cfg.prometheusPort}/api/v1/write"
        }
      }

      prometheus.scrape "systemd" {
        targets = [{
          __address__ = "127.0.0.1:9091",
        }]

        forward_to = [prometheus.remote_write.default.receiver]
      }
      '';
    };
  };
}
