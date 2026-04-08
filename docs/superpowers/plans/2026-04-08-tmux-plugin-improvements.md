# tmux Plugin Improvements Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix bugs and add UX improvements to the tmux OpenCode notification/session plugin system.

**Architecture:** Eight changes across two files — the TypeScript OpenCode plugin (`src/index.ts`) and the shell jump script (`tmux-oc-jump-notification.nix`), plus a new status-bar indicator script and a status-bar config change in `tmux.nix`. Changes are grouped into bug fixes (race condition, temp file contention, SIGHUP), cleanup improvements (session cache pruning, notification age pruning), and UX features (status bar indicator, event type display, remaining jump count).

**Tech Stack:** TypeScript (OpenCode plugin), Bash (Nix shell scripts), Nix (tmux config)

---

### Task 1: Fix `atomicWrite` temp file contention in TypeScript plugin

**Files:**
- Modify: `home-manager/ai-coding/plugins/tmux-session-cache/src/index.ts:60-64`

The current `atomicWrite` uses a fixed `.tmp` suffix. Two concurrent OpenCode instances writing to the notification file will clobber each other's temp file. Use a unique temp path with PID and timestamp.

- [ ] **Step 1: Update `atomicWrite` to use unique temp path**

In `home-manager/ai-coding/plugins/tmux-session-cache/src/index.ts`, replace the `atomicWrite` function:

```typescript
function atomicWrite(filePath: string, data: string): void {
  const tmpPath = `${filePath}.${process.pid}.${Date.now()}.tmp`;
  writeFileSync(tmpPath, data);
  renameSync(tmpPath, filePath);
}
```

- [ ] **Step 2: Verify the plugin still compiles**

Run: `cd home-manager/ai-coding/plugins/tmux-session-cache && bun build src/index.ts --outdir dist --target node`
Expected: Build succeeds with no errors.

- [ ] **Step 3: Commit**

```
fix(tmux-plugin): use unique temp path in atomicWrite to prevent contention
```

---

### Task 2: Add age-based notification queue pruning in TypeScript plugin

**Files:**
- Modify: `home-manager/ai-coding/plugins/tmux-session-cache/src/index.ts:23-24,118-139`

Currently the notification queue is only pruned by count (max 50). Add age-based pruning — remove entries older than 24 hours whenever appending a new entry.

- [ ] **Step 1: Add `MAX_NOTIFICATION_AGE_MS` constant and age-based pruning**

In `home-manager/ai-coding/plugins/tmux-session-cache/src/index.ts`, add the constant after `UPDATE_DEBOUNCE_MS`:

```typescript
const MAX_NOTIFICATION_AGE_MS = 24 * 60 * 60 * 1000; // 24 hours
```

Then update the `appendNotification` function to prune old entries before the size cap:

```typescript
function appendNotification(entry: NotificationEntry): void {
  ensureDir(join(homedir(), ".cache", "opencode"));

  let queue: NotificationEntry[] = [];
  if (existsSync(NOTIFICATION_FILE)) {
    try {
      queue = JSON.parse(readFileSync(NOTIFICATION_FILE, "utf-8"));
      if (!Array.isArray(queue)) queue = [];
    } catch {
      queue = [];
    }
  }

  // Prune entries older than 24 hours
  const ageCutoff = Date.now() - MAX_NOTIFICATION_AGE_MS;
  queue = queue.filter((e) => e.timestamp >= ageCutoff);

  queue.push(entry);

  // Prune to last MAX_QUEUE_SIZE entries
  if (queue.length > MAX_QUEUE_SIZE) {
    queue = queue.slice(-MAX_QUEUE_SIZE);
  }

  atomicWrite(NOTIFICATION_FILE, JSON.stringify(queue, null, 2));
}
```

- [ ] **Step 2: Verify the plugin still compiles**

Run: `cd home-manager/ai-coding/plugins/tmux-session-cache && bun build src/index.ts --outdir dist --target node`
Expected: Build succeeds with no errors.

- [ ] **Step 3: Commit**

```
feat(tmux-plugin): prune notification queue entries older than 24 hours
```

---

### Task 3: Add session cache file pruning in TypeScript plugin

