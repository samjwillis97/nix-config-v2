{ flake, super, ... }:
let
  inherit (super.meta) username useHomeManager extraHomeModules;
in
{
  imports = [
    flake.inputs.home-manager.nixosModules.home-manager
    ../shared/meta.nix # Feel like I don't need this
    ../modules/system/users
  ];

  modules.system.users.standardUser = {
    enable = true;
    username = username;
    home-manager = {
      enable = useHomeManager;
      extraModules = extraHomeModules;
    };
  };
}
