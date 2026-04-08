# Tmux OpenCode Notification Picker

**Date:** 2026-04-08
**Status:** Draft

## Problem

The current tmux notification system for OpenCode only supports one-at-a-time consumption via `prefix+A`, which jumps to the most recent notification and dismisses it. There is no way to:
- Browse all pending notifications and choose which one to act on
- Dismiss a notification without switching to its pane
- Clear all notifications at once

## Solution

Replace the `tmux-oc-jump-notification` script with a new `tmux-oc-notification-picker` script that opens an fzf popup showing all pending notifications with actions to jump, dismiss, or clear all.

## Design

### Display Format

Each notification appears as a single fzf line:

```
[complete]    nix-config-v2   "Add dark mode toggle"    3m ago
[permission]  my-app          ""                         1m ago
[error]       api-service     "Fix auth bug"             8m ago
```

Fields: `[event_type]  worktree_basename  "title"  relative_time`

- Sorted most-recent-first
- Only notifications within the 15-minute window are shown (consistent with existing `max_age_secs=900`)
- Title may be empty (e.g., for `permission`, `question`, `plan_exit` events)

### fzf Actions

| Key       | Action         | Description                                              |
|-----------|----------------|----------------------------------------------------------|
| Enter     | Jump & dismiss | Switch to the notification's pane and remove from queue  |
| Ctrl-D    | Dismiss        | Remove from queue without switching panes                |
| Ctrl-X    | Clear all      | Remove all notifications from queue and close popup      |

The fzf header displays available keybindings.

### Pane Resolution (for Jump action)

Uses the same two-strategy approach as the existing jump script:

1. **PID mapping**: Look up `~/.cache/opencode/tmux-cache/pids/<pane_pid>.json` to find a matching `currentSessionId`, then resolve to a tmux pane via `tmux list-panes -a`.
2. **Worktree fallback**: Search all opencode panes for one whose `pane_current_path` matches the notification's `worktree` field.

### Atomic Queue Updates

Same pattern as existing code:
- Re-read `tmux-notifications.json` before modifying (minimizes race condition window)
- Write to a temp file via `mktemp`, then `mv` atomically into place

### Edge Cases

| Case                        | Behavior                                                    |
|-----------------------------|-------------------------------------------------------------|
| No notification file        | `tmux display-message "No pending notifications"`, no popup |
| Empty/expired queue         | `tmux display-message "No pending notifications"`, no popup |
| Pane not found on jump      | `tmux display-message "Notification pane not found"`, notification is still dismissed |
| User presses Escape/Ctrl-C  | fzf closes, no changes to queue                             |

### Keybinding

`prefix+A` opens the notification picker as a popup (same pattern as the session picker `prefix+a`):

```
bind A display-popup -E -w 80% -h 80% "tmux-oc-notification-picker"
```

This replaces the current `bind A run-shell "tmux-oc-jump-notification"`.

## Files Changed

| File                                              | Change  | Description                                              |
|---------------------------------------------------|---------|----------------------------------------------------------|
| `home-manager/scripts/tmux-oc-notification-picker.nix` | New     | The fzf notification manager script                      |
| `home-manager/scripts/tmux-oc-jump-notification.nix`   | Delete  | Replaced by the picker                                   |
| `home-manager/scripts/default.nix`                     | Modify  | Replace `tmux-oc-jump-notification` import with `tmux-oc-notification-picker` |
| `home-manager/cli/tmux.nix`                            | Modify  | Change `bind A` to use `display-popup -E` with new script |

`tmux-oc-notification-status.nix` is unchanged — the status bar badge continues to work as-is.

## Implementation Notes

### Script Structure

The `tmux-oc-notification-picker` script:

1. Read `~/.cache/opencode/tmux-notifications.json`
2. Filter to entries within the 15-minute window
3. If none found, display tmux message and exit
4. Format each entry as a display line with metadata encoded in hidden tab-separated fields (event, sessionId, worktree, timestamp — passed via fzf's `--with-nth` to show only the display columns)
5. Pipe to fzf with keybinding actions
6. On Enter: resolve pane, switch to it, dismiss the notification
7. On Ctrl-D: dismiss the notification without switching
8. On Ctrl-X: truncate the queue file to `[]` and exit

### Relative Time Calculation

Compute relative time in the shell script:
- `< 60s` → `"Xs ago"` or `"just now"`
- `60s - 3599s` → `"Xm ago"`
- `>= 3600s` → `"Xh ago"` (unlikely given 15-min window, but handles edge cases)

### Dependencies

Same Nix dependencies as the existing scripts: `pkgs.jq`, `pkgs.fzf`, `pkgs.tmux`, `pkgs.coreutils`, `pkgs.gnugrep`.
