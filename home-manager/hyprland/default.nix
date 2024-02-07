{ pkgs, ... }: {
  imports = [ ./wofi.nix ./waybar.nix ];

  wayland.windowManager.hyprland = {
    enable = true;
    xwayland = { enable = true; };
    # nvidiaPatches = false;
    recommendedEnvironment = true;

    # TODO: Notification Daemon
    # TODO: Pipewire (screen sharing)
    # TODO: XDG Desktop Portal 
    # TODO: Authentication Agent
    # TODO: QT Wayland Support
    # TODO: Clipboard Manager

    # TODO: Theme
    # TODO: Background
    # TODO: Media Keys
    # TODO: STatus Bard

    # TODO: Look at eww open bar, eww open bgdecor and eww open winbar
    extraConfig = ''
      exec-once = eww daemon && eww open topbar

      $mainMod = ALT

      bind = $mainMod, Return, exec, alacritty
      bind = $mainMod, d, exec, wofi --show run

      bind = $mainMod, Space, toggleFloating

      bind = $mainMod, H, movefocus, l
      bind = $mainMod, J, movefocus, d
      bind = $mainMod, K, movefocus, u
      bind = $mainMod, L, movefocus, r

      bind = $mainMod SHIFT, H, movewindow, l
      bind = $mainMod SHIFT, J, movewindow, d
      bind = $mainMod SHIFT, K, movewindow, u
      bind = $mainMod SHIFT, L, movewindow, r

      bind = $mainMod SHIFT, q, killactive

      bind = $mainMod, 1, workspace, 1
      bind = $mainMod, 2, workspace, 2
      bind = $mainMod, 3, workspace, 3
      bind = $mainMod, 4, workspace, 4
      bind = $mainMod, 5, workspace, 5
      bind = $mainMod, 6, workspace, 6
      bind = $mainMod, 7, workspace, 7
      bind = $mainMod, 8, workspace, 8
      bind = $mainMod, 9, workspace, 9
      bind = $mainMod, 0, workspace, 10

      bind = $mainMod SHIFT, 1, movetoworkspace, 1
      bind = $mainMod SHIFT, 2, movetoworkspace, 2
      bind = $mainMod SHIFT, 3, movetoworkspace, 3
      bind = $mainMod SHIFT, 4, movetoworkspace, 4
      bind = $mainMod SHIFT, 5, movetoworkspace, 5
      bind = $mainMod SHIFT, 6, movetoworkspace, 6
      bind = $mainMod SHIFT, 7, movetoworkspace, 7
      bind = $mainMod SHIFT, 8, movetoworkspace, 8
      bind = $mainMod SHIFT, 9, movetoworkspace, 9
      bind = $mainMod SHIFT, 0, movetoworkspace, 10
    '';
  };
}