**Files:**
- Modify: `home-manager/ai-coding/plugins/tmux-session-cache/src/index.ts`

Session cache files at `sessions/<sessionId>.json` accumulate forever. Add a `pruneStaleSessionFiles()` function that removes files older than 7 days, called on plugin startup alongside `pruneStalePidFiles()`.

- [ ] **Step 1: Add `statSync` to imports**

In the import block at the top of `src/index.ts`, add `statSync` to the `fs` import:

```typescript
import {
  writeFileSync,
  readFileSync,
  mkdirSync,
  existsSync,
  renameSync,
  unlinkSync,
  readdirSync,
  statSync,
} from "fs";
```

- [ ] **Step 2: Add `MAX_SESSION_CACHE_AGE_MS` constant**

Add after `MAX_NOTIFICATION_AGE_MS`:

```typescript
const MAX_SESSION_CACHE_AGE_MS = 7 * 24 * 60 * 60 * 1000; // 7 days
```

- [ ] **Step 3: Add `pruneStaleSessionFiles` function**

Add after `pruneStalePidFiles()` function (after line 116):

```typescript
function pruneStaleSessionFiles(): void {
  try {
    if (!existsSync(SESSIONS_DIR)) return;
    const now = Date.now();
    const files = readdirSync(SESSIONS_DIR);
    for (const file of files) {
      if (!file.endsWith(".json")) continue;
      try {
        const filePath = join(SESSIONS_DIR, file);
        const stat = statSync(filePath);
        if (now - stat.mtimeMs > MAX_SESSION_CACHE_AGE_MS) {
          unlinkSync(filePath);
        }
      } catch {
        // Best effort
      }
    }
  } catch {
    // Best effort cleanup
  }
}
```

- [ ] **Step 4: Call `pruneStaleSessionFiles` on plugin startup**

In the plugin body (around the line `pruneStalePidFiles();`), add a call right after:

```typescript
  // Prune stale PID files from dead processes before writing our own
  pruneStalePidFiles();

  // Prune old session cache files (>7 days)
  pruneStaleSessionFiles();
```

- [ ] **Step 5: Verify the plugin still compiles**

Run: `cd home-manager/ai-coding/plugins/tmux-session-cache && bun build src/index.ts --outdir dist --target node`
Expected: Build succeeds with no errors.

- [ ] **Step 6: Commit**

```
feat(tmux-plugin): prune session cache files older than 7 days on startup
```

---

### Task 4: Add `SIGHUP` handler in TypeScript plugin

**Files:**
- Modify: `home-manager/ai-coding/plugins/tmux-session-cache/src/index.ts:247-257`

`SIGHUP` is sent when a terminal closes but is not currently handled, leaving PID files behind.

- [ ] **Step 1: Add `SIGHUP` handler**

In `src/index.ts`, after the `SIGTERM` handler (line 257), add:

```typescript
  process.on("SIGHUP", () => {
    cleanup();
    process.exit(0);
  });
```

- [ ] **Step 2: Verify the plugin still compiles**

Run: `cd home-manager/ai-coding/plugins/tmux-session-cache && bun build src/index.ts --outdir dist --target node`
Expected: Build succeeds with no errors.

- [ ] **Step 3: Commit**

```
fix(tmux-plugin): handle SIGHUP to clean up PID files on terminal close
```

---

### Task 5: Fix race condition in jump script notification queue write

**Files:**
- Modify: `home-manager/scripts/tmux-oc-jump-notification.nix:88-91`

The jump script reads the notification queue at the start, does pane resolution + tmux switching (slow operations), then writes the updated queue back. Any notification appended between read and write is silently destroyed. Fix by re-reading the queue immediately before modifying and writing it back, minimizing the race window.

- [ ] **Step 1: Update the notification removal to re-read and use sessionId+timestamp match**

In `home-manager/scripts/tmux-oc-jump-notification.nix`, replace the notification removal block (lines 88-91) with a re-read-and-remove approach. Instead of removing by array index (which is stale since the queue may have changed), we match on `sessionId` + `timestamp` of the consumed entry. We need to capture the identifying fields earlier in the script and use them for the removal.

First, capture the event type, session ID and timestamp from the target notification. Replace the jq invocation at lines 26-33 to also extract `event` and `timestamp`:

