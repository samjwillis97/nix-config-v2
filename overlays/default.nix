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
      tmux-session-cache-plugin-deps =
        final.callPackage ../packages/tmux-session-cache-plugin-deps.nix
          { };
      tmux-session-cache-plugin = final.callPackage ../packages/tmux-session-cache-plugin.nix { };
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
      nix-auth = inputs.nix-auth.packages.${system}.default;
      pi-agent = inputs.pi-agent.packages.${system}.pi-agent;
      # cage 0.2.1 segfaults with newer libwayland-server; override to 0.3.0
      # cage = prev.cage.overrideAttrs (old: rec {
      #   version = "0.3.0";
      #   src = prev.fetchFromGitHub {
      #     owner = "cage-kiosk";
      #     repo = "cage";
      #     rev = "v${version}";
      #     hash = "sha256-NLoz11bfeZwesmwLmyytuB6/vSwIsnDWKzyAXFe+YZ0=";
      #   };
      # });
      zsh-patina = flake.inputs.zsh-patina.packages.${system}.default;
    })
    inputs.nur.overlays.default
    inputs.brew-nix.overlays.default
    inputs.nix-vscode-extensions.overlays.default
    inputs.firefox-darwin.overlay
    inputs.llm-agents.overlays.shared-nixpkgs
  ];
}
