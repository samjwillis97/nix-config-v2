{
  config,
  pkgs,
  flake,
  ...
}:
{
  imports = [
    ../../nix-darwin
    ../../nix-darwin/microvm/default.nix
  ];

  system.stateVersion = 5;
}
