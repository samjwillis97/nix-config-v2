{ flake, config, pkgs, lib, ... }: 
let
  inherit ( import ../../lib/user.nix { inherit lib; })
    buildUserConfig;

  # THIS IS NOT FINAL
  homeUserConfig = buildUserConfig {
    users = [
      {
        module = ../../users-v2/sam.nix;
      }
    ];
  };
in {
  imports = [ 
    flake.inputs.home-manager.nixosModules.home-manager
    ./hardware-configuration.nix
  ];

  # SO THIS CAN"T BE DONE
  # NEED TO MOVE USER CONFIG ELSEWHERE
  # SOMETHING TO DO WITH THE config KEY
  config = homeUserConfig;

  ## Here I want to set the users I want to import
  # Something like
  # config.users = [ ../../users/sam ];
  # this would define, the shell and any home modules always
  # to be present (if user is homeManaged)
  # from right here I want to be able to provide additional home modules as well
  # annoyingly has to set stuff in `config.users.users."username"..`
  # as well as `config.home-manager.users."username"..`
  # So I might need to set it like:
  # users.users = buildUsers([
  #  {
  #    module = ../../users/sam;
  #    extraHomeModules = [];
  #  }
  # ])

  home-manager.users.${config.meta.username}.theme.wallpaper.path =
    pkgs.wallpapers.nixos-catppuccin-magenta-blue;
}
