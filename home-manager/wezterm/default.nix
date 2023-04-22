{ config, pkgs, ... }: {
  programs.wezterm = {
    enable = true;
    colorSchemes = {
      base16 = with config.theme.colors; {
        # ansi = [    
        #     "black"
        #     "maroon"
        #     "green"
        #     "olive"
        #     "navy"
        #     "purple"
        #     "teal"
        #     "silver"
        # ];
        # brights = [    
        #     "grey"
        #     "red"
        #     "lime"
        #     "yellow"
        #     "blue"
        #     "fuchsia"
        #     "aqua"
        #     "white"
        # ];
        ansi = [ base00 base08 base0B base0A base0D base0E base0C base05 ];
        brights = [ base03 base08 base0B base0A base0D base0E base0C base05 ];
        background = base00;
        cursor_bg = base06;
        cursor_border = base06;
        cursor_fg = base00;
        foreground = base05;
        selection_bg = base06;
        selection_fg = base00;
      };
    };
    extraConfig = ''
      return {
        color_scheme = "base16",
      }
    '';
  };
}
