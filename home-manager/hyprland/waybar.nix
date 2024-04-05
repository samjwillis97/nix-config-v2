{
  config,
  pkgs,
  lib,
  ...
}:
{
  programs.waybar = {
    enable = true;
    systemd.enable = true;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 34;
        spacing = 4;

        modules-left = [
          "sway/workspaces"
          "sway/mode"
          "wlr/taskbar"
        ];
        modules-center = [ "sway/window" ];
        modules-right = [
          "mpd"
          "temperature"
        ];

        "sway/workspaces" = {
          disable-scroll = true;
          all-outputs = true;
        };
      };
    };

    style = with config.theme.colors; ''
      @define-color base00 ${base00};
      @define-color base01 ${base01};
      @define-color base02 ${base02};
      @define-color base03 ${base03};
      @define-color base04 ${base04};
      @define-color base05 ${base05};
      @define-color base06 ${base06};
      @define-color base07 ${base07};
      @define-color base08 ${base08};
      @define-color base09 ${base09};
      @define-color base0A ${base0A};
      @define-color base0B ${base0B};
      @define-color base0C ${base0C};
      @define-color base0D ${base0D};
      @define-color base0E ${base0E};
      @define-color base0F ${base0F};

      * {
        transition: none;
        box-shadow: none;
      }

      #waybar {
      	font-family: 'Source Code Pro', sans-serif;
      	font-size: 1.2em;
      	font-weight: 400;
        color: @base04;
        background: @base01;
      }

      #workspaces {
        margin: 0 4px;
      }

      #workspaces button {
        margin: 4px 0;
        padding: 0 4px;
        color: @base05;
      }

      #workspaces button.visible {
      }

      #workspaces button.active {
        border-radius: 4px;
        background-color: @base02;
      }

      #workspaces button.urgent {
        color: rgba(238, 46, 36, 1);
      }

      #tray {
        margin: 4px 4px 4px 4px;
        border-radius: 4px;
        background-color: @base02;
      }

      #tray * {
        padding: 0 6px;
        border-left: 1px solid @base00;
      }

      #tray *:first-child {
        border-left: none;
      }

      #mode, #battery, #cpu, #memory, #network, #pulseaudio, #idle_inhibitor, #backlight, #custom-storage, #custom-updates, #custom-weather, #custom-mail, #clock, #temperature {
        margin: 4px 2px;
        padding: 0 6px;
        background-color: @base02;
        border-radius: 4px;
        min-width: 20px;
      }

      #pulseaudio.muted {
        color: @base0F;
      }

      #pulseaudio.bluetooth {
        color: @base0C;
      }

      #clock {
        margin-left: 0px;
        margin-right: 4px;
        background-color: transparent;
      }

      #temperature.critical {
        color: @base0F;
      }

      #window {
        font-size: 0.9em;
      	font-weight: 400;
      	font-family: sans-serif;
      }
    '';
  };
}
