# tmux session cache and notification jump implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the slow `opencode db` preview with an event-driven JSON cache, and add a `prefix + A` keybinding to jump to the most recent OpenCode notification.

**Architecture:** A TypeScript OpenCode plugin writes per-worktree session cache files and a global notification queue on events. Shell scripts read these files for fast tmux preview and notification jumping. The plugin is built with bun and packaged as a nix derivation.

**Tech Stack:** TypeScript (OpenCode plugin API), bun (build), nix (packaging), bash (tmux scripts), jq (JSON parsing)

---

### Task 1: create the TypeScript plugin source

**Files:**
- Create: `home-manager/ai-coding/plugins/tmux-session-cache/src/index.ts`
- Create: `home-manager/ai-coding/plugins/tmux-session-cache/package.json`
- Create: `home-manager/ai-coding/plugins/tmux-session-cache/tsconfig.json`

- [ ] **Step 1: create the project directory and package.json**

```bash
mkdir -p home-manager/ai-coding/plugins/tmux-session-cache/src
```

Write `home-manager/ai-coding/plugins/tmux-session-cache/package.json`:

```json
{
  "name": "tmux-session-cache",
  "version": "0.1.0",
  "private": true,
  "main": "dist/index.js",
  "devDependencies": {
    "@opencode-ai/plugin": "latest"
  }
}
```

- [ ] **Step 2: create tsconfig.json**

Write `home-manager/ai-coding/plugins/tmux-session-cache/tsconfig.json`:

```json
{
  "compilerOptions": {
    "target": "ESNext",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "outDir": "dist",
    "rootDir": "src",
    "types": ["bun-types"]
  },
  "include": ["src"]
}
```

- [ ] **Step 3: write the plugin source**

Write `home-manager/ai-coding/plugins/tmux-session-cache/src/index.ts`:

The plugin exports `TmuxSessionCachePlugin`. Key implementation details:

- **Imports**: `fs` (writeFileSync, readFileSync, mkdirSync, existsSync), `path` (join), `crypto` (createHash), `os` (homedir)
- **Constants**:
  - `CACHE_DIR = path.join(os.homedir(), '.cache', 'opencode', 'tmux-cache')`
  - `NOTIFICATION_FILE = path.join(os.homedir(), '.cache', 'opencode', 'tmux-notifications.json')`
  - `MAX_QUEUE_SIZE = 50`
- **`hashWorktree(worktree: string): string`** -- returns `crypto.createHash('sha256').update(worktree).digest('hex')`
- **`writeCache(worktree: string, data: object): void`** -- ensures `CACHE_DIR` exists, writes JSON to `<CACHE_DIR>/<hash>.json`. Use atomic write: write to a `.tmp` file then rename.
- **`appendNotification(entry: object): void`** -- reads existing queue (or `[]`), appends entry, prunes to last `MAX_QUEUE_SIZE`, writes back. Use atomic write.
- **`fetchSessionData(client, sessionID): Promise<object>`** -- calls `client.session.get({ path: { id: sessionID } })` and `client.session.messages({ path: { id: sessionID } })`. Extracts:
  - `title` from session response
  - `additions`, `deletions`, `files` from session summary fields (check `response.data` for `summary_additions`, `summary_deletions`, `summary_files` or equivalent SDK field names)
  - Iterates messages to sum `tokens.input`, `tokens.output`, `cost` from message data
  - Gets `model` and `provider` from the last assistant message's data
  - Gets `updatedAt` from session's `time_updated`

  **Important**: the SDK client returns typed objects. The field names may differ from the raw SQL column names used in the old script. Use `response.data` fields. If the SDK doesn't expose summary fields directly, fall back to available data.

- **`getSessionIDFromEvent(event): string | null`** -- extracts `event.properties.sessionID` if present
- **Plugin function**: receives `{ client, worktree }`. Returns hooks:
  - `event: async ({ event })` handler:
    - On `session.idle`: get sessionID, fetch data, write cache, append notification with event `"complete"`
    - On `session.error`: get sessionID, fetch data, write cache, append notification with event `"error"`
    - On `permission.asked`: get sessionID, append notification with event `"permission"` (cache write optional -- session may not have meaningful data yet)
    - On `session.updated`: get sessionID, fetch data, write cache (no notification)
  - `"tool.execute.before": async (input)` handler:
    - If `input.tool === "question"`: append notification with event `"question"`
    - If `input.tool === "plan_exit"`: append notification with event `"plan_exit"`

  All handlers should wrap in try/catch to never crash the host. Log errors via `console.error` (or `client.app.log` if available).

- [ ] **Step 4: verify the plugin builds locally with bun**

```bash
cd home-manager/ai-coding/plugins/tmux-session-cache
bun install
bun build src/index.ts --outdir dist --target node
```

Expected: `dist/index.js` is produced without errors.

