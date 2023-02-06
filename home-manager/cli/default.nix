{ config, lib, pkgs, ... }:
{
    home.packages = with pkgs; [
        bat
        curl
        jq
        p7zip
        ripgrep
        wget
        zip
    ];
}
