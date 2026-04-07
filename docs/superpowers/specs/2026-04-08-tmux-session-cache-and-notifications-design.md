# tmux session cache and notification jump

## problem

The current tmux session preview (`prefix + a`) calls `opencode db` synchronously for each fzf preview, spawning a new process (~100-200ms) on every cursor move. This causes noticeable lag. Additionally, there is no way to quickly jump to a tmux session where OpenCode needs attention (permission, error, question, completion).

## solution

A custom OpenCode plugin that writes session summary data to JSON cache files on events, plus a notification queue for attention-needed events. The preview script reads the cache instead of querying `opencode db`. A new keybinding (`prefix + A`) jumps to the most recent notification.

## plugin

### overview

A TypeScript OpenCode plugin at `home-manager/ai-coding/plugins/tmux-session-cache/src/index.ts`, built with bun and packaged as a nix derivation. The plugin hooks into OpenCode events and writes two types of files:

1. Per-worktree session cache (for fast preview)
2. Global notification queue (for jump-to-notification)

The plugin does NOT handle sound or desktop notifications -- that remains the notifier plugin's job.

### events

The plugin listens to:

- **`session.idle`** -- session completed. Write cache, queue notification (complete).
- **`session.error`** -- error or user cancellation. Write cache, queue notification (error).
- **`permission.asked`** -- blocked on permission. Queue notification (permission).
- **`session.updated`** -- title or summary changed. Refresh the per-worktree cache.
- **`tool.execute.before`** -- for `question` and `plan_exit` tools. Queue notification.

### data fetching

On each event, the plugin uses the SDK client (`client.session.get()`, `client.session.messages()`) to fetch session details: title, model, provider, token counts, cost, code change summary, and last updated time. This is in-process and fast since the plugin runs inside OpenCode.

### plugin context

The plugin receives `{ client, directory, worktree }` from the plugin API. The `worktree` value identifies which project the cache belongs to. The `client` provides SDK access for fetching session data.

## cache files

### per-worktree cache

**Location**: `~/.cache/opencode/tmux-cache/<worktree-hash>.json`

The worktree path is hashed (hex-encoded SHA-256 or similar) to produce a safe filename. The plugin overwrites this file on each relevant event, so it always reflects the most recent active session for that worktree.

**Format**:

```json
{
  "worktree": "/Users/sam/code/github.com/foo/main",
  "sessionId": "abc123",
  "title": "feat(tmux): add opencode session preview",
  "model": "claude-opus-4-20250514",
  "provider": "anthropic",
  "tokensIn": 45230,
  "tokensOut": 12840,
  "cost": 1.23,
  "additions": 128,
  "deletions": 2,
  "files": 4,
  "updatedAt": 1744123456000
}
```

### notification queue

**Location**: `~/.cache/opencode/tmux-notifications.json`

An array of recent attention-needed events. Newest entries are appended to the end. The queue is pruned to the last 50 entries on each write to prevent unbounded growth.

**Format**:

```json
[
  {
    "worktree": "/Users/sam/code/github.com/foo/main",
    "event": "complete",
    "sessionId": "abc123",
    "title": "feat(tmux): add opencode session preview",
    "timestamp": 1744123456000
  }
]
```

Events that produce notifications: `complete`, `error`, `permission`, `question`, `plan_exit`.

### concurrency

Multiple OpenCode instances (one per worktree) may write simultaneously. Per-worktree cache files have no contention since each instance writes to a different hash. The notification queue file is shared -- the plugin should read-modify-write with a simple strategy (read, parse, append, prune, write). Brief races may lose an entry, which is acceptable for this use case.

## scripts

### tmux-session-preview (modified)

The existing preview script is rewritten to read cache files instead of calling `opencode db`:

1. Get the tmux session's `pane_current_path`
2. Hash the path to derive the cache filename
3. Read `~/.cache/opencode/tmux-cache/<hash>.json`
4. If the file exists, format and display the summary (same output format as today: title, model, tokens, cost, changes, relative time)
5. If the file does not exist, fall back to `tmux capture-pane` (same as today)

The hashing algorithm must match between the plugin and the preview script. The plugin uses Node's `crypto.createHash('sha256')`, and the preview script uses `sha256sum` (coreutils).

### tmux-oc-jump-notification (new)

Bound to `prefix + A` via `run-shell` (not a popup -- it's a direct switch, no interactive UI).

1. Read `~/.cache/opencode/tmux-notifications.json`
2. Iterate from the end to find the most recent entry
3. Check if `timestamp` is within the last 5 minutes (300 seconds). If older, do nothing.
4. If no valid entry, show a brief tmux message ("no recent notifications") and exit
5. If valid, iterate all tmux sessions to find one whose `pane_current_path` matches the entry's `worktree`
6. Switch to that session
7. Remove the consumed entry from the queue file (rewrite without it)

### tmux-oc-session-picker (unchanged)

No changes needed. Still uses fzf with the preview script.

## nix integration

### package layer

- `packages/tmux-session-cache-plugin.nix` -- builds the TypeScript plugin with bun. Since the plugin likely has no npm dependencies (uses Node built-ins: `fs`, `path`, `crypto`), a single derivation may suffice. If deps are needed, follow the two-derivation FOD pattern from `opencode-notifier`.
- Registered in `overlays/default.nix` as `tmux-session-cache-plugin`.

### plugin wiring

In `home-manager/ai-coding/default.nix`, add to the `plugins` list:

```nix
"${pkgs.tmux-session-cache-plugin}/dist/index.js"
```

### script wiring

- `home-manager/scripts/tmux-session-preview.nix` -- rewritten to read JSON cache
- `home-manager/scripts/tmux-oc-jump-notification.nix` -- new script
- `home-manager/scripts/default.nix` -- add import for the new script

### keybinding

In `home-manager/cli/tmux.nix`:

```
bind A run-shell "tmux-oc-jump-notification"
```

## dependencies

The preview script needs: `jq`, `coreutils` (for `sha256sum`, `date`), `tmux`.

The jump script needs: `jq`, `coreutils`, `tmux`.

The plugin has no runtime dependencies beyond Node built-ins.

## hash consistency

Both the plugin (TypeScript) and the shell scripts must produce the same hash for a given worktree path. The canonical approach:

- **Plugin**: `crypto.createHash('sha256').update(worktree).digest('hex')`
- **Shell**: `printf '%s' "$dir" | sha256sum | cut -d' ' -f1`

Both produce the same lowercase hex SHA-256 digest.
