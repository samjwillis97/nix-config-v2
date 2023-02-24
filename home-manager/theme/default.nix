{ super, config, pkgs, lib, ... }:
{
  imports = [
    ../../modules/theme.nix
  ];

# TODO: Get from somewhere else?
  theme = {
    fonts = {
      gui = {
        package = pkgs.roboto;
        name = "Roboto";
      };
    };
    colors = with builtins; fromJSON (readFile ./colors/macchiato.json);
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
        gnome.gnome-themes-extra
    ];

    pointerCursor = {
        package = pkgs.gnome.adwaita-icon-theme;
        name = "Adwaita";
        size = 32;
        x11.enable = true;
        gtk.enable = true;
    };
    
    # Application using libadwaita are **not** respecting config files *sigh*
    # https://www.reddit.com/r/swaywm/comments/qodk20/gtk4_theming_not_working_how_do_i_configure_it/hzrv6gr/?context=3
    sessionVariables.GTK_THEME = config.gtk.theme.name;
  };

  gtk = {
    enable = true;
    font = {
      package = pkgs.noto-fonts;
      name = "Noto Sans";
    };
    iconTheme = {
      package = pkgs.arc-icon-theme;
      name = "Arc";
    };
    theme = {
      name = "Arc-Dark";
      package = pkgs.arc-theme;
    };
  };

  qt = {
    enable = true;
    platformTheme = "gtk";
  };

  services.xsettingsd = {
    enable = true;
    settings = with config; {
      # When running, most GNOME/GTK+ applications prefer those settings
      # instead of *.ini files
      "Net/IconThemeName" = gtk.iconTheme.name;
      "Net/ThemeName" = gtk.theme.name;
      "Gtk/CursorThemeName" = xsession.pointerCursor.name;
    } // lib.optionalAttrs (super ? fonts.fontconfig) {
      # Applications like Java/Wine doesn't use Fontconfig settings,
      # but uses it from here
      "Xft/Hinting" = super.fonts.fontconfig.hinting.enable;
      "Xft/HintStyle" = super.fonts.fontconfig.hinting.style;
      "Xft/Antialias" = super.fonts.fontconfig.antialias;
      "Xft/RGBA" = super.fonts.fontconfig.subpixel.lcdfilter;
    };
  };
}
