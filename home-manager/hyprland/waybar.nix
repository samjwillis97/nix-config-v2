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

        "custom/notification" = {
          format = "  ";
          on-click = pkgs.writeShellScript "open-notifications" ''
            ${config.services.swaync.package}/bin/swaync-client -t -sw
          '';
          escape = true;
        };

        "custom/powermenu" = {
          format = " ⏻  ";
          on-click = pkgs.writeShellScript "open-power-menu" ''
            ${pkgs.wlogout}/bin/wlogout
          '';
          on-click-right = "hyprlock";
        };

        "custom/mic" = {
          format = "{}";
          exec = pkgs.writeShellScript "mic-status" ''
            if ${pkgs.wireplumber}/bin/wpctl get-volume @DEFAULT_SOURCE@ | grep -q "\[MUTED\]"; then
              echo "󰍭  MUTED"
            else
              echo "󰍬  MIC ON"
            fi
          '';
          interval = 1;
          on-click = pkgs.writeShellScript "mic-toggle" ''
            ${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_SOURCE@ toggle
          '';
        };

        pulseaudio = {
          format = "{icon} {volume}%";
          format-bluetooth = "{volume}%";
          format-muted = "";
          format-icons = {
            default = [
              ""
              ""
              ""
            ];
          };
          on-click = pkgs.writeShellScript "audio-toggle-mute" ''
            ${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_SINK@ toggle
          '';
        };

        cpu = {
          format = "   {usage}%";
          interval = 1;
        };

        memory = {
          format = "  {percentage}%";
        };

        disk = {
          path = "/";
          format = "  {percentage_used}%";
        };

        network = {
          format-wifi = "{essid}";
          format-ethernet = "󰈀  {ipaddr}";
          format-disconnected = "󰖪 Disconnected";
        };

        load = {
          format = "   {load1}";
          interval = 1;
        };

        tray = {
          spacing = 10;
        };

        modules-left = [
          "hyprland/workspaces"
          "hyprland/mode"
          "wlr/taskbar"
        ];

        modules-center = [ "hyprland/window" ];

        modules-right = [
          "mpd"
          "tray"
          "network"
          "disk"
          "cpu"
          "memory"
          "load"
          "pulseaudio"
          "custom/mic"
          "clock"
          "custom/notification"
          "custom/powermenu"
        ];

        # "sway/workspaces" = {
        #   disable-scroll = true;
        #   all-outputs = true;
        # };
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
      	font-family: '${config.theme.fonts.gui.name}', 'Font Awesome 5 Free Solid', 'Font Awesome 5 Brands', 'FiraCode Nerd Font Mono', sans-serif;
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

      #mode, #battery, #cpu, #memory, #network, #pulseaudio, #idle_inhibitor, #backlight, #custom-storage, #custom-updates, #custom-weather, #custom-mail, #clock, #temperature, #disk, #custom-mic, #load {
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

      #custom-mic {
        color: @base0B;
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
