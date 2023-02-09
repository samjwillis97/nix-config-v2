# TODO:
#   - i3Status/Rust
#   - Dunst
#   - Rofi
#   - i3Lock
#   - AutoRandr
{ config, lib, pkgs, ... }:
{
    imports = [
        ./rofi.nix
    ];
}