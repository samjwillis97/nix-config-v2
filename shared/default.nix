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
  # FIXES: https://discourse.nixos.org/t/store-path-starts-with-illegal-character/42050/3
  nix.package = pkgs.nixVersions.unstable;
}
