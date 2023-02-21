{ config, pkgs, flake, ... }:
let
    inherit (flake) inputs;
in
{
    imports = [
        ./hardware-configuration.nix
        ../../nixos
    ];

    boot.loader.grub.enable = true;
    boot.loader.grub.version = 2;
    boot.loader.grub.device = "/dev/sda"; # or "nodev" for efi only

    system.stateVersion = "22.11";
}
