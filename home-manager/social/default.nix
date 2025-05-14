{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # zoom-us # commented out until someone else builds it..
    slack
    discord
  ];

  xdg.configFile.discord = {
    target = "discord/settings.json";
    source = ./discord/settings.json;
  };
}
