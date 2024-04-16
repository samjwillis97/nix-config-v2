{ config, lib, ... }:
with lib;
let
  cfg = config.modules.home-automation.hass;
in
{
  options.modules.home-automation.hass = {
    enable = mkEnableOption "Enable home-assistant service";
  };

  config = mkIf cfg.enable {
    services.home-assistant = {
      enable = true;
      config = {};
    };
  };
}