- [ ] **Step 5: commit the plugin source**

```bash
git add home-manager/ai-coding/plugins/tmux-session-cache/
git commit -m "feat(tmux): add tmux-session-cache OpenCode plugin source

typescript plugin that caches session data to json files on
opencode events for fast tmux preview and notification jumping.

Assisted-by: Claude Opus 4 via OpenCode"
```

---

### Task 2: create the nix package derivation

**Files:**
- Create: `packages/tmux-session-cache-plugin-deps.nix`
- Create: `packages/tmux-session-cache-plugin.nix`
- Modify: `overlays/default.nix`

The plugin has one dev dependency (`@opencode-ai/plugin` for types). Since bun build bundles everything, the dep is only needed at build time. Follow the two-derivation pattern from `opencode-notifier`.

- [ ] **Step 1: create the deps derivation**

Write `packages/tmux-session-cache-plugin-deps.nix`:

```nix
{
  stdenvNoCC,
  bun,
}:

stdenvNoCC.mkDerivation {
  pname = "tmux-session-cache-plugin-deps";
  version = "0.1.0";

  src = ../home-manager/ai-coding/plugins/tmux-session-cache;

  nativeBuildInputs = [ bun ];

  dontConfigure = true;
  dontFixup = true;

  outputHashMode = "recursive";
  outputHashAlgo = "sha256";
  outputHash = ""; # Will need to be filled after first build attempt

  buildPhase = ''
    runHook preBuild

    export HOME="$PWD/.home"
    mkdir -p "$HOME"

    bun install --frozen-lockfile

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    cp -R node_modules "$out/node_modules"
    cp package.json "$out/"
    if [ -f bun.lock ]; then cp bun.lock "$out/"; fi

    runHook postInstall
  '';
}
```

**Note**: The `outputHash` must be determined by attempting a build with a dummy hash, capturing the actual hash from the error, and updating. Run:

```bash
nix build .#tmux-session-cache-plugin-deps 2>&1 | grep 'got:' | awk '{print $2}'
```

Also, `bun install --frozen-lockfile` requires a `bun.lock` file. Generate it first:

```bash
cd home-manager/ai-coding/plugins/tmux-session-cache
bun install
```

This creates `bun.lock`. Commit it alongside `package.json`.

- [ ] **Step 2: create the build derivation**

Write `packages/tmux-session-cache-plugin.nix`:

```nix
{
  stdenvNoCC,
  bun,
  tmux-session-cache-plugin-deps,
}:

stdenvNoCC.mkDerivation {
  pname = "tmux-session-cache-plugin";
  version = "0.1.0";

  src = ../home-manager/ai-coding/plugins/tmux-session-cache;

  nativeBuildInputs = [ bun ];

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild

    export HOME="$PWD/.home"
    mkdir -p "$HOME"

    rm -rf node_modules
    cp -R "${tmux-session-cache-plugin-deps}/node_modules" ./node_modules
    chmod -R u+w ./node_modules

    bun build src/index.ts --outdir dist --target node --offline

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm644 dist/index.js "$out/dist/index.js"

    runHook postInstall
  '';
}
```

- [ ] **Step 3: register in overlays**

Modify `overlays/default.nix` -- add these two lines after the `opencode-notifier` entries (around line 17-18):

```nix
tmux-session-cache-plugin-deps = final.callPackage ../packages/tmux-session-cache-plugin-deps.nix { };
tmux-session-cache-plugin = final.callPackage ../packages/tmux-session-cache-plugin.nix { };
```

- [ ] **Step 4: determine the correct output hash**

Run the build for the deps derivation. It will fail with a hash mismatch. Capture the correct hash and update `packages/tmux-session-cache-plugin-deps.nix`.

```bash
nix build .#tmux-session-cache-plugin-deps 2>&1
```

Update the `outputHash` field with the correct hash.

- [ ] **Step 5: verify the full package builds**

```bash
nix build .#tmux-session-cache-plugin
ls result/dist/index.js
```

Expected: build succeeds, `result/dist/index.js` exists.

- [ ] **Step 6: commit the nix packaging**

```bash
git add packages/tmux-session-cache-plugin-deps.nix packages/tmux-session-cache-plugin.nix overlays/default.nix
git add home-manager/ai-coding/plugins/tmux-session-cache/bun.lock  # if not already committed
git commit -m "build: add nix derivation for tmux-session-cache plugin

two-derivation pattern: FOD for deps, build derivation for bun
bundle. registered in overlays.

Assisted-by: Claude Opus 4 via OpenCode"
```

---

### Task 3: wire the plugin into opencode config

**Files:**
- Modify: `home-manager/ai-coding/default.nix:22-26`

- [ ] **Step 1: add the plugin to the plugins list**

In `home-manager/ai-coding/default.nix`, modify the `plugins` list (around line 22) to add the cache plugin:

