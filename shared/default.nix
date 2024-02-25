{
  imports = [ ../cachix.nix ../overlays ../modules ];
  nixpkgs.config.allowUnfree = true;
}
