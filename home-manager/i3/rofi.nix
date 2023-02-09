{ config, lib, pkgs, ... }:
{
    programs.rofi = {
        enable = true;
        plugins = [
            pkgs.rofi-emoji
            pkgs.rofi-calc
            pkgs.rofi-file-browser
        ];

        extraConfig = {
            modi = "window,drun,run,ssh,emoji,calc,filebrowser";
            terminal = "alacritty";
            show-icons = true;
            drun-display-format = "{icon} {name}";
            hide-scrollbar = true;
        };

        theme = let
            inherit (config.lib.formats.rasi) mkLiteral;
        in {
            "*" = {
                bg-col =  mkLiteral "#24273a";
                bg-col-light = mkLiteral "#24273a";
                border-col = mkLiteral "#24273a";
                selected-col = mkLiteral "#363a4f";
                blue = "#8aadf4";
                fg-col = "#cad3f5";
                fg-col2 = "#ed8796";
                grey = "#6e738d";
                width = 600;
                font = "JetBrains Mono Nerd Font 12";
            };

            "element-text, element-icon, mode-switcher" = {
                background-color = mkLiteral "inherit";
                text-color = mkLiteral "inherit";
            };

            "window" = {
                height = mkLiteral "360px";
                border = mkLiteral "3px";
                border-color = mkLiteral "@border-col";
                background-color = mkLiteral "@bg-col";
            };

            "mainbox" = {
                background-color = "@bg-col";
            };

            "inputbar" = {
                children = map mkLiteral [ "prompt" "entry"];
                background-color = mkLiteral "@bg-col";
                border-radius = mkLiteral "5px";
                padding = mkLiteral "2px";
            };

            "prompt" = {
                background-color = mkLiteral "@blue";
                padding = mkLiteral "6px";
                text-color = mkLiteral "@bg-col";
                border-radius = mkLiteral "3px";
                margin = mkLiteral "20px 0px 0px 20px";
            };

            "textbox-prompt-colon" = {
                expand = false;
                str = ":";
            };

            "entry" = {
                padding = mkLiteral "6px";
                margin = mkLiteral "20px 0px 0px 10px";
                text-color = mkLiteral "@fg-col";
                background-color = mkLiteral "@bg-col";
            };

            "listview" = {
                border = mkLiteral "0px 0px 0px";
                padding = mkLiteral "6px 0px 4px";
                margin = mkLiteral "10px 0px 0px 20px";
                columns = 1;
                lines = 5;
                background-color = mkLiteral "@bg-col";
            };

            "element" = {
                padding = mkLiteral "3px 3px 3px 20px";
                margin = mkLiteral "0px 20px 0px 0px";
                background-color = mkLiteral "@bg-col";
                text-color = mkLiteral "@fg-col";
            };

            "element-icon" = {
                size = mkLiteral "20px";
            };

            "element selected" = {
                background-color =  mkLiteral "@selected-col";
                text-color = mkLiteral "@fg-col";
                border-radius = mkLiteral "3px";
            };

            "mode-switcher" = {
                spacing = 0;
            };

            "button" = {
                padding = mkLiteral "10px";
                background-color = mkLiteral "@bg-col-light";
                text-color = mkLiteral "@grey";
                vertical-align = 0.5; 
                horizontal-align = 0.5;
            };

            "button selected" = {
            background-color = mkLiteral "@bg-col";
            text-color = mkLiteral "@blue";
            };
        };
    };
}