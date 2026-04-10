{ pkgs, ... }:
let
  tmux-metadata-preview = pkgs.writeShellScriptBin "tmux-metadata-preview" ''
    # Usage:
    #   tmux-metadata-preview <target>
    #
    # Target can be:
    #   - A session name (e.g. "main") -> shows session overview with all windows/panes
    #   - A session:window target (e.g. "main:0") -> shows window detail with all panes

    target="$1"
    if [ -z "$target" ]; then
      echo "No target specified"
      exit 1
    fi

    # --- ANSI color codes ---
    bold=$'\033[1m'
    dim=$'\033[2m'
    reset=$'\033[0m'
    cyan=$'\033[36m'
    green=$'\033[32m'
    yellow=$'\033[33m'
    magenta=$'\033[35m'
    blue=$'\033[34m'
    white=$'\033[37m'

    # --- Helpers ---
    hr() {
      local cols="''${FZF_PREVIEW_COLUMNS:-80}"
      printf '%s' "$dim"
      printf '%.0s─' $(seq 1 "$cols")
      printf '%s\n' "$reset"
    }

    label_value() {
      local label="$1"
      local value="$2"
      local color="''${3:-$white}"
      printf '%s%-10s %s%s%s\n' "$dim" "$label" "$color" "$value" "$reset"
    }

    # Determine if target is a session or a window
    if [[ "$target" == *:* ]]; then
      mode="window"
      session_name="''${target%%:*}"
      window_idx="''${target#*:}"
    else
      mode="session"
      session_name="$target"
    fi

    tmux="${pkgs.tmux}/bin/tmux"

    if [ "$mode" = "session" ]; then
      # ── Session overview ──
      # Get session metadata
      session_info=$($tmux display-message -t "$session_name" -p \
        '#{session_windows}	#{session_attached}	#{session_created}	#{session_group}' 2>/dev/null)

      if [ -z "$session_info" ]; then
        echo "Session not found: $session_name"
        exit 1
      fi

      IFS=$'\t' read -r win_count attached created group <<< "$session_info"

      if [ "$attached" = "1" ]; then
        attach_str="''${green}attached''${reset}"
      else
        attach_str="''${dim}detached''${reset}"
      fi

      # Format creation time
      if command -v ${pkgs.coreutils}/bin/date &>/dev/null; then
        created_str=$(${pkgs.coreutils}/bin/date -d "@$created" '+%Y-%m-%d %H:%M' 2>/dev/null \
          || ${pkgs.coreutils}/bin/date -r "$created" '+%Y-%m-%d %H:%M' 2>/dev/null \
          || echo "unknown")
      else
        created_str="unknown"
      fi

      if [ "$win_count" = "1" ]; then
        win_label="1 window"
      else
        win_label="$win_count windows"
      fi

      echo ""
      printf '  %s%s %s%s\n' "$bold" "$session_name" "$attach_str" "$reset"
      hr
      label_value "Windows:" "$win_label" "$cyan"
      label_value "Created:" "$created_str" "$white"
      if [ -n "$group" ]; then
        label_value "Group:" "$group" "$magenta"
      fi
      echo ""

      # List all windows in this session with their panes
      while IFS=$'\t' read -r widx wname wpanes wactive wlayout; do
        if [ "$wactive" = "1" ]; then
          marker="''${green}● ''${reset}"
        else
          marker="  "
        fi

        if [ "$wpanes" = "1" ]; then
          pane_label="1 pane"
        else
          pane_label="$wpanes panes"
        fi

        printf '  %s%s%s:%s %s%s  %s%s%s\n' \
          "$marker" "$bold" "$session_name" "$widx" "$wname" "$reset" \
          "$dim" "$pane_label" "$reset"

        # List panes within this window
        while IFS=$'\t' read -r pidx pactive pcmd ppath ppid; do
          if [ "$pactive" = "1" ]; then
            pmarker="''${green}▸''${reset}"
          else
            pmarker="''${dim}▹''${reset}"
          fi

          # Shorten the path
          short_path="''${ppath/#$HOME/~}"

          printf '    %s %s%s%s  %s%s%s\n' \
            "$pmarker" \
            "$cyan" "$pcmd" "$reset" \
            "$dim" "$short_path" "$reset"
        done < <($tmux list-panes -t "$session_name:$widx" \
          -F '#{pane_index}	#{pane_active}	#{pane_current_command}	#{pane_current_path}	#{pane_pid}' 2>/dev/null)

        echo ""
      done < <($tmux list-windows -t "$session_name" \
        -F '#{window_index}	#{window_name}	#{window_panes}	#{window_active}	#{window_layout}' 2>/dev/null)

    else
      # ── Window detail ──
      win_info=$($tmux display-message -t "$target" -p \
        '#{window_name}	#{window_panes}	#{window_active}	#{window_layout}' 2>/dev/null)

      if [ -z "$win_info" ]; then
        echo "Window not found: $target"
        exit 1
      fi

      IFS=$'\t' read -r wname wpanes wactive wlayout <<< "$win_info"

      if [ "$wactive" = "1" ]; then
        active_str="''${green}active''${reset}"
      else
        active_str="''${dim}inactive''${reset}"
      fi

      if [ "$wpanes" = "1" ]; then
        pane_label="1 pane"
      else
        pane_label="$wpanes panes"
      fi

      # Simplify layout string to a human-readable description
      layout_type=""
      case "$wlayout" in
        *even-horizontal*) layout_type="horizontal split" ;;
        *even-vertical*) layout_type="vertical split" ;;
        *main-horizontal*) layout_type="main-horizontal" ;;
        *main-vertical*) layout_type="main-vertical" ;;
        *tiled*) layout_type="tiled" ;;
        *) layout_type="" ;;
      esac

      echo ""
      printf '  %s%s:%s %s%s  %s\n' "$bold" "$session_name" "$window_idx" "$wname" "$reset" "$active_str"
      hr
      label_value "Panes:" "$pane_label" "$cyan"
      if [ -n "$layout_type" ]; then
        label_value "Layout:" "$layout_type" "$magenta"
      fi
      echo ""

      # List all panes in this window
      printf '  %s%s%s\n' "$bold" "Panes" "$reset"
      echo ""

      while IFS=$'\t' read -r pidx pactive pcmd ppath ppid pwidth pheight; do
        if [ "$pactive" = "1" ]; then
          pmarker="''${green}▸''${reset}"
          pstyle="$bold"
        else
          pmarker="''${dim}▹''${reset}"
          pstyle=""
        fi

        # Shorten the path
        short_path="''${ppath/#$HOME/~}"

        printf '  %s %s%s#%s%s  %s%dx%d%s\n' \
          "$pmarker" \
          "$pstyle" "pane" "$pidx" "$reset" \
          "$dim" "$pwidth" "$pheight" "$reset"
        printf '    %s%-10s%s%s%s\n' "$dim" "Command:" "$reset$cyan" "$pcmd" "$reset"
        printf '    %s%-10s%s%s%s\n' "$dim" "Path:" "$reset" "$short_path" "$reset"
        printf '    %s%-10s%s%s%s\n' "$dim" "PID:" "$reset$dim" "$ppid" "$reset"
        echo ""

      done < <($tmux list-panes -t "$target" \
        -F '#{pane_index}	#{pane_active}	#{pane_current_command}	#{pane_current_path}	#{pane_pid}	#{pane_width}	#{pane_height}' 2>/dev/null)
    fi
  '';
in
{
  home.packages = [ tmux-metadata-preview ];
}
