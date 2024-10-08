{ pkgs, ... }:
{
  imports = [
    ../cachix.nix
    ../overlays
    ./meta.nix
    ./user.nix
    ./theme.nix
  ];
  # This is due to 1Passwordgui being broken for darwin
  # I have a work around currently
  nixpkgs.config.allowBroken = true;
  nixpkgs.config.allowUnfree = true;
  nix.package = pkgs.nixVersions.latest;
}
