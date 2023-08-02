{ pkgs, ... }: {
  home.packages = with pkgs; [ zoom-us slack discord ];

  xdg.configFile.discord = {
    target = "discord/settings.json";
    source = ./discord/settings.json;
  };
}
