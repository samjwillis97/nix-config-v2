{ config, lib, ... }:
with lib;
let
  cfg = config.modules.monitoring.promtail;
in
{
  options.modules.monitoring.promtail = {
    enable = mkEnableOption "Enables Promtail";

    lokiUrl = mkOption {
      type = types.str;
      default = "http://127.0.0.1:3100";
    };
  };

  config = mkIf cfg.enable {
    services.promtail = {
      enable = true;

      configuration = {
        server = {
          http_listen_port = 28183;
          grpc_listen_port = 0;
        };

        positions = {
          filename = "/tmp/positions.yaml";
        };

        clients = [ { url = "${cfg.lokiUrl}/loki/api/v1/push"; } ];

        scrape_configs = [
          {
            job_name = "journal";
            journal = {
              max_age = "12h";
              labels = {
                job = "systemd-journal";
                host = config.networking.hostName;
              };
            };
            relabel_configs = [
              {
                source_labels = [ "__journal__systemd_unit" ];
                target_label = "unit";
              }
              {
                source_labels = [ "__journal_priority_keyword" ];
                target_label = "level";
              }
              {
                source_labels = [ "__journal_syslog_identifier" ];
                target_label = "syslog_identifier";
              }
            ];
          }
        ];
      };
    };
  };
}
