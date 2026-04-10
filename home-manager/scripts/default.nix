{ ... }:
{
  imports = [
    ./git-bare-clone.nix
    ./hugo-reveal-bootstrap.nix
    ./tmux-sessionizer.nix
    ./tmux-live-sessionizer.nix
    ./tmux-session-preview.nix
    ./tmux-oc-session-picker.nix
    ./tmux-oc-notification-picker.nix
    ./tmux-session-picker.nix
    ./tmux-window-picker.nix
    ./tmux-metadata-preview.nix
    ./tmux-oc-notification-status.nix
    ./nix-shells
    # ./tmux-cht.nix
  ];
}