```nix
  plugins = [
    "${pkgs.opencode-notifier}/dist/index.js"
    "${pkgs.tmux-session-cache-plugin}/dist/index.js"
  ]
  ++ getFilesInDir ./plugins ".js"
  ++ (if pkgs.stdenv.isDarwin then getFilesInDir ./plugins/darwin ".js" else [ ]);
```

- [ ] **Step 2: verify dry-run build**

```bash
nix build .#homeConfigurations.sam@Sams-MacBook-Air.activationPackage --dry-run
```

Expected: no evaluation errors.

- [ ] **Step 3: commit**

```bash
git add home-manager/ai-coding/default.nix
git commit -m "feat(ai-coding): wire tmux-session-cache plugin into opencode

Assisted-by: Claude Opus 4 via OpenCode"
```

---

### Task 4: rewrite the preview script to read cache

**Files:**
- Modify: `home-manager/scripts/tmux-session-preview.nix`

- [ ] **Step 1: rewrite the preview script**

Replace the contents of `home-manager/scripts/tmux-session-preview.nix` with:

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

    # Hash the directory to find the cache file
    hash=$(printf '%s' "$dir" | ${pkgs.coreutils}/bin/sha256sum | ${pkgs.coreutils}/bin/cut -d' ' -f1)
    cache_file="$HOME/.cache/opencode/tmux-cache/$hash.json"

    if [ -f "$cache_file" ]; then
      # Read cached data
      title=$(${pkgs.jq}/bin/jq -r '.title // "untitled"' "$cache_file")
      model=$(${pkgs.jq}/bin/jq -r '.model // "unknown"' "$cache_file")
      provider=$(${pkgs.jq}/bin/jq -r '.provider // "unknown"' "$cache_file")
      tokens_in=$(${pkgs.jq}/bin/jq -r '.tokensIn // 0' "$cache_file")
      tokens_out=$(${pkgs.jq}/bin/jq -r '.tokensOut // 0' "$cache_file")
      total_cost=$(${pkgs.jq}/bin/jq -r '.cost // 0' "$cache_file")
      additions=$(${pkgs.jq}/bin/jq -r '.additions // 0' "$cache_file")
      deletions=$(${pkgs.jq}/bin/jq -r '.deletions // 0' "$cache_file")
      files=$(${pkgs.jq}/bin/jq -r '.files // 0' "$cache_file")
      time_updated_ms=$(${pkgs.jq}/bin/jq -r '.updatedAt // 0' "$cache_file")

      # Compute relative time (updatedAt is in milliseconds)
      now=$(${pkgs.coreutils}/bin/date +%s)
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

      # Format token numbers with commas
      fmt_tokens_in=$(printf "%'d" "$tokens_in" 2>/dev/null || echo "$tokens_in")
      fmt_tokens_out=$(printf "%'d" "$tokens_out" 2>/dev/null || echo "$tokens_out")

      # Format cost
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
      # No cache file -- fall back to pane capture
      ${pkgs.tmux}/bin/tmux capture-pane -t "$session_name" -p 2>/dev/null
    fi
  '';
in
{
  home.packages = [ tmux-session-preview ];
}
```

Key differences from the old script:
- No `opencode` dependency -- reads a local JSON file
- Uses `sha256sum` to hash the worktree path (matches the plugin's `crypto.createHash('sha256')`)
- Uses full nix paths for `sha256sum`, `cut`, `date` via `${pkgs.coreutils}`
- Same output format as before

- [ ] **Step 2: verify dry-run build**

```bash
nix build .#homeConfigurations.sam@Sams-MacBook-Air.activationPackage --dry-run
```

Expected: no evaluation errors.

- [ ] **Step 3: commit**

```bash
git add home-manager/scripts/tmux-session-preview.nix
git commit -m "refactor(tmux): rewrite preview to read cache instead of opencode db

replaces the ~150ms opencode db query with a ~1ms json file read.
the cache file is written by the tmux-session-cache opencode plugin.

