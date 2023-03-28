# TODO:
#   - Flameshot
#   - OBS
#   - Solaar
{ config, lib, pkgs, ... }:
{
    imports = [
        ../media
        ../social
        ../firefox
        ../alacritty
        ../nvim
        ../theme
    ];

    home.packages = with pkgs; [
        arandr
        gammastep
        pavucontrol
        pamixer
        udiskie
        xclip
        chromium
        filezilla
        xfce.thunar
        xfce.thunar-archive-plugin
        obs-studio
        peek
    ];

    services.udiskie = {
        enable = true;
        tray = "always";
    };

    xdg = {
    # TODO: Mimetypes
        userDirs = {
            enable = true;
            createDirectories = true;
        };
    };
}
