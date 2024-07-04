{
  super,
  flake,
  system,
  ...
}:

{
  imports = [
    flake.inputs.home-manager.nixosModules.home-manager
    ../shared/meta.nix
  ];

  config = {
    home-manager = {
      useUserPackages = true;
      users.${super.meta.username} = import ../users/${super.meta.username};
      extraSpecialArgs = {
        inherit flake system super;
      };
    };
  };
}
