{ pkgs, ... }:
{
    home.packages = with pkgs; [
        slack
        discord
    ];

    xdg.configFile.discord = {
        target = "discord/settings.json";
        source = ./discord/settings.json;
    };
}
