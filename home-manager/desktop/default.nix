# TODO:
#   - Flameshot
#   - OBS
#   - Solaar
{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../media
    ../social
    ../firefox
    ../wezterm
    ../ghostty
    ../theme
  ];

  home.packages = with pkgs; [
    arandr
    gammastep
    pavucontrol
    pamixer
    udiskie
    xclip
    chromium
    filezilla
    xfce.thunar
    xfce.thunar-archive-plugin
    obs-studio
    peek
    btop
    _1password-gui
  ];

  services.udiskie = {
    enable = true;
    tray = "always";
  };

  xdg = {
    # TODO: Mimetypes
    userDirs = {
      enable = true;
      createDirectories = true;
    };
  };
}
