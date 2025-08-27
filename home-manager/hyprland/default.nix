{ pkgs, lib, ... }:
let 
  workspaceCount = 9;
in
{
  imports = [
    ./wofi.nix # drun menu
    ./waybar.nix # status bar
    ./hyprlock.nix # lock screen
  ];

  wayland.windowManager.hyprland = {
    enable = true;

    xwayland.enable = true;

    systemd = {
      enable = true;
      enableXdgAutostart = true;
    };

    package = pkgs.hyprland;
    portalPackage = pkgs.hyprlandPortal;

    # TODO: Notification Daemon
    # TODO: Pipewire (screen sharing)
    # TODO: Authentication Agent
    # TODO: QT Wayland Support
    # TODO: Clipboard Manager

    # TODO: Theme
    # TODO: Background
    # TODO: Media Keys
    # TODO: STatus Bard

    # TODO: Power control etc

    # hyprctl dispatch exit

      # exec-once = eww daemon && eww open topbar

    settings = {
      # Monitor settings
      # Only going to work for main desktop
      monitor = [
        "DP-2, 2560x1440@180, 0x0, 1"
        "DP-3, 2560x1440@180, 2560x0, 1"
      ];

      "$mod" = "ALT";

      input = {
        # Keyboard settings
        repeat_rate = 50;
        repeat_delay = 250;

        # mouse settings
        accel_profile = "flat";
        follow_mouse = 2; # Cursor focus will be detached from keyboard focus. Clicking on a window will move keyboard focus to that window.
      };

      decoration = {
        rounding = 4;
      };

      animations = {
        workspace_wraparound = false;
      };

      misc = {
        # font_family = "";
        vrr = 3;
      };

      binds = {
        workspace_back_and_forth = true;
      };

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      bind = [
        "$mod, Return, exec, alacritty"
        "$mod, d, exec, wofi --show run"

        "$mod, Space, toggleFloating"

        "$mod, H, movefocus, l"
        "$mod, J, movefocus, d"
        "$mod, K, movefocus, u"
        "$mod, L, movefocus, r"

        "$mod SHIFT, H, movewindow, l"
        "$mod SHIFT, J, movewindow, d"
        "$mod SHIFT, K, movewindow, u"
        "$mod SHIFT, L, movewindow, r"

        "$mod SHIFT, q, killactive"

      ] ++ (lib.genList (n:
        "$mod, ${toString (n + 1)}, workspace, ${toString (n + 1)}"
      ) workspaceCount)
        ++ (lib.genList (n:
        "$mod SHIFT, ${toString (n + 1)}, movetoworkspace, ${toString (n + 1)}"
      ) workspaceCount);
    };
  };
}
