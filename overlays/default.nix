{ pkgs, lib, flake, system, ... }:
# TODO: Understand this more and why its used
let inherit (flake) inputs;
in {
  nixpkgs.overlays = [
    (final: prev: {
      # gaming = flake.inputs.nix-gaming.packages.${system};
      wallpapers = prev.callPackage ../packages/wallpapers { };
      my-neovim = flake.inputs.my-neovim.packages.${system}.default;
    })
    inputs.nixneovimplugins.overlays.default
  ];
}
