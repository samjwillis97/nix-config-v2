# TODO:
#   - Discord
#   - Slack
{ pkgs, ... }:
{
    home.packages = with pkgs; [
        slack
        discord
    ];
}