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
    ../../modules/monitoring/exporters
  ];

  modules.monitoring.exporters.system.enable = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  home-manager.users.${super.meta.username}.theme.wallpaper.path =
    pkgs.wallpapers.nixos-catppuccin-magenta-blue;
}
