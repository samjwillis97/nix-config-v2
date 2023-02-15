{ lib, pkgs, ... }:
{
  nixpkgs.config = import ./nixpkgs-config.nix // {
    allowUnfreePredicate = _: true;
  };

  programs = {
    home-manager.enable = true;
    git.enable = true;
  };

  home.stateVersion = "22.11";
}
