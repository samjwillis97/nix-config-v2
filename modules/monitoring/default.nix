{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.monitoring;
in
{
  options.modules.monitoring = {
    enable = mkEnableOption "Enables Monitoring with Grafana Alloy + Prometheus";

    alloyPort = mkOption {
      default = 12345;
      type = types.port;
    };

    prometheusPort = mkOption {
      default = 9090;
      type = types.port;
    };

    prometheusTargets = mkOption {
      default = [ ];
      type = types.listOf types.str;
    };
  };

  config = mkIf cfg.enable {
    services.prometheus = {
      enable = true;
      port = cfg.prometheusPort;

      extraFlags = [ "--web.enable-remote-write-receiver" ];

      retentionTime = "30d";
    };

    services.alloy = {
      enable = true;

      extraFlags = [ "--server.http.listen-addr=0.0.0.0:${toString cfg.alloyPort}" ];
    };

    environment.etc."alloy/config.alloy" = {
      text = ''
        prometheus.remote_write "default" {
          endpoint {
            url = "http://127.0.0.1:${toString cfg.prometheusPort}/api/v1/write"
          }
        }

        prometheus.scrape "systemd" {
          targets = [${
            builtins.concatStringsSep "\n" (
              builtins.map (target: ''{"__address__" = "${target}"},'') cfg.prometheusTargets
            )
          }
          ]

          forward_to = [prometheus.remote_write.default.receiver]
        }
      '';
    };
  };
}
