{ pkgs, ... }:
{
    home.packages = with pkgs; [
        runelite
    ];

    programs.steam = {
        enable = true;
        remotePlay.openFirewall = true;
        dedicatedServer.openFirewall = true;
    }
}
