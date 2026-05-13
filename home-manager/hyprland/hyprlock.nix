{
  config,
  lib,
  ...
}:
{
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        grace = 300;
        hide_cursor = true;
      };
      label = [
        {
          text = "$TIME";
          font_size = 64;
          position = "0, 80";
          halign = "center";
          valign = "center";
          monitor = "";
        }
        {
          text = ''cmd[update:60000] date +"%A, %B %d"'';
          font_size = 20;
          position = "0, 20";
          halign = "center";
          valign = "center";
          monitor = "";
        }
      ];
    };
  };
}
