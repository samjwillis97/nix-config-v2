{ pkgs, ... }:
let
  tmux-oc-notification-status = pkgs.writeShellScriptBin "tmux-oc-notification-status" ''
    notification_file="$HOME/.cache/opencode/tmux-notifications.json"

    # Quick exit if no file
    if [ ! -f "$notification_file" ]; then
      exit 0
    fi

    # Count notifications within the last 15 minutes
    now=$(${pkgs.coreutils}/bin/date +%s)
    cutoff=$(( (now - 900) * 1000 ))

    count=$(${pkgs.jq}/bin/jq -r --argjson cutoff "$cutoff" \
      '[.[] | select(.timestamp >= $cutoff)] | length' \
      "$notification_file" 2>/dev/null)

    if [ -n "$count" ] && [ "$count" -gt 0 ]; then
      printf ' [%s]' "$count"
    fi
  '';
in
{
  home.packages = [ tmux-oc-notification-status ];
}
