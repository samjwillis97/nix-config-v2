{ config
, lib
, terminal
, menu
, pamixer
, light
, playerctl
, fullScreenShot
, areaScreenShot
, browser
, fileManager
, statusCommand
, alt ? "Mod1"
, modifier ? "Mod4"
, bars ? [{
    inherit fonts statusCommand;

    position = "top";
    colors = {
      background = "#282A36";
      separator = "#44475A";
      statusline = "#F8F8F2";
      activeWorkspace = {
        border = "#282A36";
        background =  "#44475A";
        text = "#F8F8F2";
      };
      bindingMode = {
        border = "#FF5555";
        background =  "#FF5555";
        text = "#F8F8F2";
      };
      focusedWorkspace = {
        border = "#44475A";
        background =  "#44475A";
        text = "#F8F8F2";
      };
      inactiveWorkspace = {
        border = "#282A36";
        background =  "#282A36";
        text = "#BFBFBF";
      };
      urgentWorkspace = {
        border = "#FF5555";
        background =  "#FF5555";
        text = "#F8F8F2";
      };
    };
  }]
, fonts ? {
    names = [
        "FiraCode Nerd Font Mono"
        "Font Awesome 5 Brands"
        "Font Awesome 5 Free Solid"
    ];
    style = "Regular";
    size = 8.0;
  }
, extraBindings ? { }
, extraWindowOptions ? { }
, extraFocusOptions ? { }
, extraModes ? { }
, extraConfig ? ""
, workspaces ? [
    {
      ws = 1;
      name = "1:  ";
    }
    {
      ws = 2;
      name = "2:  ";
    }
    {
      ws = 3;
      name = "3:  ";
    }
    {
      ws = 4;
      name = "4:  ";
    }
    {
      ws = 5;
      name = "5:  ";
    }
    {
      ws = 6;
      name = "6:  ";
    }
    {
      ws = 7;
      name = "7:  ";
    }
    {
      ws = 8;
      name = "8:  ";
    }
    {
      ws = 9;
      name = "9:  ";
    }
    {
      ws = 0;
      name = "10:  ";
    }
  ]
}:
let
  # Modes
  powerManagementMode =
    " : Screen [l]ock, [e]xit, [s]uspend, [h]ibernate, [R]eboot, [S]hutdown";
  resizeMode = " : [h]  , [j]  , [k]  , [l] ";

  # Helpers
  mapDirection = { prefixKey ? null, leftCmd, downCmd, upCmd, rightCmd }:
    with lib.strings; {
      # Arrow keys
      "${optionalString (prefixKey != null) "${prefixKey}+"}Left" = leftCmd;
      "${optionalString (prefixKey != null) "${prefixKey}+"}Down" = downCmd;
      "${optionalString (prefixKey != null) "${prefixKey}+"}Up" = upCmd;
      "${optionalString (prefixKey != null) "${prefixKey}+"}Right" = rightCmd;
      # Vi-like keys
      "${optionalString (prefixKey != null) "${prefixKey}+"}h" = leftCmd;
      "${optionalString (prefixKey != null) "${prefixKey}+"}j" = downCmd;
      "${optionalString (prefixKey != null) "${prefixKey}+"}k" = upCmd;
      "${optionalString (prefixKey != null) "${prefixKey}+"}l" = rightCmd;
    };

  mapDirectionDefault = { prefixKey ? null, prefixCmd }:
    (mapDirection {
      inherit prefixKey;
      leftCmd = "${prefixCmd} left";
      downCmd = "${prefixCmd} down";
      upCmd = "${prefixCmd} up";
      rightCmd = "${prefixCmd} right";
    });

  mapWorkspacesStr = with builtins;
    with lib.strings;
    { workspaces, prefixKey ? null, prefixCmd }:
    (concatStringsSep "\n" (map
      ({ ws, name }:
        ''
          bindsym ${optionalString (prefixKey != null) "${prefixKey}+"}${
            toString ws
          } ${prefixCmd} "${name}"'')
      workspaces));
