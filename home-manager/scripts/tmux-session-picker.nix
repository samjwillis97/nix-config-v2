{ pkgs, ... }:
let
  # MRU tracking cache directory. Also referenced in tmux-metadata-preview.nix.
  cache_dir = "$HOME/.cache/tmux-session-history";

  # Encode a session name for use as a flat filename.
  # Replaces % with %25 first, then / with %2F, so names like
  # "samjwillis97/nix-config-v2/main" become safe filenames.
  # Pure bash -- no subprocess spawns.
  # Must be kept in sync across tmux-session-track, tmux-session-list,
  # tmux-metadata-preview, and the ctrl-x kill binding.
  encode_name = ''
    encode_session_name() {
      local name="$1"
      name="''${name//%/%25}"
      name="''${name//\//%2F}"
      printf '%s' "$name"
    }
  '';

  # Small script called by the tmux client-session-changed hook.
  # Records the epoch timestamp for the session that was just left.
  tmux-session-track = pkgs.writeShellScriptBin "tmux-session-track" ''
    ${encode_name}

    session_name="$1"
    if [ -z "$session_name" ]; then
      exit 0
    fi

    cache_dir="${cache_dir}"
    ${pkgs.coreutils}/bin/mkdir -p "$cache_dir"
    encoded=$(encode_session_name "$session_name")
    printf '%s' "$(${pkgs.coreutils}/bin/date +%s)" > "$cache_dir/$encoded"
  '';

  # Called by the session-closed hook to remove the tracking file for a destroyed session.
  tmux-session-track-clean = pkgs.writeShellScriptBin "tmux-session-track-clean" ''
    ${encode_name}

    session_name="$1"
    if [ -z "$session_name" ]; then
      exit 0
    fi

    cache_dir="${cache_dir}"
    encoded=$(encode_session_name "$session_name")
    rm -f "$cache_dir/$encoded"
  '';

  # Helper script to generate session list for fzf (used for initial load and reload)
  # Outputs sessions sorted by most-recently-used (sessions without history at the bottom).
  tmux-session-list = pkgs.writeShellScriptBin "tmux-session-list" ''
    ${encode_name}

    current_session=$(${pkgs.tmux}/bin/tmux display-message -p '#{session_name}' 2>/dev/null)
    cache_dir="${cache_dir}"

    # Two arrays: sessions with MRU history and sessions without
    mru_entries=()
    no_history_entries=()

    while IFS=$'\t' read -r name windows attached; do
      # Skip the current session
      if [ "$name" = "$current_session" ]; then
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

      # Check for MRU tracking file
      encoded=$(encode_session_name "$name")
      if [ -f "$cache_dir/$encoded" ]; then
        ts=$(< "$cache_dir/$encoded")
        if [ -n "$ts" ]; then
          mru_entries+=("$ts"$'\t'"$label"$'\t'"$name")
        else
          no_history_entries+=("$label"$'\t'"$name")
        fi
      else
        no_history_entries+=("$label"$'\t'"$name")
      fi
    done < <(${pkgs.tmux}/bin/tmux list-sessions \
      -F '#{session_name}	#{session_windows}	#{session_attached}' 2>/dev/null)

    # Output MRU sessions sorted by timestamp descending (most recent first)
    if [ ''${#mru_entries[@]} -gt 0 ]; then
      printf '%s\n' "''${mru_entries[@]}" \
        | ${pkgs.coreutils}/bin/sort -t$'\t' -k1,1 -rn \
        | ${pkgs.coreutils}/bin/cut -f2-
    fi

    # Output no-history sessions sorted alphabetically
    if [ ''${#no_history_entries[@]} -gt 0 ]; then
      printf '%s\n' "''${no_history_entries[@]}" \
        | ${pkgs.coreutils}/bin/sort -t$'\t' -k1,1
    fi
  '';

  tmux-session-picker = pkgs.writeShellScriptBin "tmux-session-picker" ''
    session_list=$(tmux-session-list)

    if [ -z "$session_list" ]; then
      ${pkgs.tmux}/bin/tmux display-message "No other sessions"
      exit 0
    fi

    # ctrl-x: kill session, remove tracking file, and reload list (stays in fzf)
    # ctrl-r: rename session (exits fzf via --expect, then uses tmux command-prompt)
    # enter: switch to session
    selected=$(printf '%s\n' "$session_list" | \
      ${pkgs.fzf}/bin/fzf \
        --ansi \
        --with-nth=1 \
        --delimiter=$'\t' \
        --preview 'tmux-metadata-preview {2}' \
        --preview-window=right:60% \
        --header=$'enter: switch | ctrl-x: kill | ctrl-r: rename' \
        --expect='ctrl-r' \
        --bind="ctrl-x:execute-silent(${pkgs.tmux}/bin/tmux kill-session -t '{2}')+reload(tmux-session-list)" \
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

    if [ "$key" = "ctrl-r" ]; then
      # Rename: use tmux command-prompt with the current name pre-filled
      ${pkgs.tmux}/bin/tmux command-prompt -I "$target" -p "Rename session:" \
        "rename-session -t '$target' '%%'"
      exit 0
    fi

    # Default (enter): switch to session
    ${pkgs.tmux}/bin/tmux switch-client -t "$target"
  '';
in
{
  home.packages = [ tmux-session-picker tmux-session-list tmux-session-track tmux-session-track-clean ];
}
