{ super, pkgs, ... }:
let
  osSpecificPackages = if super.meta.isDarwin then [ ] else with pkgs; [ ncdu ];
  zshImport = if super.meta.shell == "zsh" then [./zsh.nix] else [ ];
in {
  imports = [ ./zsh.nix ./tmux.nix ./git.nix ./ssh.nix ../scripts ] ++ zshImport;

  home.packages = with pkgs;
    [ bat curl p7zip ripgrep wget zip unzip htop fzf neofetch duf agenix ]
    ++ osSpecificPackages;

  programs.bat = {
    enable = true;
    config.theme = "base16-256";
  };
}
