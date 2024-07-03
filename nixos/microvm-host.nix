{ flake, ... }:
{
  imports = [ flake.inputs.microvm.nixosModules.host ];
  modules.virtualisation.microvm-host.enable = true;
}
