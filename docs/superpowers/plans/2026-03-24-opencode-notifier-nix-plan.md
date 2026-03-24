# OpenCode Notifier Nix Management Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Install `@mohak34/opencode-notifier` via pinned Nix packaging, remove OpenCode npm auto-install, and manage notifier config declaratively.

**Architecture:** Add a dedicated Nix package that produces a single plugin JS artifact from a pinned upstream revision, expose it through the repo overlay, and feed that artifact into the existing `modules.opencode.plugins` pipeline. Update Home Manager OpenCode config to stop using `settings.plugin` npm installation and write `opencode-notifier.json` as a managed file.

**Tech Stack:** Nix flakes, nixpkgs derivations, Home Manager activation hooks, OpenCode plugin/config conventions.

---

## File Structure

- Create: `packages/opencode-notifier.nix` - pinned derivation that builds plugin artifact and outputs one `.js` file.
- Create: `packages/opencode-notifier-deps.nix` - fixed-output dependency vendor derivation for reproducible Bun dependencies.
- Modify: `overlays/default.nix` - expose `opencode-notifier` package via overlay.
- Modify: `hm-modules/opencode.nix` - switch plugin sync directory from `~/.config/opencode/plugin` to `~/.config/opencode/plugins`.
- Modify: `home-manager/opencode/default.nix` - add packaged plugin to `modules.opencode.plugins`, remove npm `settings.plugin`, and add `opencode-notifier.json` managed config.
- Verify: `docs/superpowers/specs/2026-03-24-opencode-notifier-nix-design.md` - ensure implementation matches approved design.

### Task 1: Add pinned notifier package

**Files:**
- Create: `packages/opencode-notifier-deps.nix`
- Create: `packages/opencode-notifier.nix`
- Modify: `overlays/default.nix`

- [ ] **Step 1: Write package skeleton with pinned source and fixed output intent**

```nix
{ stdenvNoCC, fetchFromGitHub, bun, lib, callPackage }:

let
  version = "0.1.35";
  src = fetchFromGitHub {
    owner = "mohak34";
    repo = "opencode-notifier";
    rev = "v${version}";
    hash = lib.fakeHash;
  };

  opencodeNotifierDeps = callPackage ./opencode-notifier-deps.nix {
    inherit src version;
  };
in

stdenvNoCC.mkDerivation rec {
  pname = "opencode-notifier";
  inherit version src;

  nativeBuildInputs = [ bun ];
}
```

- [ ] **Step 2: Resolve correct SRI hash using fake hash bootstrap**

Run: set `hash = lib.fakeHash;` then run `nix build .#darwinConfigurations.work-mbp.pkgs.opencode-notifier`
Expected: build fails once and prints the expected `sha256-...` SRI hash to copy into `fetchFromGitHub.hash` in `packages/opencode-notifier.nix`

- [ ] **Step 3: Implement fixed-output vendor derivation for Bun dependencies**

Create `packages/opencode-notifier-deps.nix` as a fixed-output derivation that vendors `node_modules` with pinned output hash.

```nix
{ stdenvNoCC, bun, lib, src, version }:

stdenvNoCC.mkDerivation {
  pname = "opencode-notifier-deps";
  version = "0.1.35";
  inherit src;
  nativeBuildInputs = [ bun ];

  outputHashMode = "recursive";
  outputHashAlgo = "sha256";
  outputHash = lib.fakeHash;

  buildPhase = ''
    export HOME="$TMPDIR"
    bun install --frozen-lockfile
  '';

  installPhase = ''
    mkdir -p $out
    cp -r node_modules $out/node_modules
  '';
}
```

Expected: dependency tree is content-addressed and reproducible; online fetches are isolated to this fixed-output step only.

- [ ] **Step 3b: Resolve fixed-output hash for dependency vendor derivation**

Run: after setting the source hash, re-run `nix build .#darwinConfigurations.work-mbp.pkgs.opencode-notifier`
Expected: build fails at the dependency vendor derivation and prints the expected `sha256-...` SRI hash to copy into `outputHash` in `packages/opencode-notifier-deps.nix`

- [ ] **Step 4: Complete derivation build/install phases for single-file output**

```nix
buildPhase = ''
  export HOME="$TMPDIR"
  cp -r ${opencodeNotifierDeps}/node_modules ./
  bun install --frozen-lockfile --offline
  bun run build
'';

installPhase = ''
  install -Dm644 dist/index.js "$out/opencode-notifier.js"
'';
```

- [ ] **Step 5: Expose package from overlay**

```nix
opencode-notifier = prev.callPackage ../packages/opencode-notifier.nix { };
```

- [ ] **Step 6: Validate package builds in isolation**

Run: `nix build .#darwinConfigurations.work-mbp.pkgs.opencode-notifier`
Expected: build succeeds and produces a store path ending in `/opencode-notifier-0.1.35`

- [ ] **Step 7: Commit package + overlay update**

