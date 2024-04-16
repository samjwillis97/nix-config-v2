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

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
  # Runs the VM just in the terminal - no seperate window
  virtualisation.graphics = false;
  # Allows running on darwin
  virtualisation.host.pkgs = flake.inputs.nixpkgs.legacyPackages.aarch64-darwin;

  # Still trying to get secrets working
  # virtualisation.sharedDirectories = {
  #   agenix = {
  #     source = "/var/agenix";
  #     target = "/var/agenix";
  #   };
  # # };
  # virtualisation.fileSystems = {
  #   "/var/agenix" = {
  #     neededForBoot = true;
  #     mountPoint = "/var/agenix";
  #   };
  # };

  # Forwarding the ports of interest from the guest to the host
  virtualisation.forwardPorts = [
    { from = "host"; host.port = 8123; guest.port = 8123; }
  ];

  # Accessing webpages through the forwarding doesn't work without this
  networking.firewall.enable = lib.mkForce false;
}
