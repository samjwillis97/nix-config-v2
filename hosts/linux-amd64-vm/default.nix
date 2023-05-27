{ ... }: {
  imports = [ ./hardware-configuration.nix ../../nixos ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
