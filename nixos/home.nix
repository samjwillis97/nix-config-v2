{ super, config, lib, pkgs, flake, system, ... }:

{
  imports = [
    flake.inputs.home-manager.nixosModules.home-manager
    ../modules/meta.nix
  ];

  config = {
    home-manager = {
      useUserPackages = true;
      users.${super.meta.username} = import ../users/${super.meta.username};
      extraSpecialArgs = {
        inherit flake system;
        super = super // {
          super.meta.extraHomeModules = super.meta.extraHomeModules ++ [ ../home-manager/nixos.nix ];
        };
      };
    };
  };
}
