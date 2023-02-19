{ config, lib, pkgs, flake, system, ... }:

{
  imports = [
    flake.inputs.home-manager.nixosModules.home-manager
    ../modules/meta.nix
  ];

  config = {
    home-manager = {
      useUserPackages = true;
      users.${config.meta.username} = ../home-manager/default;
      extraSpecialArgs = {
        inherit flake system;
        super = config;
      };
    };
  };
}