Assisted-by: Claude Opus 4 via OpenCode"
```

---

### Task 5: create the jump-to-notification script

**Files:**
- Create: `home-manager/scripts/tmux-oc-jump-notification.nix`
- Modify: `home-manager/scripts/default.nix`
- Modify: `home-manager/cli/tmux.nix`

- [ ] **Step 1: write the jump script**

Write `home-manager/scripts/tmux-oc-jump-notification.nix`:

```nix
{ pkgs, ... }:
let
  tmux-oc-jump-notification = pkgs.writeShellScriptBin "tmux-oc-jump-notification" ''
    NOTIFICATION_FILE="$HOME/.cache/opencode/tmux-notifications.json"

    # Check if notification file exists
    if [ ! -f "$NOTIFICATION_FILE" ]; then
      ${pkgs.tmux}/bin/tmux display-message "No recent notifications"
      exit 0
    fi

    # Read the queue
    queue=$(${pkgs.jq}/bin/jq -r '.' "$NOTIFICATION_FILE" 2>/dev/null)
    if [ -z "$queue" ] || [ "$queue" = "[]" ] || [ "$queue" = "null" ]; then
      ${pkgs.tmux}/bin/tmux display-message "No recent notifications"
      exit 0
    fi

    # Get current time
    now=$(${pkgs.coreutils}/bin/date +%s)
    cutoff=$(( (now - 300) * 1000 ))  # 5 minutes ago in milliseconds

    # Find the most recent entry within the last 5 minutes (iterate from end)
    len=$(echo "$queue" | ${pkgs.jq}/bin/jq 'length')
    target_idx=-1
    target_worktree=""

    i=$((len - 1))
    while [ "$i" -ge 0 ]; do
      ts=$(echo "$queue" | ${pkgs.jq}/bin/jq -r ".[$i].timestamp // 0")
      if [ "$ts" -ge "$cutoff" ]; then
        target_idx=$i
        target_worktree=$(echo "$queue" | ${pkgs.jq}/bin/jq -r ".[$i].worktree")
        break
      fi
      i=$((i - 1))
    done

    if [ "$target_idx" -eq -1 ] || [ -z "$target_worktree" ]; then
      ${pkgs.tmux}/bin/tmux display-message "No recent notifications"
      exit 0
    fi

    # Find the tmux session whose pane_current_path matches the worktree
    target_session=""
    while IFS= read -r sess; do
      pane_path=$(${pkgs.tmux}/bin/tmux display-message -t "$sess" -p '#{pane_current_path}' 2>/dev/null)
      if [ "$pane_path" = "$target_worktree" ]; then
        target_session="$sess"
        break
      fi
    done < <(${pkgs.tmux}/bin/tmux list-sessions -F '#{session_name}' 2>/dev/null)

    if [ -z "$target_session" ]; then
      ${pkgs.tmux}/bin/tmux display-message "Notification session not found"
      exit 0
    fi

    # Switch to the target session
    ${pkgs.tmux}/bin/tmux switch-client -t "$target_session"

    # Remove the consumed entry from the queue
    updated=$(echo "$queue" | ${pkgs.jq}/bin/jq "del(.[$target_idx])")
    printf '%s' "$updated" > "$NOTIFICATION_FILE"
  '';
in
{
  home.packages = [ tmux-oc-jump-notification ];
}
```

- [ ] **Step 2: add the import to default.nix**

Modify `home-manager/scripts/default.nix` -- add `./tmux-oc-jump-notification.nix` to the imports list, after `./tmux-oc-session-picker.nix`.

- [ ] **Step 3: add the keybinding to tmux.nix**

In `home-manager/cli/tmux.nix`, after the `bind a` line (around line 77), add:

```
      # jump to most recent opencode notification
      bind A run-shell "tmux-oc-jump-notification"
```

- [ ] **Step 4: verify dry-run build**

```bash
nix build .#homeConfigurations.sam@Sams-MacBook-Air.activationPackage --dry-run
```

Expected: no evaluation errors.

- [ ] **Step 5: commit**

```bash
git add home-manager/scripts/tmux-oc-jump-notification.nix home-manager/scripts/default.nix home-manager/cli/tmux.nix
git commit -m "feat(tmux): add prefix+A to jump to latest opencode notification

reads the notification queue, finds the most recent entry within
5 minutes, resolves worktree to tmux session, switches to it,
and removes the consumed entry from the queue.

Assisted-by: Claude Opus 4 via OpenCode"
```

---

### Task 6: integration verification and smoke test

**Files:** none (verification only)

- [ ] **Step 1: full nix build**

```bash
nix build .#homeConfigurations.sam@Sams-MacBook-Air.activationPackage
```

Expected: build succeeds with no errors.

- [ ] **Step 2: deploy and test**

```bash
home-manager switch --flake .
```

Then in tmux:
1. Open a project with an active OpenCode session
2. Press `prefix + a` -- verify fzf picker opens, preview loads fast from cache (should be instant if the plugin has run)
3. Press `prefix + s` -- verify standard session list still works
4. Trigger an OpenCode event (e.g. complete a session) -- verify the notification queue file is created at `~/.cache/opencode/tmux-notifications.json`
5. Press `prefix + A` -- verify it switches to the session where the notification originated

**Note**: on first deployment, cache files won't exist until OpenCode fires events. The preview script will fall back to pane capture, which is the expected behavior. Start an OpenCode session and interact with it to populate the cache.

- [ ] **Step 3: verify the cache files**

```bash
ls ~/.cache/opencode/tmux-cache/
cat ~/.cache/opencode/tmux-notifications.json
```

Expected: JSON files exist with the schema defined in the spec.
