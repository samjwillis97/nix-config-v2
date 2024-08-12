{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../nixos
    ../../modules/ops/deploy.nix
    ../../modules/virtualisation/microvm-host.nix
  ];

  modules = {
    ops.deploy = {
      createDeployUser = true;
    };

    virtualisation.microvm-host = {
      enable = true;
      externalInterface = "enp2s0";
      vms = [
        "steve"
      ];
    };
  };
}
