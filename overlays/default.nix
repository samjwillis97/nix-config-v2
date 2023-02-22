{ pkgs, lib, flake, system, ... }:
# TODO: Understand this more and why its used
let
  inherit (flake) inputs;
in
{
  nixpkgs.overlays = [
    (final: prev: {
      /* gaming = flake.inputs.nix-gaming.packages.${system}; */
      wallpapers = prev.callPackage ../packages/wallpapers { };
    })
  ];
}
