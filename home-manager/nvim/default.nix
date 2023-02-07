{ config, lib, pkgs, ... }:
{
    home.programs.neovim = {
        enable = true;
        defaultEditor = true;
    };
}
