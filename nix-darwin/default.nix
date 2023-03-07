{ config, lib, pkgs, ... } :
{
    imports = [
        ./home.nix
        ./meta.nix
        ./system.nix
        ./fonts.nix
        ../overlays
    ];

    # TODO:
    #   - See About MacOS Apps:
    #       - Raycast
    #       - Rectangle
    #       - Displaylink Manager
    #       - ProtonVPN

    # TODO: Tailscale
}
