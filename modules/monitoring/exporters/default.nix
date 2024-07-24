{ config, lib, ... }:
with lib;
let
  cfg = config.modules.monitoring.exporters;
in
{
  options.modules.monitoring.exporters = {
    system = {
      enable = mkEnableOption "Enable system exporter";
      port = mkOption {
        default = 9091;
        type = types.port;
      };
    };
  };

  config = {
    services.prometheus = {
      exporters =
        {

        }
        // (mkIf cfg.system.enable {
          node = {
            enable = true;
            port = cfg.system.port;
            enabledCollectors = [
              "systemd"
              "processes"
            ];
          };
        });
    };
  };
}
