{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.ghostty;
in
{

  options.modules.ghostty = {
    enable = mkEnableOption "ghostty";
  };

  config = mkIf cfg.enable {
    xdg.configFile."ghostty/config".text = ''
      title = " "
      macos-titlebar-style = hidden
      font-size = 12
      theme = dracula
      # background-opacity = 0.8
      # background-blur-radius = 20
    '';
  };
}
