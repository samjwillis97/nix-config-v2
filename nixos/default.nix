{
  super,
  config,
  lib,
  pkgs,
  flake,
  ...
}:
{
  imports = [
    ./meta.nix
    ./user.nix
    ./ssh.nix
    ./locale.nix
    ./tailscale.nix
  ];

  networking.hostName = super.meta.hostname;
  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    agenix
  ];
}
