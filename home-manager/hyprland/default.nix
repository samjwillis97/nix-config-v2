{
  pkgs,
  config,
  lib,
  ...
}:
let
  workspaceCount = 9;

  toggleMuteScript = pkgs.writeShellApplication {
    name = "toggle-mute";
    runtimeInputs = [
      pkgs.wireplumber
      pkgs.libnotify
      pkgs.gnugrep
    ];
    text = ''
      wpctl set-mute @DEFAULT_SOURCE@ toggle && \
      if wpctl get-volume @DEFAULT_SOURCE@ | grep -q "\\[MUTED\\]"; then \
        notify-send -u critical -t 5000 --replace-id=432 'Microphone: OFF'; \
      else \
        notify-send -u critical -t 5000 --replace-id=432 'Microphone: ON'; \
      fi
    '';
  };

  screenshotDir = "${config.xdg.userDirs.pictures}";

  fullScreenShot = pkgs.writeShellScript "full-screenshot" ''
    ${pkgs.grim}/bin/grim "${screenshotDir}/$(date +%Y-%m-%d_%H-%M-%S)-screenshot.png" && \
    ${pkgs.libnotify}/bin/notify-send -u normal -t 5000 'Full screenshot taken'
  '';

  areaScreenShot = pkgs.writeShellScript "area-screenshot" ''
    ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" "${screenshotDir}/$(date +%Y-%m-%d_%H-%M-%S)-screenshot.png" && \
    ${pkgs.libnotify}/bin/notify-send -u normal -t 5000 'Area screenshot taken'
  '';
