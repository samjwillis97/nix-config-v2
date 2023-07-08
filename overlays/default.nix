{ pkgs, lib, flake, system, ... }:
# TODO: Understand this more and why its used
let inherit (flake) inputs;
in {
  nixpkgs.overlays = [
    (final: prev: {
      # gaming = flake.inputs.nix-gaming.packages.${system};
      wallpapers = prev.callPackage ../packages/wallpapers { };
      devenv = flake.inputs.devenv.packages.${system}.devenv;
      agenix = flake.inputs.agenix.packages.${system}.default;
      neovim-base = flake.inputs.modular-neovim.packages.${system}.neovim-base;
      neovim-full = flake.inputs.modular-neovim.packages.${system}.neovim-full;
    })
    inputs.nixneovimplugins.overlays.default
    inputs.nur.overlay
  ];
}
