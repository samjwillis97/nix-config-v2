{ pkgs, ... }:
{
  home.packages = with pkgs; [
    plex-desktop
    vlc
  ];
}
