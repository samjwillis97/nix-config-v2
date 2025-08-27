{
  config,
  pkgs,
  lib,
  flake,
  ...
}:
{
  programs.alacritty = {
    enable = true;

    settings = {
      colors = with config.theme.colors; {
        primary = {
          background = base00;
          foreground = base05;
          dim_foreground = base05;
          bright_foreground = base05;
        };

        cursor = {
          text = base00;
          cursor = base06;
        };
        vi_mode_cursor = {
          text = base00;
          cursor = base07;
        };

        search = {
          matches = {
            foreground = base00;
            background = base05;
          };
          focused_match = {
            foreground = base00;
            background = base0B;
          };
        };

        selection = {
          text = base00;
          background = base06;
        };

        normal = {
          black = base00;
          red = base08;
          green = base0B;
          yellow = base0A;
          blue = base0D;
          magenta = base0E;
          cyan = base0C;
          white = base05;
        };

        bright = {
          black = base03;
          red = base08;
          green = base0B;
          yellow = base0A;
          blue = base0D;
          magenta = base0E;
          cyan = base0C;
          white = base07;
        };

        dim = {
          black = base02;
          red = base08;
          green = base0B;
          yellow = base0A;
          blue = base0D;
          magenta = base0E;
          cyan = base0C;
          white = base05;
        };

        indexed_colors = [
          {
            index = 16;
            color = base09;
          }
          {
            index = 17;
            color = base0F;
          }
        ];
      };

      font.size = 12; # need this to change depending on systems
      font.normal.family = "JetBrainsMonoNerdFont";
      font.normal.style = "Regular";

      window = {
        padding = {
          x = 5;
          y = 5;
        };
        opacity = 0.9;
        blur = true;
        decorations = "None";
      };
    };
  };
}