in
{
  imports = [
    ./rofi.nix # drun menu
    ./ashell.nix # status bar
    ./hyprlock.nix # lock screen
    ./hypridle.nix # idle management
    ./swaync.nix # notifications
    ./wlogout.nix # logout menu
    ./hyprpaper.nix # wallpaper manager
  ];

  xdg.configFile."uwsm/env".source =
    "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh";

  wayland.windowManager.hyprland = {
    enable = true;

    # Will use the ones from NixOS module
    package = null;
    portalPackage = null;

    systemd = {
      enable = false;
    };

    settings = {
      # Monitor settings
      # Only going to work for main desktop
      monitor = [
        "DP-3, 2560x1440@180, 0x0, 1"
        "DP-2, 2560x1440@180, 2560x0, 1"
      ];

      "$mod" = "ALT";

      exec-once = [
        "swaync"
        "hypridle"
        "hyprpaper"
      ];

      input = {
        # Keyboard settings
        repeat_rate = 50;
        repeat_delay = 250;

        # mouse settings
        accel_profile = "flat";
        follow_mouse = 2; # Cursor focus will be detached from keyboard focus. Clicking on a window will move keyboard focus to that window.
      };

      general = {
        border_size = 2;
        gaps_in = 8;
        gaps_out = 15;
      };

      decoration = {
        rounding = 4;
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      animations = {
        workspace_wraparound = false;
      };

      misc = {
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
        "$mod, Return, exec, ghostty"
        "$mod, d, exec, rofi -show drun"

        # Other Rofi
        "$mod, TAB, exec, rofi -show window -modi window"

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

        # Browser
        "$mod, N, exec, firefox"

        # Fullscreen
        "$mod, F, fullscreen"

        # Split orientation (dwindle)
        "$mod, S, layoutmsg, preselect d"
        "$mod, V, layoutmsg, preselect r"

        # Group (tabbed equivalent)
        "$mod SHIFT, W, togglegroup"
        "$mod SHIFT, E, changegroupactive, f"
        "$mod SHIFT, O, changegroupactive, b"

        # Focus mode toggle
        "$mod SHIFT, Space, alterzorder, top"

        # Sticky window
        "$mod CONTROL, Space, pin"

        # Scratchpad
        "$mod SHIFT, minus, movetoworkspacesilent, special:scratchpad"
        "$mod, minus, togglespecialworkspace, scratchpad"

        # Resize with $mod+Ctrl+hjkl
        "$mod CONTROL, H, resizeactive, -20 0"
        "$mod CONTROL, J, resizeactive, 0 20"
        "$mod CONTROL, K, resizeactive, 0 -20"
        "$mod CONTROL, L, resizeactive, 20 0"

        # Reload config
        "$mod SHIFT, C, exec, hyprctl reload"

        # Window switcher (Alt+Tab style)
        "$mod, Tab, cyclenext"
        "$mod SHIFT, Tab, cyclenext, prev"

        # Move workspace to monitor
        "$mod CONTROL SUPER, H, movecurrentworkspacetomonitor, l"
        "$mod CONTROL SUPER, J, movecurrentworkspacetomonitor, d"
        "$mod CONTROL SUPER, K, movecurrentworkspacetomonitor, u"
        "$mod CONTROL SUPER, L, movecurrentworkspacetomonitor, r"

        # Close all notifications
        "CONTROL SHIFT, Space, exec, swaync-client --close-all"

        # Mute toggle with notification
        "$mod, M, exec, ${lib.getExe toggleMuteScript}"

        # Screenshots
        ", Print, exec, ${fullScreenShot}"
        "SHIFT, Print, exec, ${areaScreenShot}"

        # Enter game mode
        "$mod SHIFT, G, submap, gaming"
      ]
      ++ (lib.genList (n: "$mod, ${toString (n + 1)}, workspace, ${toString (n + 1)}") workspaceCount)
      ++ (lib.genList (
        n: "$mod SHIFT, ${toString (n + 1)}, movetoworkspace, ${toString (n + 1)}"
      ) workspaceCount);

      bindel = [
        ", XF86AudioRaiseVolume, exec, ${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, ${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86MonBrightnessUp, exec, ${pkgs.brightnessctl}/bin/brightnessctl set 5%+"
        ", XF86MonBrightnessDown, exec, ${pkgs.brightnessctl}/bin/brightnessctl set 5%-"
      ];

      bindl = [
        ", XF86AudioMute, exec, ${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioMicMute, exec, ${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_SOURCE@ toggle"
        ", XF86AudioPlay, exec, ${pkgs.playerctl}/bin/playerctl play-pause"
        ", XF86AudioStop, exec, ${pkgs.playerctl}/bin/playerctl stop"
        ", XF86AudioNext, exec, ${pkgs.playerctl}/bin/playerctl next"
        ", XF86AudioPrev, exec, ${pkgs.playerctl}/bin/playerctl previous"
      ];

      windowrule = [
        # Steam windows
        "float on, match:class ^(steam)$, match:title ^(Friends)$"
        "float on, match:class ^(steam)$, match:title ^(Steam - News)$"
        "float on, match:class ^(steam)$, match:title .* - Chat$"
        "float on, match:class ^(steam)$, match:title ^(Settings)$"
        "float on, match:class ^(steam)$, match:title .* - event started$"
        "float on, match:class ^(steam)$, match:title .* CD key$"
        "float on, match:class ^(steam)$, match:title ^(Steam - Self Updater)$"
        "float on, match:class ^(steam)$, match:title ^(Screenshot Uploader)$"
        "float on, match:class ^(steam)$, match:title ^(Steam Guard).*$"

        # Pop-ups and dialogs
        "float on, match:title ^(Settings)$"
        "float on, match:title ^(splash)$"

        # PiP
        "float on, match:title ^(Picture.in.[Pp]icture)$"
        "pin on, match:title ^(Picture.in.[Pp]icture)$"

        # Runelite
        "float on, match:title ^Bolt Launcher$"
        "float on, match:title ^RuneLite$"
        "float on, match:title ^RuneLite Launcher$"

        # Plexamp
        "float on, match:class ^(Plexamp)$"
        "pin on, match:class ^(Plexamp)$"
      ];
    };

    extraConfig =
      let
        workspaceBinds = lib.concatStringsSep "\n" (
          lib.genList (n: ''
            bind = $mod, ${toString (n + 1)}, workspace, ${toString (n + 1)}
            bind = $mod SHIFT, ${toString (n + 1)}, movetoworkspace, ${toString (n + 1)}
          '') workspaceCount
        );
      in
      ''
        # Game mode submap — suppresses all $mod bindings except workspace switching and exit
        submap = gaming
        ${workspaceBinds}
        bind = $mod SHIFT, G, submap, reset
        submap = reset
      '';
  };
}
