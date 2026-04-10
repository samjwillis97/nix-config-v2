{ pkgs, ... }:
let
  # Helper script to generate window list for fzf (used for initial load and reload)
  tmux-window-list = pkgs.writeShellScriptBin "tmux-window-list" ''
    current_session=$(${pkgs.tmux}/bin/tmux display-message -p '#{session_name}' 2>/dev/null)
    current_window=$(${pkgs.tmux}/bin/tmux display-message -p '#{window_index}' 2>/dev/null)

    while IFS=$'\t' read -r sess_name win_idx win_name panes active; do
      # Skip the current window
      if [ "$sess_name" = "$current_session" ] && [ "$win_idx" = "$current_window" ]; then
        continue
      fi

      if [ "$panes" = "1" ]; then
        pane_label="1 pane"
      else
        pane_label="$panes panes"
      fi

      if [ "$active" = "1" ]; then
        indicator="*"
      else
        indicator=""
      fi

      label="$sess_name:$win_idx  $win_name  $pane_label $indicator"
      target="$sess_name:$win_idx"
      printf '%s\t%s\t%s\n' "$label" "$target" "$win_name"
    done < <(${pkgs.tmux}/bin/tmux list-windows -a \
      -F '#{session_name}	#{window_index}	#{window_name}	#{window_panes}	#{window_active}' 2>/dev/null)
  '';

  # Helper script to pick a target session for moving a window
  tmux-move-window-picker = pkgs.writeShellScriptBin "tmux-move-window-picker" ''
    # Usage: tmux-move-window-picker <source_session:window_index>
    source_target="$1"
    if [ -z "$source_target" ]; then
      exit 1
    fi

    source_sess="''${source_target%%:*}"

    # Build session list (exclude the source session since the window is already there)
    session_list=""
    while IFS=$'\t' read -r name windows attached; do
      # Skip the session the window is already in
      if [ "$name" = "$source_sess" ]; then
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
      entry="$label"$'\t'"$name"

      if [ -z "$session_list" ]; then
        session_list="$entry"
      else
        session_list="$session_list"$'\n'"$entry"
      fi
    done < <(${pkgs.tmux}/bin/tmux list-sessions \
      -F '#{session_name}	#{session_windows}	#{session_attached}' 2>/dev/null \
      | ${pkgs.coreutils}/bin/sort -t$'\t' -k1,1)

    if [ -z "$session_list" ]; then
      ${pkgs.tmux}/bin/tmux display-message "No sessions available"
      exit 0
    fi

    selected=$(printf '%s\n' "$session_list" | \
      ${pkgs.fzf}/bin/fzf \
        --ansi \
        --with-nth=1 \
        --delimiter=$'\t' \
        --preview 'tmux-metadata-preview {2}' \
        --preview-window=right:60% \
        --header="Move $source_target to session:" \
        --no-sort \
        --border=none)

    if [ -n "$selected" ]; then
      target_sess=$(printf '%s' "$selected" | ${pkgs.coreutils}/bin/cut -f2)
      ${pkgs.tmux}/bin/tmux move-window -s "$source_target" -t "$target_sess:"
      ${pkgs.tmux}/bin/tmux display-message "Moved window to $target_sess"
    fi
  '';

  tmux-window-picker = pkgs.writeShellScriptBin "tmux-window-picker" ''
    window_list=$(tmux-window-list)

    if [ -z "$window_list" ]; then
      ${pkgs.tmux}/bin/tmux display-message "No other windows"
      exit 0
    fi

    # ctrl-x: kill window and reload list (stays in fzf)
    # ctrl-r: rename window (exits fzf via --expect, then uses tmux command-prompt)
    # ctrl-g: move window to another session (exits fzf via --expect, opens second picker)
    # enter: switch to window
    selected=$(printf '%s\n' "$window_list" | \
      ${pkgs.fzf}/bin/fzf \
        --ansi \
        --with-nth=1 \
        --delimiter=$'\t' \
        --preview 'tmux-metadata-preview {2}' \
        --preview-window=right:60% \
        --header=$'enter: switch | ctrl-x: kill | ctrl-r: rename | ctrl-g: move' \
        --expect='ctrl-r,ctrl-g' \
        --bind="ctrl-x:execute-silent(${pkgs.tmux}/bin/tmux kill-window -t '{2}')+reload(tmux-window-list)" \
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
    win_name=$(printf '%s' "$entry" | ${pkgs.coreutils}/bin/cut -f3)

    if [ "$key" = "ctrl-r" ]; then
      # Rename: use tmux command-prompt with the current name pre-filled
      ${pkgs.tmux}/bin/tmux command-prompt -I "$win_name" -p "Rename window:" \
        "rename-window -t '$target' '%%'"
      exit 0
    fi

    if [ "$key" = "ctrl-g" ]; then
      # Move: open a second fzf picker to select the target session
      tmux-move-window-picker "$target"
      exit 0
    fi

    # Default (enter): switch to window
    sess="''${target%%:*}"
    win="''${target#*:}"
    ${pkgs.tmux}/bin/tmux switch-client -t "$sess"
    ${pkgs.tmux}/bin/tmux select-window -t "$sess:$win"
  '';
in
{
  home.packages = [ tmux-window-picker tmux-window-list tmux-move-window-picker ];
}
