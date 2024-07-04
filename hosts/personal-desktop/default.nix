{
  super,
  pkgs,
  lib,
  flake,
  ...
}:
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

  home-manager.users.${super.meta.username}.theme.wallpaper.path =
    pkgs.wallpapers.nixos-catppuccin-magenta-blue;
}
