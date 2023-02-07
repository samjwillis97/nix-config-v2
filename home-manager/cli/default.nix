{ config, lib, pkgs, ... }:
{
    imports = [
        ./zsh.nix
        ./tmux.nix
        ./git.nix
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
        difftastic
        htop
    ];
}
