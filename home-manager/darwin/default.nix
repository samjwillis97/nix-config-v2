{ ... }:
{
  imports = [
    ../../hm-modules/darwin.nix
    ../../hm-modules/ghostty
  ];

  modules.darwin.enable = true;
  modules.ghostty.enable = true;
}
