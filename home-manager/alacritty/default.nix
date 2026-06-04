{
  config,
  pkgs,
  lib,
  flake,
  ...
}:
{
  programs.alacritty = {
    enable = true;

    settings = {
      window = {
        padding = {
          x = 5;
          y = 5;
        };
        blur = true;
        decorations = "None";
      };
    };
  };
}
