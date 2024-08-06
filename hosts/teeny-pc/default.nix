{ ... }: 
{
  imports = [
    ../../nixos
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.networkmanager.enable = true;
  networking.firewall.enable = false;

  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
    };
  };

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "btrfs";
  };

  system.stateVersion = "24.05";
}
