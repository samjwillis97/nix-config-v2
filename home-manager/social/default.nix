{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # zoom-us # commented out until someone else builds it..
    slack
    # discord
  ];

  programs.vesktop = {
    enable = true;
  };

  # xdg.configFile.discord = {
  #   target = "discord/settings.json";
  #   source = ./discord/settings.json;
  # };
}