in
{
  helpers = { inherit mapDirection mapDirectionDefault mapWorkspacesStr; };

  config = {
    inherit bars fonts modifier menu terminal;

    colors = {
      background = "#F8F8F2";
      focused = {
        background = "#6272A44";
        border = "#6272A4";
        childBorder = "#6272A4";
        indicator = "#6272A4";
        text = "#F8F8F2";
      };
      focusedInactive = {
        background = "#44475A";
        border = "#44475A";
        childBorder = "#44475A";
        indicator = "#44475A";
        text = "#F8F8F2";
      };
      placeholder = {
        background = "#282A36";
        border = "#282A36";
        childBorder = "#282A36";
        indicator = "#282A36";
        text = "#F8F8F2";
      };
      unfocused = {
        background = "#282A36";
        border = "282A36";
        childBorder = "#FF5555";
        indicator = "#FF5555";
        text = "#BFBFBF";
      };
      urgent = {
        background = "#44475A";
        border = "#FF5555";
        childBorder = "#FF5555";
        indicator = "#FF5555";
        text = "#F8F8F2";
      };
    };

    keybindings = ({
      "${modifier}+Return" = "exec ${terminal}";
      "${modifier}+Shift+q" = "kill";

      "${modifier}+n" = "exec ${browser}";
      "${modifier}+m" = "exec ${fileManager}";
      "${modifier}+d" = "exec ${menu}";

      "${modifier}+f" = "fullscreen toggle";
      "${modifier}+s" = "split v";
      "${modifier}+h" = "split h";

      "${modifier}+Shift+s" = "layout stacking";
      "${modifier}+Shift+w" = "layout tabbed";
      "${modifier}+Shift+e" = "layout toggle split";

      "${modifier}+space" = "floating toggle";
      "${modifier}+Shift+space" = "focus mode_toggle";

      "${modifier}+a" = "focus parent";

      "${modifier}+Shift+minus" = "move scratchpad";
      "${modifier}+minus" = "scratchpad show";

      "${modifier}+r" = ''mode "${resizeMode}"'';
      "${modifier}+Control+h" = "resize shrink width 10px or 10ppt";
      "${modifier}+Control+j" = "resize grow height 10px or 10ppt";
      "${modifier}+Control+k" = "resize shrink height 10px or 10ppt";
      "${modifier}+Control+l" = "resize grow width 10px or 10ppt";

      "${modifier}+Escape" = ''mode "${powerManagementMode}"'';

      "${modifier}+Shift+c" = "reload";
      "${modifier}+Shift+r" = "restart";

      "XF86AudioRaiseVolume" =
        "exec --no-startup-id ${pamixer} --set-limit 150 --allow-boost -i 5";
      "XF86AudioLowerVolume" =
        "exec --no-startup-id ${pamixer} --set-limit 150 --allow-boost -d 5";
      "XF86AudioMute" =
        "exec --no-startup-id ${pamixer} --toggle-mute";
      "XF86AudioMicMute" =
        "exec --no-startup-id ${pamixer} --toggle-mute --default-source";

      "XF86MonBrightnessUp" = "exec --no-startup-id ${light} -A 5%";
      "XF86MonBrightnessDown" = "exec --no-startup-id ${light} -U 5%";

      "XF86AudioPlay" = "exec --no-startup-id ${playerctl} play-pause";
      "XF86AudioStop" = "exec --no-startup-id ${playerctl} stop";
      "XF86AudioNext" = "exec --no-startup-id ${playerctl} next";
      "XF86AudioPrev" = "exec --no-startup-id ${playerctl} previous";

      "Print" = "exec --no-startup-id ${fullScreenShot}";
      "Shift+Print" = "exec --no-startup-id ${areaScreenShot}";
    } // (mapDirectionDefault {
      prefixKey = modifier;
      prefixCmd = "focus";
    }) // (mapDirectionDefault {
      prefixKey = "${modifier}+Shift";
      prefixCmd = "move";
    }) // (mapDirectionDefault {
      prefixKey = "Ctrl+${alt}";
      prefixCmd = "move workspace to output";
    }) // extraBindings);

    modes =
      let
        exitMode = {
          "Escape" = "mode default";
          "Return" = "mode default";
        };
      in
      {
        ${resizeMode} = (mapDirection {
          leftCmd = "resize shrink width 10px or 10ppt";
          downCmd = "resize grow height 10px or 10ppt";
          upCmd = "resize shrink height 10px or 10ppt";
          rightCmd = "resize grow width 10px or 10ppt";
        }) // exitMode;
        ${powerManagementMode} = {
          l = "mode default, exec loginctl lock-session";
          e = "mode default, exec loginctl terminate-session $XDG_SESSION_ID";
          s = "mode default, exec systemctl suspend";
          h = "mode default, exec systemctl hibernate";
          "Shift+r" = "mode default, exec systemctl reboot";
          "Shift+s" = "mode fault, exec systemctl poweroff";
        } // exitMode;
      } // extraModes;

    workspaceAutoBackAndForth = true;
    workspaceLayout = "tabbed";

    window = {
      border = 2;
      hideEdgeBorders = "smart";
      titlebar = false;
    } // extraWindowOptions;

    focus = { followMouse = false; } // extraFocusOptions;
  };

  # Until this issue is fixed we need to map workspaces directly to config file
  # https://github.com/nix-community/home-manager/issues/695
  extraConfig =
    let
      workspaceStr = (builtins.concatStringsSep "\n" [
        (mapWorkspacesStr {
          inherit workspaces;
          prefixKey = modifier;
          prefixCmd = "workspace number";
        })
        (mapWorkspacesStr {
          inherit workspaces;
          prefixKey = "${modifier}+Shift";
          prefixCmd = "move container to workspace number";
        })
      ]);
    in
    ''
      ${workspaceStr}
      ${extraConfig}
    '';
}
