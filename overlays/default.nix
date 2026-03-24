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
      opencode-notifier-deps = final.callPackage ../packages/opencode-notifier-deps.nix { };
      opencode-notifier = final.callPackage ../packages/opencode-notifier.nix { };
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
      nix-auth = inputs.nix-auth.packages.${system}.default;
    })
    inputs.nur.overlays.default
    inputs.brew-nix.overlays.default
    inputs.nix-vscode-extensions.overlays.default
    inputs.firefox-darwin.overlay
    inputs.llm-agents.overlays.default
  ];
}
