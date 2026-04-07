{ pkgs, ... }:
let
  tmux-oc-jump-notification = pkgs.writeShellScriptBin "tmux-oc-jump-notification" ''
    notification_file="$HOME/.cache/opencode/tmux-notifications.json"

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
    max_age_secs=300  # 5 minutes
    cutoff=$(( (now - max_age_secs) * 1000 ))  # convert to milliseconds

    # Find the last entry within the cutoff in a single jq call
    IFS=$'\t' read -r target_idx target_worktree < <(
      printf '%s' "$queue" | ${pkgs.jq}/bin/jq -r --argjson cutoff "$cutoff" '
        [to_entries[] | select(.value.timestamp >= $cutoff)] |
        if length == 0 then "-1\t"
        else last | [(.key | tostring), .value.worktree] | join("\t")
        end
      '
    )
    target_idx=''${target_idx:--1}

    if [ "$target_idx" -eq -1 ] || [ -z "$target_worktree" ]; then
      ${pkgs.tmux}/bin/tmux display-message "No recent notifications"
      exit 0
    fi

    # Find the tmux session whose pane_current_path matches the worktree
    target_session=""
    while IFS= read -r sess; do
      pane_path=$(${pkgs.tmux}/bin/tmux display-message -t "$sess" -p '#{pane_current_path}' 2>/dev/null)
      if [ "$pane_path" = "$target_worktree" ]; then
        target_session="$sess"
        break
      fi
    done < <(${pkgs.tmux}/bin/tmux list-sessions -F '#{session_name}' 2>/dev/null)

    if [ -z "$target_session" ]; then
      ${pkgs.tmux}/bin/tmux display-message "Notification session not found"
      exit 0
    fi

    # Switch to the target session
    ${pkgs.tmux}/bin/tmux switch-client -t "$target_session"

    # Remove the consumed entry from the queue (atomic write)
    updated=$(printf '%s' "$queue" | ${pkgs.jq}/bin/jq "del(.[$target_idx])")
    tmp_file="$(${pkgs.coreutils}/bin/mktemp "$notification_file.XXXXXX")"
    printf '%s' "$updated" > "$tmp_file" && ${pkgs.coreutils}/bin/mv "$tmp_file" "$notification_file"
  '';
in
{
  home.packages = [ tmux-oc-jump-notification ];
}
