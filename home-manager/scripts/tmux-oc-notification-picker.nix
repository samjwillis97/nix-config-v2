{ pkgs, ... }:
let
  # Helper script to dismiss a single notification by sessionId+timestamp
  tmux-oc-dismiss-notification = pkgs.writeShellScriptBin "tmux-oc-dismiss-notification" ''
    notification_file="$HOME/.cache/opencode/tmux-notifications.json"
    session_id="$1"
    timestamp="$2"

    if [ -z "$session_id" ] || [ -z "$timestamp" ]; then
      exit 1
    fi

    if [ ! -f "$notification_file" ]; then
      exit 0
    fi

    fresh_queue=$(${pkgs.jq}/bin/jq -r '.' "$notification_file" 2>/dev/null)
    if [ -n "$fresh_queue" ] && [ "$fresh_queue" != "null" ]; then
      updated=$(printf '%s' "$fresh_queue" | ${pkgs.jq}/bin/jq \
        --arg sid "$session_id" \
        --argjson ts "$timestamp" \
        '[.[] | select(.sessionId == $sid and .timestamp == $ts | not)]')
      tmp_file="$(${pkgs.coreutils}/bin/mktemp "$notification_file.XXXXXX")"
      printf '%s' "$updated" > "$tmp_file" && ${pkgs.coreutils}/bin/mv "$tmp_file" "$notification_file"
    fi
  '';

  # Helper script to clear all notifications
  tmux-oc-clear-notifications = pkgs.writeShellScriptBin "tmux-oc-clear-notifications" ''
    notification_file="$HOME/.cache/opencode/tmux-notifications.json"
    tmp_file="$(${pkgs.coreutils}/bin/mktemp "$notification_file.XXXXXX")"
    printf '[]' > "$tmp_file" && ${pkgs.coreutils}/bin/mv "$tmp_file" "$notification_file"
  '';

  # Helper script to generate the notification list for fzf
  tmux-oc-notification-list = pkgs.writeShellScriptBin "tmux-oc-notification-list" ''
    notification_file="$HOME/.cache/opencode/tmux-notifications.json"

    if [ ! -f "$notification_file" ]; then
      exit 0
    fi

    queue=$(${pkgs.jq}/bin/jq -r '.' "$notification_file" 2>/dev/null)
    if [ -z "$queue" ] || [ "$queue" = "[]" ] || [ "$queue" = "null" ]; then
      exit 0
    fi

    now=$(${pkgs.coreutils}/bin/date +%s)
    max_age_secs=900
    cutoff=$(( (now - max_age_secs) * 1000 ))

    # Output tab-separated: display_col \t sessionId \t worktree \t event \t timestamp
    # display_col is: [event]  worktree_basename  "title"  relative_time
    # Sorted most-recent-first
    printf '%s' "$queue" | ${pkgs.jq}/bin/jq -r --argjson cutoff "$cutoff" --argjson now_ms "$((now * 1000))" '
      [.[] | select(.timestamp >= $cutoff)]
      | sort_by(-.timestamp)
      | .[]
      | {
          event: .event,
          worktree_base: (.worktree | split("/") | last),
          title: (.title // ""),
          age_secs: (($now_ms - .timestamp) / 1000 | floor),
          sessionId: .sessionId,
          worktree: .worktree,
          timestamp: .timestamp
        }
      | .age_str = (
          if .age_secs < 60 then "just now"
          elif .age_secs < 3600 then "\(.age_secs / 60 | floor)m ago"
          else "\(.age_secs / 3600 | floor)h ago"
          end
        )
      | "[\(.event)]\t\(.worktree_base)\t\(.title)\t\(.age_str)\t\(.sessionId)\t\(.worktree)\t\(.timestamp)\t\(.event)"
    '
  '';

  # Main picker script
  tmux-oc-notification-picker = pkgs.writeShellScriptBin "tmux-oc-notification-picker" ''
    notification_file="$HOME/.cache/opencode/tmux-notifications.json"
    pids_dir="$HOME/.cache/opencode/tmux-cache/pids"

    # Check if there are any notifications to show
    entries=$(tmux-oc-notification-list)
    if [ -z "$entries" ]; then
      ${pkgs.tmux}/bin/tmux display-message "No pending notifications"
      exit 0
    fi

    # Launch fzf with actions
    # Columns: 1=[event] 2=worktree 3=title 4=age | 5=sessionId 6=worktree_full 7=timestamp 8=event_raw
    # ctrl-d: dismiss selected notification and reload the list (stays in fzf)
    # ctrl-x: clear all notifications and close (via --expect)
    # enter: select notification for jump & dismiss (default accept)
    selected=$(printf '%s\n' "$entries" | \
      ${pkgs.fzf}/bin/fzf \
        --with-nth=1..4 \
        --delimiter=$'\t' \
        --header=$'enter=jump & dismiss | ctrl-d=dismiss | ctrl-x=clear all' \
        --expect='ctrl-x' \
        --bind="ctrl-d:execute-silent(tmux-oc-dismiss-notification {5} {7})+reload(tmux-oc-notification-list)" \
        --no-sort \
        --border=none \
        --tabstop=16)

    if [ -z "$selected" ]; then
      exit 0
    fi

    # Parse fzf output: first line is the key pressed (empty for enter), rest is selected line
    key=$(printf '%s' "$selected" | ${pkgs.coreutils}/bin/head -n1)
    entry=$(printf '%s' "$selected" | ${pkgs.coreutils}/bin/tail -n +2)

    # Handle clear all
    if [ "$key" = "ctrl-x" ]; then
      tmux-oc-clear-notifications
      ${pkgs.tmux}/bin/tmux display-message "OC: all notifications cleared"
      exit 0
    fi

    # For jump, we need the selected entry
    if [ -z "$entry" ]; then
      exit 0
    fi

    # Parse selected entry
    session_id=$(printf '%s' "$entry" | ${pkgs.coreutils}/bin/cut -f5)
    worktree=$(printf '%s' "$entry" | ${pkgs.coreutils}/bin/cut -f6)
    timestamp=$(printf '%s' "$entry" | ${pkgs.coreutils}/bin/cut -f7)
    event=$(printf '%s' "$entry" | ${pkgs.coreutils}/bin/cut -f8)

    # Dismiss the notification
    tmux-oc-dismiss-notification "$session_id" "$timestamp"

    # Handle jump (enter key)
    # Strategy 1: Find tmux pane via PID mapping
    target=""
    if [ -n "$session_id" ] && [ -d "$pids_dir" ]; then
      for pid_file in "$pids_dir"/*.json; do
        [ -f "$pid_file" ] || continue
        file_session_id=$(${pkgs.jq}/bin/jq -r '.currentSessionId // empty' "$pid_file" 2>/dev/null)
        if [ "$file_session_id" = "$session_id" ]; then
          match_pid=$(${pkgs.coreutils}/bin/basename "$pid_file" .json)
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
        if [ "$pane_path" = "$worktree" ]; then
          target="$pane_target"
          break
        fi
      done < <(${pkgs.tmux}/bin/tmux list-panes -a \
        -F '#{session_name}:#{window_index}.#{pane_index}	#{pane_current_command}	#{pane_current_path}' 2>/dev/null \
        | ${pkgs.gnugrep}/bin/grep -i opencode)
    fi

    if [ -z "$target" ]; then
      ${pkgs.tmux}/bin/tmux display-message "OC: notification pane not found"
      exit 0
    fi

    # Map event type to human-readable label
    case "$event" in
      complete)    event_label="completed" ;;
      error)       event_label="error" ;;
      permission)  event_label="needs permission" ;;
      question)    event_label="has a question" ;;
      plan_exit)   event_label="plan exit" ;;
      *)           event_label="$event" ;;
    esac

    # Switch to the target pane
    sess="''${target%%:*}"
    winpane="''${target#*:}"
    win="''${winpane%%.*}"
    ${pkgs.tmux}/bin/tmux switch-client -t "$sess"
    ${pkgs.tmux}/bin/tmux select-window -t "$sess:$win"
    ${pkgs.tmux}/bin/tmux select-pane -t "$sess:$winpane"
    ${pkgs.tmux}/bin/tmux display-message "OC: $event_label"
  '';
in
{
  home.packages = [
    tmux-oc-notification-picker
    tmux-oc-notification-list
    tmux-oc-dismiss-notification
    tmux-oc-clear-notifications
  ];
}
