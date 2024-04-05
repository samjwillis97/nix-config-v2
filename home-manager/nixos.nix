{
  super,
  config,
  pkgs,
  lib,
  ...
}:
{
  # TODO: See if this applied to home-manager non nixos as well - This does apply maybe move this to theme or something IDK
  # I have also noticed Steam is fuckin huge on personal desktop so DPI might need to be changed
  # Okay now I have the most plain cursor in the world on personal-desktop so I am confused
  home = {
    pointerCursor = {
      package = pkgs.gnome.adwaita-icon-theme;
      name = "Adwaita";
      size = 16;
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
    style.name = "gtk2";
  };

  services.xsettingsd = {
    enable = true;
    settings =
      with config;
      {
        # When running, most GNOME/GTK+ applications prefer those settings
        # instead of *.ini files
        "Net/IconThemeName" = gtk.iconTheme.name;
        "Net/ThemeName" = gtk.theme.name;
        "Gtk/CursorThemeName" = xsession.pointerCursor.name;
      }
      // lib.optionalAttrs (super ? fonts.fontconfig) {
        # Applications like Java/Wine doesn't use Fontconfig settings,
        # but uses it from here
        "Xft/Hinting" = super.fonts.fontconfig.hinting.enable;
        "Xft/HintStyle" = super.fonts.fontconfig.hinting.style;
        "Xft/Antialias" = super.fonts.fontconfig.antialias;
        "Xft/RGBA" = super.fonts.fontconfig.subpixel.lcdfilter;
      };
  };
}
