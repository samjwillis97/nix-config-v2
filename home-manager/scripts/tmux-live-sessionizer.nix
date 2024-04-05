{ pkgs, ... }:
let
  tmux-live-sessionizer = pkgs.writeShellScriptBin "tmux-live-sessionizer" ''
    if [[ $# -eq 1 ]]; then
        selected=$1
    else
        selected=$(tmux list-sessions -F "#{session_name}" | fzf)
    fi

    if [[ -z $selected ]]; then
        echo "0"
        exit 0
    fi

    selected_name=$(basename "$selected" | tr . _)
    tmux_running=$(pgrep tmux)

    if [[ -z $TMUX ]] && [[ -z $tmux_running ]]; then
        echo "1"
        tmux new-session -s $selected_name -c $selected
        exit 0
    fi

    if ! tmux has-session -t=$selected_name 2> /dev/null; then
        echo "2"
        tmux new-session -ds $selected_name -c $selected
    fi

    if [[ -z $TMUX ]]; then
        echo "3"
        tmux attach-session -t $selected_name
        exit 0
    fi

    echo "4"
    tmux switch-client -t $selected_name
  '';
in
{
  home.packages = [ tmux-live-sessionizer ];
}
