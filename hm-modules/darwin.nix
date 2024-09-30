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
  };

  config = (
    mkIf cfg.enable (mkMerge [
      {
        home.packages = with pkgs; [
          brewCasks.raycast
          brewCasks.slack
          brewCasks.discord
          # brewCasks."1password" - requires installing in particular location
          # brewCasks.displaylink - bad type of package
          brewCasks.betterdisplay
          brewCasks.appcleaner
          # brewCasks."logi-options+" - bad hash
          brewCasks.proxyman
          brewCasks.disk-inventory-x
        ];
      }
    ])
  );
}
