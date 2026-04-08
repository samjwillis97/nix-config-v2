{ pkgs, ... }:
let
  tmux-oc-session-picker = pkgs.writeShellScriptBin "tmux-oc-session-picker" ''
    pids_dir="$HOME/.cache/opencode/tmux-cache/pids"
    sessions_dir="$HOME/.cache/opencode/tmux-cache/sessions"

    # List all opencode panes, resolve PID mapping for session titles
    pane_list=""
    while IFS=$'\t' read -r target pane_pid cmd pane_path; do
      sess="''${target%%:*}"
      label="$sess"

      # Look up PID mapping to get session title from cache
      pid_file="$pids_dir/$pane_pid.json"
      session_id=""
      if [ -f "$pid_file" ]; then
        session_id=$(${pkgs.jq}/bin/jq -r '.currentSessionId // empty' "$pid_file" 2>/dev/null)
      fi

      title=""
      if [ -n "$session_id" ]; then
        session_file="$sessions_dir/$session_id.json"
        if [ -f "$session_file" ]; then
          title=$(${pkgs.jq}/bin/jq -r '.title // empty' "$session_file" 2>/dev/null)
        fi
      fi

      # Fallback: scrape session title from the pane content.
      # The OpenCode TUI shows "# <title>   <tokens>  <pct>% ($<cost>)" near the top.
      if [ -z "$title" ]; then
        title=$(${pkgs.tmux}/bin/tmux capture-pane -t "$target" -p 2>/dev/null \
          | ${pkgs.gnugrep}/bin/grep -m1 '# .*[0-9].*%.*\$' \
          | ${pkgs.gnused}/bin/sed 's/.*# //' \
          | ${pkgs.gnused}/bin/sed 's/[[:space:]]\{2,\}[0-9].*//')
      fi

      if [ -n "$title" ]; then
        label="$sess: $title"
      fi

      entry="$label"$'\t'"$target"$'\t'"$pane_path"
      if [ -z "$pane_list" ]; then
        pane_list="$entry"
      else
        pane_list="$pane_list"$'\n'"$entry"
      fi
    done < <(${pkgs.tmux}/bin/tmux list-panes -a \
      -F '#{session_name}:#{window_index}.#{pane_index}	#{pane_pid}	#{pane_current_command}	#{pane_current_path}' 2>/dev/null \
      | ${pkgs.gnugrep}/bin/grep -i opencode)

    if [ -z "$pane_list" ]; then
      echo "No opencode panes found"
      exit 0
    fi

    # fzf shows column 1 (label), passes full line to preview
    selected=$(printf '%s\n' "$pane_list" | \
      ${pkgs.fzf}/bin/fzf \
        --ansi \
        --with-nth=1 \
        --delimiter=$'\t' \
        --preview 'tmux-session-preview {2}' \
        --preview-window=right:60%:wrap \
        --header='Switch to OpenCode pane' \
        --no-sort \
        --border=none)

    if [ -n "$selected" ]; then
      target=$(printf '%s' "$selected" | ${pkgs.coreutils}/bin/cut -f2)
      sess="''${target%%:*}"
      winpane="''${target#*:}"
      win="''${winpane%%.*}"
      ${pkgs.tmux}/bin/tmux switch-client -t "$sess"
      ${pkgs.tmux}/bin/tmux select-window -t "$sess:$win"
      ${pkgs.tmux}/bin/tmux select-pane -t "$sess:$winpane"
    fi
  '';
in
{
  home.packages = [ tmux-oc-session-picker ];
}
