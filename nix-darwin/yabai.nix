{ pkgs, ... }:
{
  launchd.user.agents.yabai.environment.SHELL = "${pkgs.bash}/bin/bash";

  # Look at spacebar for MacOS

  system.keyboard.enableKeyMapping = true;
  services.skhd = {
    enable = true;
    skhdConfig = ''
      # Open Terminal
      # Can't get this bastard to work
      # cmd - enter : ${pkgs.wezterm}/Applications/Wezterm.app/wezterm-gui

      # Window navigation
      cmd - h : ${pkgs.yabai}/bin/yabai -m window --focus west || ${pkgs.yabai}/bin/yabai -m display --focus west
      cmd - l : ${pkgs.yabai}/bin/yabai -m window --focus east || ${pkgs.yabai}/bin/yabai -m display --focus east
      cmd - k : ${pkgs.yabai}/bin/yabai -m window --focus north || ${pkgs.yabai}/bin/yabai -m display --focus north
      cmd - j : ${pkgs.yabai}/bin/yabai -m window --focus south || ${pkgs.yabai}/bin/yabai -m display --focus south

      # Moving windows
      shift + cmd - left : ${pkgs.yabai}/bin/yabai -m window --warp west || $(${pkgs.yabai}/bin/yabai -m window --display west && ${pkgs.yabai}/bin/yabai -m display --focus west && ${pkgs.yabai}/bin/yabai -m window --warp last) || ${pkgs.yabai}/bin/yabai -m window --move rel:-10:0
      shift + cmd - down : ${pkgs.yabai}/bin/yabai -m window --warp south || $(${pkgs.yabai}/bin/yabai -m window --display south && ${pkgs.yabai}/bin/yabai -m display --focus south) || ${pkgs.yabai}/bin/yabai -m window --move rel:0:10
      shift + cmd - up : ${pkgs.yabai}/bin/yabai -m window --warp north || $(${pkgs.yabai}/bin/yabai -m window --display north && ${pkgs.yabai}/bin/yabai -m display --focus north) || ${pkgs.yabai}/bin/yabai -m window --move rel:0:-10
      shift + cmd - right : ${pkgs.yabai}/bin/yabai -m window --warp east || $(${pkgs.yabai}/bin/yabai -m window --display east && ${pkgs.yabai}/bin/yabai -m display --focus east && ${pkgs.yabai}/bin/yabai -m window --warp first) || ${pkgs.yabai}/bin/yabai -m window --move

      # Float / Unfloat window
      # Requires SIP partially disabled
      # lctrl + lalt - f : ${pkgs.yabai}/bin/yabai -m window --toggle float --grid 4:4:1:1:2:2

      # Resize windows
      ctrl + cmd - left : ${pkgs.yabai}/bin/yabai -m window --resize left:-50:0 \
                        ${pkgs.yabai}/bin/yabai -m window --resize right:-50:0
      ctrl + cmd - down : ${pkgs.yabai}/bin/yabai -m window --resize bottom:0:50 \
                        ${pkgs.yabai}/bin/yabai -m window --resize top:0:50
      ctrl + cmd - up : ${pkgs.yabai}/bin/yabai -m window --resize top:0:-50 \
                        ${pkgs.yabai}/bin/yabai -m window --resize bottom:0:-50
      ctrl + cmd - right : ${pkgs.yabai}/bin/yabai -m window --resize right:50:0 \
                        ${pkgs.yabai}/bin/yabai -m window --resize left:50:0
    '';
  };

  services.yabai = {
    enable = true;
    enableScriptingAddition = false; # This requires SIP to be disabled...
    # Need to determine what I would actually need this for

    config = {
      layout = "bsp";
      auto_balance = "on";
      split_ratio = "0.50";
      window_placement = "second_child";

      window_gap = 10;
      top_padding = 10;
      bottom_padding = 10;
      left_padding = 10;
      right_padding = 10;
    };

    extraConfig = ''
      # Sonoma compatible borders
      /etc/profiles/per-user/j.mckeown/bin/borders active_color=0xffe1e3e4 inactive_color=0x00000000 width=8.0 &

      # rules
      ${pkgs.yabai}/bin/yabai -m rule --add app="^System Settings$"         sticky=on layer=above manage=off
      ${pkgs.yabai}/bin/yabai -m rule --add app="^Disk Utility$"            sticky=on layer=above manage=off
      ${pkgs.yabai}/bin/yabai -m rule --add app="^System Information$"      sticky=on layer=above manage=off
      ${pkgs.yabai}/bin/yabai -m rule --add app="^Activity Monitor$"        sticky=on layer=above manage=off
      ${pkgs.yabai}/bin/yabai -m rule --add app="^Simulator$"               sticky=on layer=above manage=off
      ${pkgs.yabai}/bin/yabai -m rule --add app="^Raycast Settings$"        sticky=on layer=above manage=off
      ${pkgs.yabai}/bin/yabai -m rule --add app="^Path Finder$"             manage=off
      ${pkgs.yabai}/bin/yabai -m rule --add app="^Time Out$"                manage=off
      ${pkgs.yabai}/bin/yabai -m rule --add app="^Calculator$"              manage=off
    '';
  };
}
