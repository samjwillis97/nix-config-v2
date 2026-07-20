{
  config,
  pkgs,
  flake,
  ...
}:
{
  imports = [
    ../../../hm-modules/omp.nix
  ];

  modules.omp = {
    enable = true;
  };
}
