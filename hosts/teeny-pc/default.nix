{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ../../nixos
    ../../modules/ops/deploy.nix
  ];

  modules.ops.deploy = {
    createDeployUser = true;
  };
}
