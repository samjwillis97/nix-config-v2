{ config, lib, pkgs, system, ... }:
{
    programs.zsh.enable = true;
    environment.shells = [ pkgs.zsh ];
}
