# Tmux Session MRU Tracking

## Problem

`tmux-session-picker` lists sessions alphabetically. With many sessions open, finding the one you were just working in requires scanning the whole list. There is no tracking of when a session was last visited.

## Solution

Track when each session was last used (switched away from), sort the picker by most-recently-used, and show the last-accessed time in the preview.

## Design Decisions

- **"Used" = switched away from**: The `client-session-changed` tmux hook fires on session switch. We record the session being *left*, giving a "this session was active until X" semantic.
- **File-per-session storage**: One file per session at `~/.cache/tmux-session-history/<session_name>`, containing a single epoch timestamp. Matches existing patterns in this repo (OpenCode cache uses file-per-entity under `~/.cache/`). Atomic writes, no locking needed.
- **Relative time display**: "5 min ago", "2 hours ago", "3 days ago" in the preview. Concise and immediately meaningful.
- **No-history sessions at the bottom**: Newly created sessions that have never been switched away from appear after all MRU-tracked sessions, sorted alphabetically among themselves.

## Components

### 1. `tmux-session-track` (new script)

A small script added to `tmux-session-picker.nix`. Takes a session name as argument, writes the current epoch to the tracking file.

```bash
# tmux-session-track <session_name>
cache_dir="$HOME/.cache/tmux-session-history"
mkdir -p "$cache_dir"
printf '%s' "$(date +%s)" > "$cache_dir/$1"
```

Exported as a `home.packages` entry alongside `tmux-session-picker` and `tmux-session-list`.

### 2. Tmux hook (in `tmux.nix`)

```
set-hook -g client-session-changed 'run-shell "tmux-session-track \"#{hook_session_name}\""'
```

`#{hook_session_name}` resolves to the session that was just left. The hook fires globally on every session switch.

### 3. Modified `tmux-session-list`

Current behavior: lists sessions sorted alphabetically by name.

New behavior:
1. For each session, read `~/.cache/tmux-session-history/<name>` if it exists.
2. Emit sessions in two groups:
   - **Group 1 (has history)**: Sorted by timestamp descending (most recent first).
   - **Group 2 (no history)**: Sorted alphabetically.
3. Opportunistic cleanup: remove tracking files for session names that no longer exist in `tmux list-sessions`.

The output format stays the same (`label\tname`) so the picker doesn't need to change its parsing.

### 4. Modified `tmux-metadata-preview`

In session mode, add a "Last used:" line after "Created:":
- If tracking file exists: show relative time (e.g., "5 min ago").
- If not: show "--".

Relative time helper function (in the same script):

```bash
relative_time() {
  local ts="$1"
  local now
  now=$(date +%s)
  local delta=$(( now - ts ))
  if [ "$delta" -lt 60 ]; then
    echo "just now"
  elif [ "$delta" -lt 3600 ]; then
    echo "$(( delta / 60 )) min ago"
  elif [ "$delta" -lt 86400 ]; then
    echo "$(( delta / 3600 )) hours ago"
  else
    echo "$(( delta / 86400 )) days ago"
  fi
}
```

### 5. Kill-session cleanup

The existing `ctrl-x` binding in `tmux-session-picker` kills a session and reloads the list. Extend the `execute-silent` command to also remove the tracking file:

```
ctrl-x:execute-silent(tmux kill-session -t '{2}' && rm -f ~/.cache/tmux-session-history/'{2}')+reload(tmux-session-list)
```

## Files Changed

| File | Change |
|------|--------|
| `home-manager/scripts/tmux-session-picker.nix` | Add `tmux-session-track` script; modify `tmux-session-list` to sort by MRU; update ctrl-x to clean up tracking file |
| `home-manager/scripts/tmux-metadata-preview.nix` | Add "Last used:" line with relative time to session preview |
| `home-manager/cli/tmux.nix` | Add `client-session-changed` hook |

## Files Not Changed

- `tmux-window-picker.nix` -- unrelated scope
- OpenCode-specific pickers (`tmux-oc-session-picker.nix`, etc.) -- separate system
- fzf keybindings (ctrl-r rename, enter switch) -- unchanged behavior

## Edge Cases

- **Session renamed**: The tracking file uses the session name. If a session is renamed via ctrl-r, the old tracking file becomes orphan (cleaned up on next `tmux-session-list` run) and the renamed session starts with no history. This is acceptable -- rename is rare and the session will get a fresh timestamp on next switch-away.
- **Multiple tmux clients**: The hook fires per-client, so the most recent switch from any client wins. This is correct behavior.
- **Rapid switching**: Each switch overwrites the file. No accumulation of stale data.
