{
  lib,
  flake,
  system,
  ...
}:
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
      # hyprland = flake.inputs.hyprland.packages.${system}.hyprland;
      # xdg-desktop-portal-hyprland = flake.inputs.hyprland.packages.${system}.xdg-desktop-portal-hyprland;
      f = flake.inputs.f.packages.${system}.default;
      httpcraft = flake.inputs.httpcraft.packages.${system}.default;
      httpcraft-mcp = flake.inputs.httpcraft-mcp.packages.${system}.default;
      ghostty = flake.inputs.ghostty.packages.${system}.default;

      # something seems to have broken in latest moonlight-qt
      moonlight-qt =
        let
          moonlight-nixpkgs = import (builtins.fetchTarball {
            url = "https://github.com/NixOS/nixpkgs/archive/ab7b6889ae9d484eed2876868209e33eb262511d.tar.gz";
            sha256 = "0wl2rq7jxr7b0g0inxbh9jgiifamn9i45p7fgra8rhhnrmcdlqjz";
          }) { inherit (prev) system; };
        in
        moonlight-nixpkgs.moonlight-qt;
    })
    inputs.nur.overlays.default
    inputs.brew-nix.overlays.default
    inputs.nix-vscode-extensions.overlays.default
    inputs.firefox-darwin.overlay
  ];
}
