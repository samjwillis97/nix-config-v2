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

  environment.pathsToLink = if useHomeManager then [ "/share/applications" "/share/xdg-desktop-portal" ] else [ ];

  modules.system.users.standardUser = {
    enable = true;
    username = username;
    home-manager = {
      enable = useHomeManager;
      extraModules = extraHomeModules;
    };
  };
}
