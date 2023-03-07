{ pkgs, ... }:
{
    home.packages = with pkgs; [
        plex-media-player
        vlc
        tidal-hifi
    ];
}
