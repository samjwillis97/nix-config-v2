{ config, pkgs, lib, flake, ... }:
{
    programs.tmux = {
        enable = true;
    };
}
