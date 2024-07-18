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
          http_port = cfg.port;
        };
      };
    };
  };
}
