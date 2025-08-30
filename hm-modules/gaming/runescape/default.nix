{ config, lib, pkgs, ...}:
with lib;
let
  cfg = config.modules.gaming.runescape;
in
{
  options.modules.gaming.runescape = {
    enable = mkEnableOption "Enables Runescape gaming setup";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      runelite
      bolt-launcher
    ];
  };
}
