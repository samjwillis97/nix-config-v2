{ config, lib, ... }:
with lib;
let
  cfg = config.modules.media.deluge;
in 
{
  options.modules.media.deluge = {
    enable = mkEnableOption "Enables Deluge service";

    port = mkOption {
      default = 8112;
      type = types.port;
    };
  };

  config = mkIf cfg.enable {
    services.deluge = {
      enable = true;

      web = {
        enable = true;
        port = cfg.port;
      };
    };
  };
}