```bash
    # Find the last entry within the cutoff, including sessionId, event, timestamp
    IFS=$'\t' read -r target_idx target_session_id target_worktree target_event target_timestamp < <(
      printf '%s' "$queue" | ${pkgs.jq}/bin/jq -r --argjson cutoff "$cutoff" '
        [to_entries[] | select(.value.timestamp >= $cutoff)] |
        if length == 0 then "-1\t\t\t\t"
        else last | [(.key | tostring), .value.sessionId, .value.worktree, .value.event, (.value.timestamp | tostring)] | join("\t")
        end
      '
    )
```

Then replace the queue removal block (lines 88-91) to re-read the file and remove by matching fields:

```bash
    # Remove the consumed entry from the queue (re-read to avoid race condition)
    fresh_queue=$(${pkgs.jq}/bin/jq -r '.' "$notification_file" 2>/dev/null)
    if [ -n "$fresh_queue" ] && [ "$fresh_queue" != "null" ]; then
      updated=$(printf '%s' "$fresh_queue" | ${pkgs.jq}/bin/jq \
        --arg sid "$target_session_id" \
        --argjson ts "$target_timestamp" \
        '[.[] | select(.sessionId == $sid and .timestamp == $ts | not)]')
      tmp_file="$(${pkgs.coreutils}/bin/mktemp "$notification_file.XXXXXX")"
      printf '%s' "$updated" > "$tmp_file" && ${pkgs.coreutils}/bin/mv "$tmp_file" "$notification_file"
    fi
```

- [ ] **Step 2: Commit**

```
fix(tmux-jump): re-read notification queue before removal to avoid race condition
```

---

### Task 6: Show event type and remaining count in jump script

**Files:**
- Modify: `home-manager/scripts/tmux-oc-jump-notification.nix`

After jumping, display a tmux message showing the event type and how many notifications remain.

- [ ] **Step 1: Add event type labels and remaining count display**

In `home-manager/scripts/tmux-oc-jump-notification.nix`, after the notification removal block (from Task 5), add a display message with the event type and remaining count. The `target_event` variable is already captured from Task 5.

Replace the three `tmux switch/select` lines and the removal block with:

```bash
    # Map event type to human-readable label
    case "$target_event" in
      complete)    event_label="completed" ;;
      error)       event_label="error" ;;
      permission)  event_label="needs permission" ;;
      question)    event_label="has a question" ;;
      plan_exit)   event_label="plan exit" ;;
      *)           event_label="$target_event" ;;
    esac

    # Switch to the target pane
    sess="''${target%%:*}"
    winpane="''${target#*:}"
    win="''${winpane%%.*}"
    ${pkgs.tmux}/bin/tmux switch-client -t "$sess"
    ${pkgs.tmux}/bin/tmux select-window -t "$sess:$win"
    ${pkgs.tmux}/bin/tmux select-pane -t "$sess:$winpane"

    # Remove the consumed entry from the queue (re-read to avoid race condition)
    fresh_queue=$(${pkgs.jq}/bin/jq -r '.' "$notification_file" 2>/dev/null)
    if [ -n "$fresh_queue" ] && [ "$fresh_queue" != "null" ]; then
      updated=$(printf '%s' "$fresh_queue" | ${pkgs.jq}/bin/jq \
        --arg sid "$target_session_id" \
        --argjson ts "$target_timestamp" \
        '[.[] | select(.sessionId == $sid and .timestamp == $ts | not)]')
      tmp_file="$(${pkgs.coreutils}/bin/mktemp "$notification_file.XXXXXX")"
      printf '%s' "$updated" > "$tmp_file" && ${pkgs.coreutils}/bin/mv "$tmp_file" "$notification_file"

      # Count remaining valid notifications
      remaining=$(printf '%s' "$updated" | ${pkgs.jq}/bin/jq --argjson cutoff "$cutoff" \
        '[.[] | select(.timestamp >= $cutoff)] | length')
    else
      remaining=0
    fi

    # Show event type and remaining count
    if [ "$remaining" -gt 0 ]; then
      ${pkgs.tmux}/bin/tmux display-message "OC: $event_label ($remaining more pending)"
    else
      ${pkgs.tmux}/bin/tmux display-message "OC: $event_label"
    fi
```

