{ config, pkgs, lib, flake, ... }:
{
    programs.alacritty = {
        enable = true;

        settings = {
            import = [
                "~/.config/alacritty/catppuccin-macchiato.yml"
            ];

            font.size = 12; # need this to change depending on systems
            font.family = "FiraCode Nerd Font Mono Light";
            font.style = "Light";
        };
    };

    xdg.configFile.alacritty = {
        source = ./config;
        recursive = true;
    };
}