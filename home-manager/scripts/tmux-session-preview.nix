{ pkgs, ... }:
let
  tmux-session-preview = pkgs.writeShellScriptBin "tmux-session-preview" ''
    session_name="$1"
    if [ -z "$session_name" ]; then
      echo "Usage: tmux-session-preview <session-name>"
      exit 1
    fi

    # Get the working directory of the session's active pane
    dir=$(${pkgs.tmux}/bin/tmux display-message -t "$session_name" -p '#{pane_current_path}' 2>/dev/null)
    if [ -z "$dir" ]; then
      echo "Could not get pane path for session: $session_name"
      exit 0
    fi

    # Check if opencode is available
    if ! command -v opencode >/dev/null 2>&1; then
      ${pkgs.tmux}/bin/tmux capture-pane -t "$session_name" -p 2>/dev/null
      exit 0
    fi

    # Sanitize directory for SQL (double any single quotes for SQL escaping)
    safe_dir=$(printf '%s' "$dir" | ${pkgs.gnused}/bin/sed "s/'/&&/g")

    # Query opencode for the most recent session matching this directory
    # Note: $.field in SQL json_extract is safe in nix indented strings
    # because $ not followed by { is passed through literally
    result=$(opencode db \
      "SELECT s.title, s.time_updated,
        s.summary_additions, s.summary_deletions, s.summary_files,
        (SELECT json_extract(m2.data, '$.modelID')
         FROM message m2 WHERE m2.session_id = s.id
         ORDER BY m2.time_created DESC LIMIT 1) as model,
        (SELECT json_extract(m2.data, '$.providerID')
         FROM message m2 WHERE m2.session_id = s.id
         ORDER BY m2.time_created DESC LIMIT 1) as provider,
        COALESCE(SUM(json_extract(m.data, '$.tokens.input')), 0) as tokens_in,
        COALESCE(SUM(json_extract(m.data, '$.tokens.output')), 0) as tokens_out,
        COALESCE(SUM(json_extract(m.data, '$.cost')), 0) as total_cost
      FROM session s
      JOIN project p ON s.project_id = p.id
      LEFT JOIN message m ON s.id = m.session_id
      WHERE p.worktree = '$safe_dir'
        AND s.time_archived IS NULL
      GROUP BY s.id
      ORDER BY s.time_updated DESC
      LIMIT 1" --format json 2>/dev/null)

    # Check if we got results
    if echo "$result" | ${pkgs.jq}/bin/jq -e 'length > 0' >/dev/null 2>&1; then
      # Extract fields
      title=$(echo "$result" | ${pkgs.jq}/bin/jq -r '.[0].title // "untitled"')
      model=$(echo "$result" | ${pkgs.jq}/bin/jq -r '.[0].model // "unknown"')
      provider=$(echo "$result" | ${pkgs.jq}/bin/jq -r '.[0].provider // "unknown"')
      tokens_in=$(echo "$result" | ${pkgs.jq}/bin/jq -r '.[0].tokens_in // 0')
      tokens_out=$(echo "$result" | ${pkgs.jq}/bin/jq -r '.[0].tokens_out // 0')
      total_cost=$(echo "$result" | ${pkgs.jq}/bin/jq -r '.[0].total_cost // 0')
      additions=$(echo "$result" | ${pkgs.jq}/bin/jq -r '.[0].summary_additions // 0')
      deletions=$(echo "$result" | ${pkgs.jq}/bin/jq -r '.[0].summary_deletions // 0')
      files=$(echo "$result" | ${pkgs.jq}/bin/jq -r '.[0].summary_files // 0')
      time_updated_ms=$(echo "$result" | ${pkgs.jq}/bin/jq -r '.[0].time_updated // 0')

      # Compute relative time (time_updated is in milliseconds)
      now=$(date +%s)
      updated_s=$((time_updated_ms / 1000))
      delta=$((now - updated_s))
      if [ "$delta" -lt 60 ]; then
        rel="just now"
      elif [ "$delta" -lt 3600 ]; then
        rel="$((delta / 60)) minutes ago"
      elif [ "$delta" -lt 86400 ]; then
        rel="$((delta / 3600)) hours ago"
      else
        rel="$((delta / 86400)) days ago"
      fi

      # Format token numbers with commas using printf
      fmt_tokens_in=$(printf "%'d" "$tokens_in" 2>/dev/null || echo "$tokens_in")
      fmt_tokens_out=$(printf "%'d" "$tokens_out" 2>/dev/null || echo "$tokens_out")

      # Format cost (use \$ to produce literal $ in bash double-quoted string)
      fmt_cost=$(printf "\$%.2f" "$total_cost" 2>/dev/null || echo "$total_cost")

      # Print formatted summary
      echo "── OpenCode ──────────────────────────"
      echo "Title:   $title"
      echo "Model:   $model ($provider)"
      echo "Tokens:  $fmt_tokens_in in / $fmt_tokens_out out"
      echo "Cost:    $fmt_cost"
      echo "Changes: +$additions / -$deletions across $files files"
      echo "Updated: $rel"
      echo "──────────────────────────────────────"
    else
      # No opencode session found -- fall back to pane capture
      ${pkgs.tmux}/bin/tmux capture-pane -t "$session_name" -p 2>/dev/null
    fi
  '';
in
{
  home.packages = [ tmux-session-preview ];
}
