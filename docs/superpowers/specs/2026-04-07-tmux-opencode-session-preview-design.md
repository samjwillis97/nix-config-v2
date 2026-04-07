# OpenCode-Aware tmux Session Preview

**Date:** 2026-04-07
**Status:** Draft
**Approach:** fzf in tmux popup with `opencode db` preview

## Problem

When using `prefix + s` to switch tmux sessions, the built-in `choose-tree` shows a list of sessions with a pane content preview. There's no way to see at a glance whether a session has an active opencode conversation, what it's working on, or how much it has consumed. You have to switch into each session to check.

## Goals

- Replace `prefix + s` with a session picker that shows opencode session summaries
- Show core metrics: session title, model, token usage, cost, code changes, last update time
- Fall back gracefully for sessions without opencode data (show normal pane content)
- Fit naturally into the existing nix config patterns (`writeShellScriptBin`, home-manager)

## Non-Goals

- Real-time streaming of opencode output into the preview
- Modifying the tmux statusbar or session list annotations
- Managing opencode sessions (create, delete, export) from the picker
- Supporting multiple opencode sessions per tmux session (shows the most recent one)

## Architecture

### Overview

Two new shell scripts packaged via `writeShellScriptBin`, invoked from a modified `prefix + s` keybinding that opens a `tmux display-popup` running fzf.

```
prefix + s
  -> tmux display-popup (80% x 80% centered)
    -> tmux-oc-session-picker (fzf with preview)
      -> tmux-session-preview (per-session, runs in fzf preview pane)
        -> opencode db (query for session data)
        OR
        -> tmux capture-pane (fallback)
```

### Component 1: Preview Script (`tmux-session-preview`)

**File:** `home-manager/scripts/tmux-session-preview.nix`
**Package name:** `tmux-session-preview`
**Runtime dependencies:** `opencode`, `jq`, `tmux`

Takes a tmux session name as `$1`. Performs these steps:

1. **Get the working directory** of the session's active pane:
   ```bash
   dir=$(tmux display-message -t "$1" -p '#{pane_current_path}')
   ```

