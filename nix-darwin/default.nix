{ config, lib, pkgs, ... } :
{
    imports = [
        ./home.nix
        ./meta.nix
        ./system.nix
        ../modules/fonts.nix
    ];

    # TODO:
    #   - See About MacOS Apps:
    #       - Raycast
    #       - Rectangle
    #       - Displaylink Manager
    #       - ProtonVPN

    # TODO: Tailscale
}
