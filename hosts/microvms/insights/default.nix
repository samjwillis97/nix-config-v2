{ config, ... }:
{
  imports = [
    ../../../modules/monitoring
    ../../../modules/monitoring/loki
    ../../../modules/monitoring/promtail
    ../../../modules/monitoring/exporters
  ];

  networking.hostName = "insights";

  modules = {
    monitoring = {
      enable = true;

      loki.enable = true;

      promtail = {
        enable = true;
        lokiUrl = "http://127.0.0.1:${toString config.modules.monitoring.loki.port}";
      };

      exporters = {
        system.enable = true;
      };

      prometheusTargets = [
        "${config.networking.hostName}:${toString config.modules.monitoring.exporters.system.port}"
        "personal-desktop:9091" # node system exporter
        "curator:9091" # node system exporter
        "dash:9091" # node system exporter
        "graphy:9091" # node system exporter
        "indexer:9091" # node system exporter
        "insights:9091" # node system exporter
        "iso-grabber:9091" # node system exporter
        "sonarr:9091" # node system exporter
        "plex:9091" # node system exporter
        "curator:9708" # radarr exportarr
      ];
    };
  };
}
