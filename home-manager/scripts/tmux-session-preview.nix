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

    # Hash the directory to find the cache file
    dir_hash=$(printf '%s' "$dir" | ${pkgs.coreutils}/bin/sha256sum | ${pkgs.coreutils}/bin/cut -d' ' -f1)
    cache_file="$HOME/.cache/opencode/tmux-cache/$dir_hash.json"

    if [ -f "$cache_file" ]; then
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
        ${pkgs.tmux}/bin/tmux capture-pane -t "$session_name" -p 2>/dev/null
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
      # No cache file -- fall back to pane capture
      ${pkgs.tmux}/bin/tmux capture-pane -t "$session_name" -p 2>/dev/null
    fi
  '';
in
{
  home.packages = [ tmux-session-preview ];
}
