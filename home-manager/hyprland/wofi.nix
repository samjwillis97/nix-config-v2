{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.wofi = {
    enable = true;

    settings = {
      show = "drun";
      allow_images = true;
      image_size = 28;
      hide_scroll = true;
      insensitive = true;
    };

    # NOTE: Wofi has limited plugin support compared to rofi.
    # There are no equivalents for rofi-emoji, rofi-calc, rofi-file-browser, etc.
    # For window switching, use `wofi --show window` via a Hyprland keybinding.

    style = with config.theme.colors; ''
      * {
        font-family: "${config.theme.fonts.gui.name}", sans-serif;
        font-size: 14px;
      }

      window {
        background-color: ${base00};
        color: ${base05};
        border: 2px solid ${base0D};
        border-radius: 8px;
      }

      #outer-box {
        margin: 4px;
      }

      #input {
        margin: 4px;
        padding: 8px 12px;
        border: none;
        border-bottom: 2px solid ${base0D};
        background-color: ${base01};
        color: ${base05};
      }

      #scroll {
        margin: 4px;
      }

      #entry {
        padding: 4px 8px;
        border-radius: 4px;
      }

      #entry:selected {
        background-color: ${base0D};
        color: ${base00};
      }
    '';
  };
}
