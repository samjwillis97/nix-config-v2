{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.modules.zellij;
in
{
  options.modules.zellij = {
    enable = mkEnableOption "a terminal workspace manager";
    package = mkOption {
      type = types.package;
      default = pkgs.zellij;
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
    xdg.configFile = {
      "zellij/config.kdl" = {
        text = ''
default_mode "locked"

default_layout "compact"

pane_frames false

mouse_mode true

keybinds clear-defaults=true {
  locked {
    bind "Ctrl b" { SwitchToMode "normal"; }

    bind "Ctrl h" { MoveFocus "left"; }
    bind "Ctrl j" { MoveFocus "down"; }
    bind "Ctrl k" { MoveFocus "up"; }
    bind "Ctrl l" { MoveFocus "right"; }

    bind "Shift h" { MovePane "left"; }
    bind "Shift j" { MovePane "down"; }
    bind "Shift k" { MovePane "up"; }
    bind "Shift l" { MovePane "right"; }

    bind "Ctrl Shift h" { Resize "left"; }
    bind "Ctrl Shift j" { Resize "down"; }
    bind "Ctrl Shift k" { Resize "up"; }
    bind "Ctrl Shift l" { Resize "right"; }
  }

  normal {
    bind "h" { MoveFocus "left"; }
    bind "j" { MoveFocus "down"; }
    bind "k" { MoveFocus "up"; }
    bind "l" { MoveFocus "right"; }

    bind "f" { ToggleFocusFullscreen; SwitchToMode "locked"; }
    bind "|" { NewPane "right"; SwitchToMode "locked"; }
    bind "-" { NewPane "down"; SwitchToMode "locked"; }
    bind "x" { CloseFocus; SwitchToMode "locked"; }

    bind "c" { NewTab; SwitchToMode "locked"; }
    bind "n" { GoToNextTab; }
    bind "p" { GoToPreviousTab; }
    // "," to rename tab

    bind "m" { SwitchToMode "move"; }

    bind "w" { 
      LaunchOrFocusPlugin "session-manager" {
        floating true
        move_to_focused_tab true
      }
      SwitchToMode "locked"
    }

    bind "d" { Detach; }
  }

  move {
    bind "m" { SwitchToMode "normal"; }
    bind "n" "Tab" { MovePane; }
    bind "h" "Left" { MovePane "Left"; }
    bind "j" "Down" { MovePane "Down"; }
    bind "k" "Up" { MovePane "Up"; }
    bind "l" "Right" { MovePane "Right"; }
  }

  shared_except "locked" "entersearch" {
    bind "enter" { SwitchToMode "locked"; }
  }

  shared_except "locked" "entersearch" "renametab" "renamepane" {
    bind "esc" { SwitchToMode "locked"; }
  }
}

plugins {
    compact-bar location="zellij:compact-bar"
    configuration location="zellij:configuration"
    filepicker location="zellij:strider" {
        cwd "/"
    }
    plugin-manager location="zellij:plugin-manager"
    session-manager location="zellij:session-manager"
    status-bar location="zellij:status-bar"
    strider location="zellij:strider"
    tab-bar location="zellij:tab-bar"
    welcome-screen location="zellij:session-manager" {
        welcome_screen true
    }
}
        '';
      };
    };
  };
}
