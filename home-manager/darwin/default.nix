{ ... }:
{
  imports = [
    ../../hm-modules/darwin.nix
    ../ghostty
  ];

  modules.darwin.enable = true;
}
