{ config, pkgs, lib, flake, ... }: {
  programs.kitty = {
    enable = true;
    font = {
      package = with pkgs; (nerdfonts.override { fonts = [ "FiraCode" ]; });
      name = "FiraCode Nerd Font Mono";
      size = 9;
    };
  };
}
