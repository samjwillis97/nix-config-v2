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
    ../../modules/monitoring/promtail
  ];

  modules.monitoring = {
    promtail = {
      enable = true;
      lokiUrl = "http://insights:3100";
    };

    exporters.system.enable = true;
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 2;
  boot.loader.efi.canTouchEfiVariables = true;

  home-manager.users.${super.meta.username}.theme.wallpaper.path =
    pkgs.wallpapers.nixos-catppuccin-magenta-blue;
}
