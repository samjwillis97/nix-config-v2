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

    # Find the last entry within the cutoff, including sessionId, event, timestamp
    IFS=$'\t' read -r target_idx target_session_id target_worktree target_event target_timestamp < <(
      printf '%s' "$queue" | ${pkgs.jq}/bin/jq -r --argjson cutoff "$cutoff" '
        [to_entries[] | select(.value.timestamp >= $cutoff)] |
        if length == 0 then "-1\t\t\t\t"
        else last | [(.key | tostring), .value.sessionId, .value.worktree, .value.event, (.value.timestamp | tostring)] | join("\t")
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

    # Map event type to human-readable label
    case "$target_event" in
      complete)    event_label="completed" ;;
      error)       event_label="error" ;;
      permission)  event_label="needs permission" ;;
      question)    event_label="has a question" ;;
      plan_exit)   event_label="plan exit" ;;
      *)           event_label="$target_event" ;;
    esac

    # Switch to the target pane
    sess="''${target%%:*}"
    winpane="''${target#*:}"
    win="''${winpane%%.*}"
    ${pkgs.tmux}/bin/tmux switch-client -t "$sess"
    ${pkgs.tmux}/bin/tmux select-window -t "$sess:$win"
    ${pkgs.tmux}/bin/tmux select-pane -t "$sess:$winpane"

    # Remove the consumed entry from the queue (re-read to avoid race condition)
    fresh_queue=$(${pkgs.jq}/bin/jq -r '.' "$notification_file" 2>/dev/null)
    remaining=0
    if [ -n "$fresh_queue" ] && [ "$fresh_queue" != "null" ]; then
      updated=$(printf '%s' "$fresh_queue" | ${pkgs.jq}/bin/jq \
        --arg sid "$target_session_id" \
        --argjson ts "$target_timestamp" \
        '[.[] | select(.sessionId == $sid and .timestamp == $ts | not)]')
      tmp_file="$(${pkgs.coreutils}/bin/mktemp "$notification_file.XXXXXX")"
      printf '%s' "$updated" > "$tmp_file" && ${pkgs.coreutils}/bin/mv "$tmp_file" "$notification_file"

      # Count remaining valid notifications
      remaining=$(printf '%s' "$updated" | ${pkgs.jq}/bin/jq --argjson cutoff "$cutoff" \
        '[.[] | select(.timestamp >= $cutoff)] | length')
    fi

    # Show event type and remaining count
    if [ "$remaining" -gt 0 ]; then
      ${pkgs.tmux}/bin/tmux display-message "OC: $event_label ($remaining more pending)"
    else
      ${pkgs.tmux}/bin/tmux display-message "OC: $event_label"
    fi
  '';
in
{
  home.packages = [ tmux-oc-jump-notification ];
}
