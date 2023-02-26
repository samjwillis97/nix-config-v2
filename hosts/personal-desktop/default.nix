{ config, pkgs, lib, flake, ... }:
let
    inherit (flake) inputs;
in
{
    imports = [
        ./hardware-configuration.nix
        ../../nixos
    ];

    # Use the systemd-boot EFI boot loader.
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    # TODO: Get this from config
    networking.hostName = "personal-desktop";

    home-manager.users.${config.meta.username}.theme.wallpaper.path = pkgs.wallpapers.nixos-catppuccin-magenta-blue;
}
