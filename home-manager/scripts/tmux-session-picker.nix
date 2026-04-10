{ pkgs, ... }:
let
  # Helper script to generate session list for fzf (used for initial load and reload)
  tmux-session-list = pkgs.writeShellScriptBin "tmux-session-list" ''
    current_session=$(${pkgs.tmux}/bin/tmux display-message -p '#{session_name}' 2>/dev/null)

    while IFS=$'\t' read -r name windows attached; do
      # Skip the current session
      if [ "$name" = "$current_session" ]; then
        continue
      fi

      if [ "$attached" = "1" ]; then
        indicator="(attached)"
      else
        indicator=""
      fi

      if [ "$windows" = "1" ]; then
        win_label="1 window"
      else
        win_label="$windows windows"
      fi

      label="$name  $win_label $indicator"
      printf '%s\t%s\n' "$label" "$name"
    done < <(${pkgs.tmux}/bin/tmux list-sessions \
      -F '#{session_name}	#{session_windows}	#{session_attached}' 2>/dev/null \
      | ${pkgs.coreutils}/bin/sort -t$'\t' -k1,1)
  '';

  tmux-session-picker = pkgs.writeShellScriptBin "tmux-session-picker" ''
    session_list=$(tmux-session-list)

    if [ -z "$session_list" ]; then
      ${pkgs.tmux}/bin/tmux display-message "No other sessions"
      exit 0
    fi

    # ctrl-x: kill session and reload list (stays in fzf)
    # ctrl-r: rename session (exits fzf via --expect, then uses tmux command-prompt)
    # enter: switch to session
    selected=$(printf '%s\n' "$session_list" | \
      ${pkgs.fzf}/bin/fzf \
        --ansi \
        --with-nth=1 \
        --delimiter=$'\t' \
        --preview 'tmux-metadata-preview {2}' \
        --preview-window=right:60% \
        --header=$'enter: switch | ctrl-x: kill | ctrl-r: rename' \
        --expect='ctrl-r' \
        --bind="ctrl-x:execute-silent(${pkgs.tmux}/bin/tmux kill-session -t '{2}')+reload(tmux-session-list)" \
        --no-sort \
        --border=none)

    if [ -z "$selected" ]; then
      exit 0
    fi

    # Parse fzf output: first line is the key pressed (empty for enter), rest is selected line
    key=$(printf '%s' "$selected" | ${pkgs.coreutils}/bin/head -n1)
    entry=$(printf '%s' "$selected" | ${pkgs.coreutils}/bin/tail -n +2)

    if [ -z "$entry" ]; then
      exit 0
    fi

    target=$(printf '%s' "$entry" | ${pkgs.coreutils}/bin/cut -f2)

    if [ "$key" = "ctrl-r" ]; then
      # Rename: use tmux command-prompt with the current name pre-filled
      ${pkgs.tmux}/bin/tmux command-prompt -I "$target" -p "Rename session:" \
        "rename-session -t '$target' '%%'"
      exit 0
    fi

    # Default (enter): switch to session
    ${pkgs.tmux}/bin/tmux switch-client -t "$target"
  '';
in
{
  home.packages = [ tmux-session-picker tmux-session-list ];
}
