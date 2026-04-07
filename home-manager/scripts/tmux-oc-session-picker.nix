{ pkgs, ... }:
let
  tmux-oc-session-picker = pkgs.writeShellScriptBin "tmux-oc-session-picker" ''
    current_session=$(${pkgs.tmux}/bin/tmux display-message -p '#{session_name}')

    session=$(${pkgs.tmux}/bin/tmux list-sessions -F '#{session_name}' | \
      ${pkgs.fzf}/bin/fzf \
        --preview 'tmux-session-preview {}' \
        --preview-window=right:60%:wrap \
        --header='Switch Session' \
        --no-sort \
        --border=none \
        --query="$current_session")

    if [ -n "$session" ]; then
      ${pkgs.tmux}/bin/tmux switch-client -t "$session"
    fi
  '';
in
{
  home.packages = [ tmux-oc-session-picker ];
}
