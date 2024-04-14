{
  super,
  config,
  home,
  pkgs,
  ...
}:
{
  imports = [
    ../../shared/user.nix
    ../../home-manager/theme
    ../../home-manager/meta
    ../../home-manager/cli
  ] ++ super.meta.extraHomeModules;

  # TODO: Put in initial hashed password etc.
}
