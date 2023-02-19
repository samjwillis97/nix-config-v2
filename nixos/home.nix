{ config, lib, pkgs, flake, system, ... }:

{
  imports = [
    flake.inputs.home.nixosModules.home-manager
    ../modules/meta.nix
  ];

  config = {
    home-manager = {
      useUserPackages = true;
      users.${config.nixos.home.username} = ../home-manager/default;
      extraSpecialArgs = {
        inherit flake system;
        super = config;
      };
    };
  };
}
