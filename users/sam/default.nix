{ super, config, home, pkgs, ... }: {
  imports = [
    ../../modules/user.nix
    ../../home-manager/theme
    ../../home-manager/meta
    ../../home-manager/cli
  ] ++ super.meta.extraHomeModules;

  user.shell = pkgs.zsh;

  # TODO: Put in initial hashed password etc.
}
