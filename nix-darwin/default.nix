{ pkgs, ... }:
{
  imports = [
    ./home.nix
    ./meta.nix
    ./system.nix
    ./fonts.nix
    ./docker.nix
    ./documentation.nix
    ./finder.nix
    ./brew.nix
    ./keyboard.nix
    ./ns-global-domain.nix
    ./dock.nix
    ./spaces.nix
    ../overlays
  ];

  # TODO:
  #   - See About MacOS Apps:
  #       - Raycast
  #       - Displaylink Manager

  # TODO: Tailscale
}
