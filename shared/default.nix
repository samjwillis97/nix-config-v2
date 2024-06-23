{ pkgs, ... }:
{
  imports = [
    ../cachix.nix
    ../overlays
    ./meta.nix
    ./user.nix
    ./theme.nix
  ];
  nixpkgs.config.allowUnfree = true;
  nix.package = pkgs.nixVersions.latest;
}
