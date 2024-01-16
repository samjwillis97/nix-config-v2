{ lib, pkgs, ... }: {
  imports = [ ../../overlays ];

  nixpkgs.config = import ./nixpkgs-config.nix // {
    allowUnfreePredicate = _: true;
  };

  programs = {
    home-manager.enable = true;
    git.enable = true;
  };

  # IDK if this does anything?
  home.stateVersion = "23.05";
}
