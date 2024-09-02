{
  pkgs,
  lib,
  flake,
  system,
  ...
}:
# TODO: Understand this more and why its used
let
  inherit (flake) inputs;
in
{
  nixpkgs.overlays = [
    (final: prev: {
      # gaming = flake.inputs.nix-gaming.packages.${system};
      aerospace = prev.callPackage ../packages/aerospace.nix { };
      wallpapers = prev.callPackage ../packages/wallpapers { };
      devenv = flake.inputs.devenv.packages.${system}.devenv;
      agenix = flake.inputs.agenix.packages.${system}.default;
      neovim-base = flake.inputs.modular-neovim.packages.${system}.neovim-base;
      neovim-full = flake.inputs.modular-neovim.packages.${system}.neovim-full;
      nix-serve = flake.inputs.nix-serve.packages.${system}.nix-serve;
      hyprland = flake.inputs.hyprland.packages.${system}.hyprland;
      f = flake.inputs.f.packages.${system}.default;
      f-tmux = flake.inputs.f.packages.${system}.f-tmux;
      shc-cli = flake.inputs.shc.packages.${system}.default;
    })
    inputs.nur.overlay
  ];
}
