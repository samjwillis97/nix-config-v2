{
  programs.wlogout = {
    enable = true;

    layout = [
      {
        label = "lock";
        action = "hyprlock";
        keybind = "l";
      }
      {
        label = "logout";
        action = "hyprctl dispatch exit 0";
        keybind = "q";
      }
      {
        label = "suspend";
        action = "systemctl suspend";
        keybind = "u";
      }
      {
        label = "hibernate";
        action = "systemctl hibernate";
        keybind = "h";
      }
      {
        label = "reboot";
        action = "systemctl reboot";
        keybind = "r";
      }
      {
        label = "shutdown";
        action = "systemctl poweroff";
        keybind = "s";
      }
    ];
  };
}
