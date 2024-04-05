{
  config,
  lib,
  pkgs,
  ...
}:
{
  # NEED TO PLAY AROUND WITH THE COLORS FIRST 
  services.gammastep = {
    enable = true;
    tray = true;
    dawnTime = "6:30-7:30";
    duskTime = "19:30-20:30";
    package = pkgs.gammastep;
    temperature = {
      day = 6500;
      night = 3700;
    };
    settings = {
      general = {
        gamma = 1;
        fade = 1;
      };
    };
  };
}
