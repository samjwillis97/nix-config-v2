{ config, lib, pkgs, flake, ... }:
{
    imports = [
        ./meta.nix
        ./home.nix
        ./user.nix
        ./fonts.nix
        ./ssh.nix
        ./locale.nix
        ./tailscale.nix
    ];
}
