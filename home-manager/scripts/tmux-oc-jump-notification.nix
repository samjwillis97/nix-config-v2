{ pkgs, ... }:
let
  tmux-oc-jump-notification = pkgs.writeShellScriptBin "tmux-oc-jump-notification" ''
    notification_file="$HOME/.cache/opencode/tmux-notifications.json"
    pids_dir="$HOME/.cache/opencode/tmux-cache/pids"

    # Check if notification file exists
    if [ ! -f "$notification_file" ]; then
      ${pkgs.tmux}/bin/tmux display-message "No recent notifications"
      exit 0
    fi

    # Read the queue
    queue=$(${pkgs.jq}/bin/jq -r '.' "$notification_file" 2>/dev/null)
    if [ -z "$queue" ] || [ "$queue" = "[]" ] || [ "$queue" = "null" ]; then
      ${pkgs.tmux}/bin/tmux display-message "No recent notifications"
      exit 0
    fi

    # Get current time
    now=$(${pkgs.coreutils}/bin/date +%s)
    max_age_secs=1800  # 30 minutes
    cutoff=$(( (now - max_age_secs) * 1000 ))  # convert to milliseconds

    # Find the last entry within the cutoff, including sessionId
    IFS=$'\t' read -r target_idx target_session_id target_worktree < <(
      printf '%s' "$queue" | ${pkgs.jq}/bin/jq -r --argjson cutoff "$cutoff" '
        [to_entries[] | select(.value.timestamp >= $cutoff)] |
        if length == 0 then "-1\t\t"
        else last | [(.key | tostring), .value.sessionId, .value.worktree] | join("\t")
        end
      '
    )
    target_idx=''${target_idx:--1}

    if [ "$target_idx" -eq -1 ] || [ -z "$target_worktree" ]; then
      ${pkgs.tmux}/bin/tmux display-message "No recent notifications"
      exit 0
    fi

    # Strategy 1: Find tmux pane via PID mapping (matches specific OpenCode session)
    target=""
    if [ -n "$target_session_id" ] && [ -d "$pids_dir" ]; then
      for pid_file in "$pids_dir"/*.json; do
        [ -f "$pid_file" ] || continue
        file_session_id=$(${pkgs.jq}/bin/jq -r '.currentSessionId // empty' "$pid_file" 2>/dev/null)
        if [ "$file_session_id" = "$target_session_id" ]; then
          # Extract pane_pid from filename
          match_pid=$(${pkgs.coreutils}/bin/basename "$pid_file" .json)
          # Find tmux pane with this pane_pid
          while IFS=' ' read -r pane_target pane_pid; do
            if [ "$pane_pid" = "$match_pid" ]; then
              target="$pane_target"
              break
            fi
          done < <(${pkgs.tmux}/bin/tmux list-panes -a \
            -F '#{session_name}:#{window_index}.#{pane_index} #{pane_pid}' 2>/dev/null)
          break
        fi
      done
    fi

    # Strategy 2: Fall back to worktree + opencode command matching
    if [ -z "$target" ]; then
      while IFS=$'\t' read -r pane_target pane_cmd pane_path; do
        if [ "$pane_path" = "$target_worktree" ]; then
          target="$pane_target"
          break
        fi
      done < <(${pkgs.tmux}/bin/tmux list-panes -a \
        -F '#{session_name}:#{window_index}.#{pane_index}	#{pane_current_command}	#{pane_current_path}' 2>/dev/null \
        | ${pkgs.gnugrep}/bin/grep -i opencode)
    fi

    if [ -z "$target" ]; then
      ${pkgs.tmux}/bin/tmux display-message "Notification session not found"
      exit 0
    fi

    # Switch to the target pane
    sess="''${target%%:*}"
    winpane="''${target#*:}"
    win="''${winpane%%.*}"
    ${pkgs.tmux}/bin/tmux switch-client -t "$sess"
    ${pkgs.tmux}/bin/tmux select-window -t "$sess:$win"
    ${pkgs.tmux}/bin/tmux select-pane -t "$sess:$winpane"

    # Remove the consumed entry from the queue (atomic write)
    updated=$(printf '%s' "$queue" | ${pkgs.jq}/bin/jq "del(.[$target_idx])")
    tmp_file="$(${pkgs.coreutils}/bin/mktemp "$notification_file.XXXXXX")"
    printf '%s' "$updated" > "$tmp_file" && ${pkgs.coreutils}/bin/mv "$tmp_file" "$notification_file"
  '';
in
{
  home.packages = [ tmux-oc-jump-notification ];
}
