{ ... }:
{
  imports = [
    ./git-bare-clone.nix
    ./hugo-reveal-bootstrap.nix
    ./tmux-sessionizer.nix
    ./tmux-live-sessionizer.nix
    ./nix-shells
    # ./tmux-cht.nix
  ];
}
