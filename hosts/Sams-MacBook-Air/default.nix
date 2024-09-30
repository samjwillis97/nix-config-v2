{
  config,
  pkgs,
  flake,
  ...
}:
{
  imports = [ ../../nix-darwin ];

  system.stateVersion = 5;
}
