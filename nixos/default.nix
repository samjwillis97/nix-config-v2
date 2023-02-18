{ config, lib, pkgs, flake, ... }:
{
    imports = [
        ./home.nix
        ./users.nix
        ./fonts.nix
    ];
}
