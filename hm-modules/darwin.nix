{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.darwin;
in
{

  options.modules.darwin = {
    enable = mkEnableOption "darwin home-manager stuffs";

    work = mkEnableOption "work related programs";
  };

  config = (
    mkIf cfg.enable (mkMerge [
      {
        home.packages = with pkgs; [
          _1password-gui
          brewCasks.raycast
          # brewCasks.displaylink - bad type of package
          brewCasks.betterdisplay
          brewCasks.appcleaner
          # brewCasks."logi-options+" - bad hash
          brewCasks.disk-inventory-x
        ];
      }
      (mkIf cfg.work {
        home.packages = with pkgs; [
          brewCasks.proxyman
          # brewCasks.workplace-chat - bad hash
        ];
      })
    ])
  );
}
