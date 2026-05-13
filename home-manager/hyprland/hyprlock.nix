{
  config,
  lib,
  ...
}:
let
  removeHash = lib.removePrefix "#";
in
{
  programs.hyprlock = {
    enable = true;
    settings = with config.theme.colors; {
      general = {
        grace = 300;
        hide_cursor = true;
      };
      background = [
        {
          path = "screenshot";
          blur_passes = 3;
          blur_size = 8;
        }
      ];
      input-field = [
        {
          size = "200, 50";
          position = "0, -80";
          monitor = "";
          dots_center = true;
          fade_on_empty = false;
          font_color = "rgb(${removeHash base05})";
          font_family = config.theme.fonts.gui.name;
          inner_color = "rgb(${removeHash base02})";
          outer_color = "rgb(${removeHash base00})";
          outline_thickness = 5;
          placeholder_text = ''Password...'';
          shadow_passes = 2;
        }
      ];
      label = [
        {
          text = "$TIME";
          font_size = 64;
          font_family = config.theme.fonts.gui.name;
          color = "rgb(${removeHash base05})";
          position = "0, 80";
          halign = "center";
          valign = "center";
          monitor = "";
        }
        {
          text = ''cmd[update:60000] date +"%A, %B %d"'';
          font_size = 20;
          font_family = config.theme.fonts.gui.name;
          color = "rgb(${removeHash base04})";
          position = "0, 20";
          halign = "center";
          valign = "center";
          monitor = "";
        }
      ];
    };
  };
}
