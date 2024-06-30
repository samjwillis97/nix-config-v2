{
  super,
  config,
  home,
  pkgs,
  ...
}:
{
  imports = [
    ../../home-manager/theme
    ../../home-manager/meta
    ../../home-manager/cli
  ] ++ super.meta.extraHomeModules;

  # TODO: Put in initial hashed password etc.
}