2. **Query opencode** for the most recent session matching that directory. The directory is sanitized (single quotes escaped) before interpolation into the SQL string. All `opencode db` invocations redirect stderr to `/dev/null` to suppress one-time migration messages and other diagnostic output.

   ```bash
   safe_dir=$(printf '%s' "$dir" | sed "s/'/''/g")
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
   ```

   **Path matching strategy:** Uses `p.worktree` (the project's root directory) rather than `s.directory` (which may differ for sandbox or temporary sessions). Since tmux sessions created via `f` use worktree-based directories, `#{pane_current_path}` will match `p.worktree` in the common case.

   **Note:** `time_archived IS NULL` filters out archived sessions. The subqueries for model/provider get the values from the most recent message rather than aggregating (which would be meaningless).

3. **Check for results and format.** `opencode db --format json` returns a JSON array. An empty result is `[]` or an empty string on error. The script checks with `jq 'length > 0'`:

   ```bash
   if echo "$result" | jq -e 'length > 0' >/dev/null 2>&1; then
     # Format the summary
   ```

   Output format:
   ```
   ── OpenCode ──────────────────────────
   Title:   Implement dark mode toggle
   Model:   claude-opus-4.6 (github-copilot)
   Tokens:  12,340 in / 3,210 out
   Cost:    $0.42
   Changes: +156 / -23 across 8 files
   Updated: 5 minutes ago
   ──────────────────────────────────────
   ```

   **Relative time computation:** The `time_updated` field is a Unix epoch (seconds). The script computes the delta and formats it:
   ```bash
   now=$(date +%s)
   updated=$(echo "$result" | jq -r '.[0].time_updated')
   delta=$((now - updated))
   if [ "$delta" -lt 60 ]; then
     rel="just now"
   elif [ "$delta" -lt 3600 ]; then
     rel="$((delta / 60)) minutes ago"
   elif [ "$delta" -lt 86400 ]; then
     rel="$((delta / 3600)) hours ago"
   else
     rel="$((delta / 86400)) days ago"
   fi
   ```

4. **If no opencode session found**, fall back to pane capture:
   ```bash
   tmux capture-pane -t "$1" -p
   ```

**Assumptions:**
- `tmux display-popup` inherits the environment of the invoking pane, so `opencode` and other tools are available via `$PATH`. However, the picker script uses full nix store paths for the preview command to be safe (see Component 2).
- When a session has multiple windows/panes with different working directories, only the active pane's directory is checked. This means opencode running in a non-active pane may not be detected. This is acceptable -- the active pane is the most relevant context.

### Component 2: Session Picker Script (`tmux-oc-session-picker`)

**File:** `home-manager/scripts/tmux-oc-session-picker.nix`
**Package name:** `tmux-oc-session-picker`
**Runtime dependencies:** `tmux`, `fzf`, `tmux-session-preview` (component 1)

Lists tmux sessions and presents them in fzf with the preview script. Uses full nix store paths for the preview command to avoid `$PATH` dependency issues inside the popup:

```bash
current_session=$(tmux display-message -p '#{session_name}')

session=$(tmux list-sessions -F '#{session_name}' | \
  fzf --preview '${tmux-session-preview}/bin/tmux-session-preview {}' \
      --preview-window=right:60%:wrap \
      --header='Switch Session' \
      --no-sort \
      --border=none \
      --query="$current_session" \
      --select-1=false)

if [ -n "$session" ]; then
  tmux switch-client -t "$session"
fi
```

Design choices:
- `--preview-window=right:60%:wrap` -- preview takes 60% of the popup width on the right, wraps long lines
- `--no-sort` -- preserves the tmux session order (alphabetical by name, matching current `choose-tree -O name` behavior)
- `--border=none` -- the popup itself provides the border
- `--query="$current_session"` -- pre-fills the search with the current session name so it's highlighted/selected by default, matching `choose-tree` behavior of showing the current session
- Full nix store path (`${tmux-session-preview}/bin/tmux-session-preview`) ensures the preview script is found regardless of `$PATH` context inside the popup
- Exit without selection (Escape/Ctrl-C) simply closes the popup with no side effects

### Component 3: Keybinding Change

**File:** `home-manager/cli/tmux.nix`

Replace:
```
bind s choose-tree -sZ -O name
```

With:
```
bind s display-popup -E -w 80% -h 80% "${pkgs.tmux-oc-session-picker}/bin/tmux-oc-session-picker"
```

- `-E` -- close popup when the command exits
- `-w 80% -h 80%` -- centered popup at 80% of terminal dimensions
- Full nix store path ensures the script is always found regardless of `$PATH`

## File Changes

| File | Change |
|------|--------|
| `home-manager/scripts/tmux-session-preview.nix` | **New** -- preview script |
| `home-manager/scripts/tmux-oc-session-picker.nix` | **New** -- fzf session picker |
| `home-manager/scripts/default.nix` | Add imports for both new scripts |
| `home-manager/cli/tmux.nix` | Change `prefix + s` binding from `choose-tree` to `display-popup` |

## Dependencies

All dependencies are already present in the nix config:

- `tmux` -- the terminal multiplexer itself
- `fzf` -- fuzzy finder (used by existing sessionizer scripts)
- `jq` -- JSON processing (available via home-manager packages)
- `opencode` -- AI coding tool (installed via home-manager)

No new packages, flake inputs, or overlays needed.

## Error Handling

- **opencode not installed / not in PATH:** The preview script checks if `opencode` is available (`command -v opencode`). If not, falls back to pane capture silently.
- **opencode db query fails:** If the query returns an error (e.g., database locked, missing tables), or if `jq` fails to parse the output, the script falls back to pane capture. All `opencode db` stderr is redirected to `/dev/null` to suppress migration messages and diagnostics.
- **No tmux sessions:** If `tmux list-sessions` returns nothing, fzf shows an empty list. The popup closes on Escape.
- **Session disappears during preview:** If a session is killed while highlighted in fzf, `tmux display-message` and `capture-pane` will fail. The preview shows nothing (acceptable -- the session is gone).
- **jq parse failure:** If the `opencode db` output format changes or returns malformed JSON, the `jq -e 'length > 0'` check fails and the script falls back to pane capture.

## Performance

- `opencode db` invocation: ~100-200ms (Go binary startup + SQLite query). Acceptable per the user's stated tolerance for small delays.
- `tmux capture-pane` fallback: <10ms.
- fzf preview runs asynchronously -- the list remains responsive while the preview loads.

## Future Enhancements

These are explicitly out of scope for v1 but noted for potential follow-up:

- **Session list annotations:** Add an opencode indicator (icon/label) in the fzf list itself, not just the preview, so you can see which sessions have opencode data without selecting them.
- **Last exchange preview:** Show the last user prompt and assistant response snippet in the preview.
- **Todo items:** Show active todo items from the opencode session.
- **Direct sqlite3 optimization:** If `opencode db` startup latency becomes annoying, switch to direct `sqlite3` queries for faster response.
- **Multiple sessions:** Show a list of recent opencode sessions for a directory, not just the most recent one.
