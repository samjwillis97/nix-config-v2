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
        label = "reboot";
        action = "systemctl reboot";
        keybind = "r";
      }
      {
        label = "logout";
        action = "hyperctl dispatch exit 0";
        keybind = "q";
      }
      {
        label = "shutdown";
        action = "systemctl poweroff";
        keybind = "s";
      }
    ];
  };
}
