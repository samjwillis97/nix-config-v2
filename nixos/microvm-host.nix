{ flake, ... }:
{
  imports = [
    ../modules/virtualisation/microvm-host.nix
    flake.inputs.microvm.nixosModules.host
  ];
  modules.virtualisation.microvm-host.enable = true;
}
