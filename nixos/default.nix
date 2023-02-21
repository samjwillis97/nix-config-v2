{ config, lib, pkgs, flake, ... }:
{
    imports = [
        ./home.nix
        ./user.nix
        ./fonts.nix
    ];
}
