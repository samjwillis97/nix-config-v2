{ config, lib, pkgs, ... }: {
  imports = [
    ./zsh.nix
    ./tmux.nix
    ./git.nix
    ./ssh.nix
    # ../nvim
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
    unzip
    difftastic
    htop
    fzf
    direnv
    neofetch
    _1password
    my-neovim

    nodePackages.wrangler
  ];

  programs.bat = {
    enable = true;
    config.theme = "base16-256";
  };
}
