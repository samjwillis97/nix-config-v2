{ config, ... }:
{
  services.hyprpaper = {
    enable = true;

    settings = {
      preload = [ "${config.theme.wallpaper.path}" ];
      wallpaper = [
        ", ${config.theme.wallpaper.path}"
      ];
    };
  };
}
