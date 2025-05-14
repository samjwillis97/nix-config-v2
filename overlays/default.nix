{
  lib,
  flake,
  system,
  ...
}:
# TODO: Understand this more and why its used
let
  inherit (flake) inputs;
  pkgs = import inputs.nixpkgs { inherit system; };
in
{
  nixpkgs.overlays = [
    (final: prev: {
      # gaming = flake.inputs.nix-gaming.packages.${system};
      aerospace = prev.callPackage ../packages/aerospace.nix { };
      wallpapers = prev.callPackage ../packages/wallpapers { };
      agenix = flake.inputs.agenix.packages.${system}.default;
      neovim = flake.inputs.modular-neovim.packages.${system}.default;
      neovim-vscode = pkgs.neovim;
      nix-serve = flake.inputs.nix-serve.packages.${system}.nix-serve;
      hyprland = flake.inputs.hyprland.packages.${system}.hyprland;
      f = flake.inputs.f.packages.${system}.default;
      shc = flake.inputs.shc.packages.${system}.default;
      ghostty = flake.inputs.ghostty.packages.${system}.default;
    })
    inputs.nur.overlays.default
    inputs.brew-nix.overlays.default
    inputs.firefox-darwin.overlay
  ];
}
