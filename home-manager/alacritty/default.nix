{ config, pkgs, lib, flake, ... }:
{
    programs.alacritty = {
        enable = true;

        settings = {
            import = [
                "~/.config/alacritty/catppuccin-macchiato.yml"
            ];

            font.size = 8; # need this to change depending on systems
            font.normal.family = "FiraCode Nerd Font Mono";
            font.normal.style = "Light";
        };
    };

    xdg.configFile.alacritty = {
        source = ./config;
        recursive = true;
    };
}
