{ super, config, lib, pkgs, ... }:
let
  osSpecificPackages = if super.meta.isDarwin then [ ] else with pkgs; [ ncdu ];
in {
  imports = [ ./zsh.nix ./tmux.nix ./git.nix ./ssh.nix ../scripts ];

  home.packages = with pkgs;
    [
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
    ] ++ osSpecificPackages;

  programs.bat = {
    enable = true;
    config.theme = "base16-256";
  };
}
