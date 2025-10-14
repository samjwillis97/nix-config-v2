{ super, ... }:
let
  inherit (super.meta) useHomeManager;
in
{
  imports = [
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
  ]
  ++ (if useHomeManager then [ ./home.nix ] else [ ]);

  # TODO:
  #   - See About MacOS Apps:
  #       - Raycast
  #       - Displaylink Manager

  # TODO: Tailscale
}
