{
  config,
  pkgs,
  lib,
  flake,
  ...
}:
{
  imports = [ 
    ( flake.inputs.nixpkgs + "/nixos/modules/virtualisation/qemu-vm.nix" )
    ../../nixos
  ];

  # boot.loader.grub.enable = true;
  # boot.loader.grub.version = 2;
  # boot.loader.grub.device = "/dev/sda"; # or "nodev" for efi only

  # virtualisation = {
  #   memorySize = 4096;
  #   cores = 8;
  # };

  # boot.initrd.availableKernelModules = [ "ata_piix" "ohci_pci" "ehci_pci" "ahci" "sd_mod" "sr_mod" ];
  # boot.initrd.kernelModules = [ ];
  # boot.kernelModules = [ ];
  # boot.extraModulePackages = [ ];

  # fileSystems."/" =
  # { device = "/dev/disk/by-uuid/bda6e682-bbae-44b5-933e-9c4b52c2ded2";
  # fsType = "ext4";
  # };

  # swapDevices =
  # [ { device = "/dev/disk/by-uuid/aa80d8c2-1851-4b12-a079-61efd69ff884"; }
  # ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  # networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.enp0s3.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
  virtualisation.graphics = false;
  virtualisation.host.pkgs = flake.inputs.nixpkgs.legacyPackages.aarch64-darwin;
}
