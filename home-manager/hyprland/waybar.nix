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
  };
}
