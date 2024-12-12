{
  config,
  pkgs,
  lib,
  flake,
  ...
}:
{
  programs.kitty = {
    enable = true;
    font = {
      package = pkgs.nerd-fonts.fira-mono;
      name = "FiraCode Nerd Font Mono";
      size = 9;
    };
  };
}
