{ super, pkgs, ... }:
let
  # Need to fix f for nixos
  osSpecificPackages = if super.meta.isDarwin then with pkgs; [ f ] else with pkgs; [ ncdu ];
in
{
  imports = [
    ./zsh.nix
    ./tmux.nix
    ./zellij.nix
    ./git.nix
    ./rmtree.nix
    ./worktree.nix
    ./ssh.nix
    ../scripts
  ];

  home.packages =
    with pkgs;
    [
      bat
      curl
      p7zip
      ripgrep
      wget
      zip
      unzip
      htop
      fzf
      neofetch
      duf
      agenix
    ]
    ++ osSpecificPackages;

  programs.shc = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.bat = {
    enable = true;
    config.theme = "base16-256";
  };
}
