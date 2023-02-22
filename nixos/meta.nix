{ config, pkgs, flake, ... }:

{
  # TODO: Look at Cachix
  # TODO: Look at Overlays

  # Add some Nix related packages
  environment.systemPackages = with pkgs; [
    cachix
    nixos-cleanup
  ];

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "22.11"; # Did you read the comment?

  # TODO: Look at ../shared/nix.nix in Thio

  # Enable unfree packages
  nixpkgs.config.allowUnfree = true;
}
