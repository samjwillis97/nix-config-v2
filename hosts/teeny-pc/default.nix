{ ... }:
{
  imports = [
    ../../nixos
    ../../modules/ops/deploy.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "btrfs";
  };

  modules.ops.deploy = {
    createDeployUser = true;
  };

  system.stateVersion = "24.05";
}
