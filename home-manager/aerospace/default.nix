{ pkgs, config, ... }:
{
  home.packages = [ pkgs.jankyborders ];

  modules.aerospace = {
    enable = true;

    settings = {
      start-at-login = true;

      # Normalizations. See: https://nikitabobko.github.io/AeroSpace/guide#normalization
      enable-normalization-flatten-containers = false;
      enable-normalization-opposite-orientation-for-nested-containers = false;
      after-startup-command = [
        "exec-and-forget ${pkgs.jankyborders}/bin/borders style=round width=5.0 active_color=${
          builtins.replaceStrings [ "#" ] [ "0xff" ] config.theme.colors.base0D
        } inactive_color=${builtins.replaceStrings [ "#" ] [ "0xff" ] config.theme.colors.base01}"
      ];

      workspace-to-monitor-force-assignment = {
        "1" = [
          "C34H89x"
          1
          2
        ];
        "2" = [
          "C34H89x"
          1
          2
        ];
        "3" = [
          "C34H89x"
          1
          2
        ];
        "4" = [
          "C34H89x"
          1
          2
        ];
        "5" = [ "^built-in retina display$" 1 2 ];
        "6" = [ "^built-in retina display$" 3 2 ];
        "7" = [
          "C34H89x"
          3
          2
        ];
        "8" = [
          "C34H89x"
          3
          2
        ];
        "9" = [
          "C34H89x"
          3
          2
        ];
        "10" = [
          "C34H89x"
          3
          2
        ];
      };

      gaps = {
        inner = {
          horizontal = 15;
          vertical = 15;
        };
        outer = {
          left = 15;
          bottom = 15;
          top = 15;
          right = 15;
        };
      };

      mode = {
        main.binding = {
          "cmd-h" = [ ]; # Disable cmd-h hiding windows
          "alt-enter" = "exec-and-forget open -n ${pkgs.wezterm}/Applications/Wezterm.app/wezterm-gui";

          "alt-h" = "focus left --boundaries all-monitors-outer-frame --boundaries-action wrap-around-all-monitors";
          "alt-j" = "focus down";
          "alt-k" = "focus up";
          "alt-l" = "focus right --boundaries all-monitors-outer-frame --boundaries-action wrap-around-all-monitors";

          "alt-shift-h" = "move left";
          "alt-shift-j" = "move down";
          "alt-shift-k" = "move up";
          "alt-shift-l" = "move right";

          "alt-period" = "move-workspace-to-monitor next";
          "alt-comma" = "move-workspace-to-monitor prev";

          # Consider using "join-with" command as a "split" replacement if you want to enable normalizations
          "alt-s" = "split vertical";
          "alt-v" = "split horizontal";

          "alt-f" = "fullscreen";

          # "alt-s" = "layout v_accordion" # "layout stacking" in i3
          "alt-w" = "layout h_accordion"; # "layout tabbed" in i3
          "alt-e" = "layout tiles horizontal vertical"; # "layout toggle split" in i3

          "alt-shift-space" = "layout floating tiling"; # "floating toggle" in i3

          # Not supported, because this command is redundant in AeroSpace mental model.
          # See: https://nikitabobko.github.io/AeroSpace/guide#floating-windows
          # alt-space" = "focus toggle_tiling_floating"

          # `focus parent`/`focus child` are not yet supported, and it"s not clear whether they
          # should be supported at all https://github.com/nikitabobko/AeroSpace/issues/5
          # alt-a" = "focus parent"

          "alt-1" = "workspace 1";
          "alt-2" = "workspace 2";
          "alt-3" = "workspace 3";
          "alt-4" = "workspace 4";
          "alt-5" = "workspace 5";
          "alt-6" = "workspace 6";
          "alt-7" = "workspace 7";
          "alt-8" = "workspace 8";
          "alt-9" = "workspace 9";
          "alt-0" = "workspace 10";

          "alt-shift-1" = "move-node-to-workspace 1";
          "alt-shift-2" = "move-node-to-workspace 2";
          "alt-shift-3" = "move-node-to-workspace 3";
          "alt-shift-4" = "move-node-to-workspace 4";
          "alt-shift-5" = "move-node-to-workspace 5";
          "alt-shift-6" = "move-node-to-workspace 6";
          "alt-shift-7" = "move-node-to-workspace 7";
          "alt-shift-8" = "move-node-to-workspace 8";
          "alt-shift-9" = "move-node-to-workspace 9";
          "alt-shift-0" = "move-node-to-workspace 10";

          "alt-shift-c" = "reload-config";

          "alt-r" = "mode resize";
        };

        resize.binding = {
          "h" = "resize width -50";
          "j" = "resize height +50";
          "k" = "resize height -50";
          "l" = "resize width +50";
          "enter" = "mode main";
          "esc" = "mode main";
        };
      };

    };
  };
}
