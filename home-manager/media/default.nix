{ pkgs, ... }:
{
    home.packages = with pkgs; [
        spotify
        plexamp
        plex-media-player
        vlc
    ];
}