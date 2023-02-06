{ config, lib, pkgs, ... } :
{
    imports = [
        ./home.nix
        ./meta.nix
        ./system.nix
    ];
}
