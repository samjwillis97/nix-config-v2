{ config, ... }:
{
  imports = [ 
    ../../../modules/monitoring 
    ../../../modules/monitoring/exporters
  ];

  networking.hostName = "insights";

  modules = {
    monitoring = {
      enable = true;

      exporters = {
        system.enable = true;
      };

      prometheusTargets = [
        "${config.networking.hostName}:${toString config.modules.monitoring.exporters.system.port}"
        "personal-desktop:9091"   # node system exporter
        "curator:9091"            # node system exporter
        "curator:9708"            # radarr exportarr
      ];
    };
  };
}
