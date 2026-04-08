{ pkgs, ... }:
let
  tmux-session-preview = pkgs.writeShellScriptBin "tmux-session-preview" ''
    target="$1"
    if [ -z "$target" ]; then
      echo "Usage: tmux-session-preview <session:win.pane | session-name>"
      exit 1
    fi

    pids_dir="$HOME/.cache/opencode/tmux-cache/pids"
    sessions_dir="$HOME/.cache/opencode/tmux-cache/sessions"

    # Get the pane PID for the target
    pane_pid=$(${pkgs.tmux}/bin/tmux display-message -t "$target" -p '#{pane_pid}' 2>/dev/null)

    # Try PID-based lookup: pane_pid -> PID mapping -> session ID -> session cache
    cache_file=""
    if [ -n "$pane_pid" ]; then
      pid_file="$pids_dir/$pane_pid.json"
      if [ -f "$pid_file" ]; then
        session_id=$(${pkgs.jq}/bin/jq -r '.currentSessionId // empty' "$pid_file" 2>/dev/null)
        if [ -n "$session_id" ]; then
          candidate="$sessions_dir/$session_id.json"
          if [ -f "$candidate" ]; then
            cache_file="$candidate"
          fi
        fi
      fi
    fi

    # Fallback: if no cache from PID mapping, scrape the pane title and
    # search session cache files by title match
    if [ -z "$cache_file" ]; then
      scraped_title=$(${pkgs.tmux}/bin/tmux capture-pane -t "$target" -p 2>/dev/null \
        | ${pkgs.gnugrep}/bin/grep -m1 '# .*[0-9].*%.*\$' \
        | ${pkgs.gnused}/bin/sed 's/.*# //' \
        | ${pkgs.gnused}/bin/sed 's/[[:space:]]\{2,\}[0-9].*//')
      if [ -n "$scraped_title" ] && [ -d "$sessions_dir" ]; then
        for sf in "$sessions_dir"/*.json; do
          [ -f "$sf" ] || continue
          sf_title=$(${pkgs.jq}/bin/jq -r '.title // empty' "$sf" 2>/dev/null)
          if [ "$sf_title" = "$scraped_title" ]; then
            cache_file="$sf"
            break
          fi
        done
      fi
    fi

    if [ -n "$cache_file" ]; then
      # Read all cached fields in a single jq invocation
      IFS=$'\t' read -r title model provider tokens_in tokens_out \
        total_cost additions deletions files time_updated_ms < <(
        ${pkgs.jq}/bin/jq -r '[
          (.title // "untitled"),
          (.model // "unknown"),
          (.provider // "unknown"),
          (.tokensIn // 0 | tostring),
          (.tokensOut // 0 | tostring),
          (.cost // 0 | tostring),
          (.additions // 0 | tostring),
          (.deletions // 0 | tostring),
          (.files // 0 | tostring),
          (.updatedAt // 0 | tostring)
        ] | join("\t")' "$cache_file" 2>/dev/null
      )

      if [ -z "$title" ]; then
        # jq failed or cache is corrupt -- fall back to pane capture
        ${pkgs.tmux}/bin/tmux capture-pane -t "$target" -p 2>/dev/null
        exit 0
      fi

      # Compute relative time (updatedAt is in milliseconds)
      now=$(${pkgs.coreutils}/bin/date +%s)
      updated_s=$((time_updated_ms / 1000))
      delta=$((now - updated_s))
      if [ "$delta" -lt 60 ]; then
        rel="just now"
      elif [ "$delta" -lt 3600 ]; then
        mins=$((delta / 60))
        if [ "$mins" -eq 1 ]; then rel="1 minute ago"; else rel="$mins minutes ago"; fi
      elif [ "$delta" -lt 86400 ]; then
        hrs=$((delta / 3600))
        if [ "$hrs" -eq 1 ]; then rel="1 hour ago"; else rel="$hrs hours ago"; fi
      else
        days=$((delta / 86400))
        if [ "$days" -eq 1 ]; then rel="1 day ago"; else rel="$days days ago"; fi
      fi

      # Format cost
      cost_formatted=$(printf '%.2f' "$total_cost" 2>/dev/null || echo "$total_cost")
      fmt_cost="\$$cost_formatted"

      # Print formatted summary
      echo "── OpenCode ──────────────────────────"
      echo "Title:   $title"
      echo "Model:   $model ($provider)"
      echo "Tokens:  $tokens_in in / $tokens_out out"
      echo "Cost:    $fmt_cost"
      echo "Changes: +$additions / -$deletions across $files files"
      echo "Updated: $rel"
      echo "──────────────────────────────────────"
    else
      # No cache found -- fall back to pane capture
      ${pkgs.tmux}/bin/tmux capture-pane -t "$target" -p 2>/dev/null
    fi
  '';
in
{
  home.packages = [ tmux-session-preview ];
}