- [ ] **Step 2: Commit**

```
feat(tmux-jump): show event type and remaining notification count after jump
```

---

### Task 7: Create tmux status bar notification indicator script

**Files:**
- Create: `home-manager/scripts/tmux-oc-notification-status.nix`
- Modify: `home-manager/scripts/default.nix`

Create a lightweight script that reads the notification queue and outputs a badge string for the tmux status bar. Called by tmux's `status-right` on each refresh interval.

- [ ] **Step 1: Create the notification status script**

Create `home-manager/scripts/tmux-oc-notification-status.nix`:

```nix
{ pkgs, ... }:
let
  tmux-oc-notification-status = pkgs.writeShellScriptBin "tmux-oc-notification-status" ''
    notification_file="$HOME/.cache/opencode/tmux-notifications.json"

    # Quick exit if no file
    if [ ! -f "$notification_file" ]; then
      exit 0
    fi

    # Count notifications within the last 30 minutes
    now=$(${pkgs.coreutils}/bin/date +%s)
    cutoff=$(( (now - 1800) * 1000 ))

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
```

- [ ] **Step 2: Register the script in `default.nix`**

In `home-manager/scripts/default.nix`, add the import:

```nix
    ./tmux-oc-notification-status.nix
```

Add it after `./tmux-oc-jump-notification.nix`.

- [ ] **Step 3: Commit**

```
feat(tmux): add notification count status bar script
```

---

### Task 8: Wire notification indicator into tmux status bar

**Files:**
- Modify: `home-manager/cli/tmux.nix:122`

Add the notification indicator to `status-right`, rendered in the accent color so it stands out. The `status-interval` should be set to ensure the indicator refreshes every few seconds.

- [ ] **Step 1: Add status-interval and update status-right**

In `home-manager/cli/tmux.nix`, add a `status-interval` setting (the default is 15 seconds, set it to 5 for responsive notification updates). Add it before the `status-right` line:

```
      set-option -gq status-interval 5
```

Then update the `status-right` line (line 122) to prepend the notification indicator. The indicator should appear in `thm_yellow` (the attention color) before the existing status segments:

Current:
```
      set-option -gq status-right "#[fg=$thm_pink,bg=$thm_bg,nobold,nounderscore,noitalics]#[fg=$thm_bg,bg=$thm_pink,nobold,nounderscore,noitalics] #[fg=$thm_fg,bg=$thm_gray] #{b:pane_current_path} #{?client_prefix,#[fg=$thm_red],#[fg=$thm_green]}#[bg=$thm_gray]#{?client_prefix,#[bg=$thm_red],#[bg=$thm_green]}#[fg=$thm_bg] #[fg=$thm_fg,bg=$thm_gray] #S "
```

New (add notification badge at the very start, before the pink segment):
```
      set-option -gq status-right "#[fg=$thm_yellow,bg=$thm_bg]#(tmux-oc-notification-status)#[default] #[fg=$thm_pink,bg=$thm_bg,nobold,nounderscore,noitalics]#[fg=$thm_bg,bg=$thm_pink,nobold,nounderscore,noitalics] #[fg=$thm_fg,bg=$thm_gray] #{b:pane_current_path} #{?client_prefix,#[fg=$thm_red],#[fg=$thm_green]}#[bg=$thm_gray]#{?client_prefix,#[bg=$thm_red],#[bg=$thm_green]}#[fg=$thm_bg] #[fg=$thm_fg,bg=$thm_gray] #S "
```

The `#(tmux-oc-notification-status)` runs the script on each status refresh. When no notifications exist, the script outputs nothing and the status bar is unchanged.

- [ ] **Step 2: Commit**

```
feat(tmux): show notification count badge in status bar
```

---

## Task Dependency Summary

Tasks 1-4 modify the TypeScript plugin (`src/index.ts`) and are independent of each other. Tasks 5-6 modify the jump script and must be done in order (Task 6 depends on variables introduced in Task 5). Task 7-8 create and wire the status bar indicator.

All plugin changes (Tasks 1-4) can be done in parallel. Task 5 must come before Task 6. Tasks 7-8 are independent of everything else.
