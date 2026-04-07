# OpenCode-Aware tmux Session Preview Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace `prefix + s` with an fzf-based session picker in a tmux popup that shows opencode session summaries in the preview pane.

**Architecture:** Two new `writeShellScriptBin` nix scripts -- a preview script that queries opencode's database and formats a summary, and a picker script that runs fzf with that preview in a tmux popup. The tmux keybinding changes from `choose-tree` to `display-popup` invoking the picker.

**Tech Stack:** Nix (home-manager, `writeShellScriptBin`), bash, tmux, fzf, opencode CLI (`opencode db`), jq

**Spec:** `docs/superpowers/specs/2026-04-07-tmux-opencode-session-preview-design.md`

---

### Task 1: Create the preview script (`tmux-session-preview`)

**Files:**
- Create: `home-manager/scripts/tmux-session-preview.nix`

This script takes a tmux session name, looks up the pane's working directory, queries the opencode database for a matching session, and either prints a formatted summary or falls back to `tmux capture-pane`.

**Important implementation details:**
- `opencode db --format json` returns `time_updated` as **milliseconds** (not seconds as the spec says). The relative time computation must divide by 1000 before comparing to `date +%s`.
- **Nix string escaping:** Inside nix indented strings (`''...''`), `$` NOT followed by `{` passes through literally. So `$.modelID` in SQL is fine as-is (no backslash needed). To produce a literal `${`, write `''${`. To produce a literal single quote, write `'''`.

- [ ] **Step 1: Create `home-manager/scripts/tmux-session-preview.nix`**

```nix
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

    # Sanitize directory for SQL (escape single quotes)
    safe_dir=$(printf '%s' "$dir" | sed "s/'/''/g")

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
```

- [ ] **Step 2: Commit**

```
feat(tmux): add opencode session preview script

queries opencode db for session data matching the tmux pane's
working directory and formats a summary with title, model, tokens,
cost, and code changes.
```

---

### Task 2: Create the session picker script (`tmux-oc-session-picker`)

**Files:**
- Create: `home-manager/scripts/tmux-oc-session-picker.nix`

This script lists tmux sessions via fzf with the preview script from Task 1, inside a format suitable for `tmux display-popup`.

The preview script (`tmux-session-preview`) is called by bare name since both scripts end up in `home.packages` and thus `$PATH`. The `display-popup` inherits the invoking pane's environment. This matches the existing pattern where `tmux-cht.sh` is referenced by name in `tmux.nix`.

- [ ] **Step 1: Create `home-manager/scripts/tmux-oc-session-picker.nix`**

```nix
{ pkgs, ... }:
let
  tmux-oc-session-picker = pkgs.writeShellScriptBin "tmux-oc-session-picker" ''
    current_session=$(${pkgs.tmux}/bin/tmux display-message -p '#{session_name}')

    session=$(${pkgs.tmux}/bin/tmux list-sessions -F '#{session_name}' | \
      ${pkgs.fzf}/bin/fzf \
        --preview 'tmux-session-preview {}' \
        --preview-window=right:60%:wrap \
        --header='Switch Session' \
        --no-sort \
        --border=none \
        --query="$current_session")

    if [ -n "$session" ]; then
      ${pkgs.tmux}/bin/tmux switch-client -t "$session"
    fi
  '';
in
{
  home.packages = [ tmux-oc-session-picker ];
}
```

- [ ] **Step 2: Commit**

```
feat(tmux): add opencode-aware session picker script

fzf-based tmux session picker with opencode summary preview,
designed to run inside a tmux display-popup.
```

---

### Task 3: Wire up imports and keybinding

**Files:**
- Modify: `home-manager/scripts/default.nix` (add imports for both new scripts)
- Modify: `home-manager/cli/tmux.nix:74` (change `prefix + s` binding)

- [ ] **Step 1: Add imports to `home-manager/scripts/default.nix`**

Add these two lines after the existing tmux script imports:

```nix
{ ... }:
{
  imports = [
    ./git-bare-clone.nix
    ./hugo-reveal-bootstrap.nix
    ./tmux-sessionizer.nix
    ./tmux-live-sessionizer.nix
    ./tmux-session-preview.nix
    ./tmux-oc-session-picker.nix
    ./nix-shells
    # ./tmux-cht.nix
  ];
}
```

- [ ] **Step 2: Change the `prefix + s` keybinding in `home-manager/cli/tmux.nix`**

Replace line 74:
```
bind s choose-tree -sZ -O name
```

With:
```
bind s display-popup -E -w 80% -h 80% "tmux-oc-session-picker"
```

The script is in `$PATH` via `home.packages`, so the bare name works. This matches the pattern used on line 58 (`tmux-cht.sh`).

- [ ] **Step 3: Verify nix evaluation succeeds**

Run: `nix build .#homeConfigurations.sam.activationPackage --dry-run 2>&1 | tail -5`

This checks that all imports resolve and the nix expressions are valid without actually building.

- [ ] **Step 4: Commit**

```
feat(tmux): replace choose-tree with opencode-aware session picker

prefix+s now opens an fzf popup showing opencode session summaries
(title, model, tokens, cost, code changes) in the preview pane.
sessions without opencode data fall back to pane content preview.
```

---

### Task 4: Manual smoke test

This feature requires a running tmux environment and opencode database, so automated testing isn't practical. Verify manually after a `home-manager switch`.

- [ ] **Step 1: Build and switch**

Run: `home-manager switch --flake .` (or the appropriate switch command for this config)

- [ ] **Step 2: Test the preview script directly**

In a tmux session, run:
```bash
tmux-session-preview "$(tmux display-message -p '#{session_name}')"
```

Expected: Either an opencode summary box or captured pane content.

- [ ] **Step 3: Test the session picker**

Press `prefix + s`. Expected:
- A centered popup appears (80% x 80%)
- Session list on the left, preview on the right
- Current session name is pre-filled in the search
- Selecting a session and pressing Enter switches to it
- Pressing Escape closes the popup

- [ ] **Step 4: Test fallback behavior**

Switch to a session that has no opencode history (e.g., a fresh session). Press `prefix + s` and highlight it. Expected: The preview shows the captured pane content instead of an opencode summary.
