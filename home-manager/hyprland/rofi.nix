{
  pkgs,
  ...
}:
{
  programs.rofi = {
    enable = true;
    plugins = [
      pkgs.rofi-emoji
      pkgs.rofi-calc
      pkgs.rofi-file-browser
    ];

    extraConfig = {
      modi = "window,drun,run,ssh,emoji,calc,filebrowser";
      terminal = "ghostty";
      show-icons = true;
      drun-display-format = "{icon} {name}";
      hide-scrollbar = true;
    };
  };
}