```bash
git add -- packages/opencode-notifier-deps.nix packages/opencode-notifier.nix overlays/default.nix
git commit -m "feat(opencode): package notifier plugin with pinned nix derivation" -- packages/opencode-notifier-deps.nix packages/opencode-notifier.nix overlays/default.nix
```

### Task 2: Align plugin directory contract in module

**Files:**
- Modify: `hm-modules/opencode.nix`

- [ ] **Step 1: Write failing check for legacy singular plugin path reference**

Run: `rg "\.config/opencode/plugin" hm-modules/opencode.nix`
Expected: finds existing singular path references (this is the failure condition)

- [ ] **Step 2: Replace activation script paths with plural `plugins` directory**

```nix
mkdir -p $HOME/.config/opencode/plugins
rm -f $HOME/.config/opencode/plugins/*
cp ${plugin} $HOME/.config/opencode/plugins/
```

- [ ] **Step 3: Re-run check to verify singular path removed**

Run: `rg "\.config/opencode/plugin" hm-modules/opencode.nix`
Expected: no matches

- [ ] **Step 4: Commit module path contract update**

```bash
git add -- hm-modules/opencode.nix
git commit -m "fix(opencode): sync local plugins to plugins directory" -- hm-modules/opencode.nix
```

### Task 3: Wire packaged plugin and remove npm auto-install

**Files:**
- Modify: `home-manager/opencode/default.nix`

- [ ] **Step 1: Add packaged plugin artifact to plugins list**

```nix
plugins =
  [ "${pkgs.opencode-notifier}/opencode-notifier.js" ]
  ++ getFilesInDir ./plugins ".js"
  ++ (if (pkgs.stdenv.isDarwin) then getFilesInDir ./plugins/darwin ".js" else [ ]);
```

- [ ] **Step 2: Remove npm plugin entry from OpenCode settings**

Delete this block:

```nix
plugin = [
  "@mohak34/opencode-notifier@latest"
];
```

- [ ] **Step 3: Add declarative notifier config file**

```nix
home.file.".config/opencode/opencode-notifier.json".text = builtins.toJSON {
  sound = true;
  notification = true;
  timeout = 5;
  showProjectName = true;
  showSessionTitle = false;
  showIcon = true;
  suppressWhenFocused = true;
  enableOnDesktop = false;
  notificationSystem = "osascript";
  linux = { grouping = false; };
};
```

- [ ] **Step 4: Verify npm plugin key is absent and declarative config is present**

Run: `rg "@mohak34/opencode-notifier|plugin = \[" home-manager/opencode/default.nix`
Expected: no `settings.plugin` npm entry remains

Run: `rg "opencode-notifier.json|notificationSystem|suppressWhenFocused" home-manager/opencode/default.nix`
Expected: matches for managed notifier config

- [ ] **Step 5: Commit Home Manager config changes**

```bash
git add -- home-manager/opencode/default.nix
git commit -m "feat(opencode): manage notifier plugin and config via nix" -- home-manager/opencode/default.nix
```

### Task 4: End-to-end verification

**Files:**
- Verify only (no new files expected)

- [ ] **Step 1: Evaluate target Home Manager configuration**

Run: `nix eval .#darwinConfigurations.work-mbp.config.system.stateVersion`
Expected: evaluation succeeds without errors

- [ ] **Step 2: Build full target activation package**

Run: `nix build .#darwinConfigurations.work-mbp.system`
Expected: build completes successfully

- [ ] **Step 3: Verify final git diff only contains intended files**

Run: `git diff --name-only "$(git merge-base HEAD @{upstream})"..HEAD`
Expected: only intended files for this plan appear across the entire branch delta

- [ ] **Step 4: Manual runtime check after switch (operator step)**

Run: `darwin-rebuild switch --flake .#work-mbp`
Expected: `~/.config/opencode/plugins/opencode-notifier.js` exists and `~/.config/opencode/opencode-notifier.json` exists

- [ ] **Step 5: Validate no OpenCode npm auto-install path is used**

Run: `opencode` (start a session and observe startup/plugin behavior)
Expected: plugin loads from local plugins directory; no npm install of `@mohak34/opencode-notifier` is triggered

- [ ] **Step 6: Negative-path checks (config + directory contract)**

Run A: temporarily set malformed JSON in `~/.config/opencode/opencode-notifier.json` and restart OpenCode
Expected A: clear/observable plugin config failure mode

Run B: temporarily move `~/.config/opencode/plugins/opencode-notifier.js` out of `plugins/` (or into singular `plugin/`) and restart OpenCode
Expected B: notifier plugin does not load, confirming directory contract is enforced

Restore: `darwin-rebuild switch --flake .#work-mbp`

- [ ] **Step 7: Final commit for verification adjustments (if any)**

```bash
git add -- packages/opencode-notifier.nix overlays/default.nix hm-modules/opencode.nix home-manager/opencode/default.nix
git commit -m "chore(opencode): verify nix-managed notifier plugin integration" -- packages/opencode-notifier.nix overlays/default.nix hm-modules/opencode.nix home-manager/opencode/default.nix
```
