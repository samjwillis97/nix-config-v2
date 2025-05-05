{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # zoom-us # commented out until https://github.com/NixOS/nixpkgs/pull/403993
    slack
    discord
  ];

  xdg.configFile.discord = {
    target = "discord/settings.json";
    source = ./discord/settings.json;
  };
}
