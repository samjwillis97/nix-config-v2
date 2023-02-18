{ config, pkgs, flake, ... }:
let
    inherit (flake) inputs;
in
{
    imports = [
        ./hardware-configuration.nix
        ../../nixos
    ];
}
