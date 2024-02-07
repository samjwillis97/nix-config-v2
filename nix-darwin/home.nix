{ super, flake, config, lib, pkgs, system, ... }:
let inherit (super.meta) username;
in {
  imports = [ flake.inputs.home-manager.darwinModules.home-manager ];

  programs.zsh.enable = true;
  environment.shells = [ pkgs.zsh ];

  users.users.${username} = {
    home = "/Users/${username}";
    # FIXME: why I can't use `pkgs.zsh` here?
    shell = "/run/current-system/sw/bin/zsh";
  };

  home-manager = {
    useUserPackages = true;
    users.${username} = import ../users/${username};
    extraSpecialArgs = { inherit flake system super; };
  };
}
