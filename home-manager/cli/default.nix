{ config, lib, pkgs, ... }:
{
    imports = [
        ./zsh
        ./tmux
        ../nvim
    ];

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
