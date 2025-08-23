{
  config,
  pkgs,
  lib,
  flake,
  ...
}:
{
  imports = [
    (flake.inputs.nixpkgs + "/nixos/modules/virtualisation/qemu-vm.nix")
    ../../nixos
  ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
  # Runs the VM just in the terminal - no seperate window
  virtualisation.graphics = false;
  # Allows running on darwin
  virtualisation.host.pkgs = flake.inputs.nixpkgs.legacyPackages.aarch64-darwin;

  virtualisation = {
    diskSize = 10000;
  };

  # Forwarding the ports of interest from the guest to the host
  virtualisation.forwardPorts = [
    {
      from = "host";
      host.port = 3000;
      guest.port = 3000;
    }
  ];
}
