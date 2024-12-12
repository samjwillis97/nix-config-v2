{
  super,
  config,
  pkgs,
  lib,
  ...
}:
{
  imports = [ ./colors ];

  # TODO: Get from somewhere else?
  theme = {
    fonts = {
      gui = {
        package = pkgs.roboto;
        name = "Roboto";
      };
    };
    wallpaper.path = lib.mkDefault pkgs.wallpapers.nixos-catppuccin-magenta-blue;
  };

  fonts.fontconfig.enable = true;

  home = {
    packages = with pkgs; [
      config.theme.fonts.gui.package
      font-awesome_5
      hack-font
      noto-fonts
      noto-fonts-emoji
      gnome-themes-extra
      adwaita-icon-theme
    ];
  };
}
