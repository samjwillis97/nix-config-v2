{ config, lib, pkgs, ... }:
{
    imports = [
        ./zsh.nix
        ./tmux.nix
        ./git.nix
        ./ssh.nix
        ../nvim
        ../scripts
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
        fzf
        direnv
        neofetch
        _1password
    ];

    programs.bat = {
        enable = true;
        config.theme = "base16-256";
    };
}
