{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.ghostty;
  isLinux = pkgs.stdenv.isLinux;
in
{

  options.modules.ghostty = {
    enable = mkEnableOption "ghostty";

    package = mkOption {
      type = types.package;
      default = if isLinux then pkgs.ghostty else pkgs.ghostty-bin;
      description = "The ghostty package to use.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = if isLinux then [ pkgs.ghostty ] else [ pkgs.ghostty-bin ];

    xdg.configFile."ghostty/config".text = ''
      title = " "
      macos-titlebar-style = hidden
      cursor-style = block
      font-size = 12
      font-family = FiraCode Nerd Font Mono
      font-feature = -calt
      font-thicken = true
      theme = dracula
      window-colorspace = display-p3
      shell-integration-features = no-cursor
      # background-opacity = 0.8
      # background-blur-radius = 20
    '';
  };
}
