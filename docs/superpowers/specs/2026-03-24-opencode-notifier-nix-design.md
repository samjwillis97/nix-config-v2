# Design: Nix-managed OpenCode Notifier Plugin

## Context

Current OpenCode configuration in `home-manager/opencode/default.nix` uses:

- `settings.plugin = [ "@mohak34/opencode-notifier@latest" ]`

This causes OpenCode to auto-install the plugin via Bun at startup. The goal is to make plugin installation declarative and reproducible in Nix, and prevent OpenCode npm auto-install behavior.

## Goals

1. Install `@mohak34/opencode-notifier` using Nix with a pinned version.
2. Load the plugin from OpenCode's local plugin directory (`~/.config/opencode/plugins/`) managed by Home Manager.
3. Remove npm plugin auto-install from OpenCode settings.
4. Manage `~/.config/opencode/opencode-notifier.json` via Nix.

## Non-goals

- Building a generalized npm plugin packaging framework for all OpenCode plugins.
- Changing unrelated OpenCode agent, skill, tool, or permission configuration.

## Proposed Approach (Approved Option A)

### 1) Package plugin with pinned source in Nix

Create a derivation that fetches `mohak34/opencode-notifier` at a fixed tag/rev and builds its `dist/index.js` plugin entrypoint.

Implementation intent:

- Use `pkgs.fetchFromGitHub` with pinned `owner`, `repo`, `rev`, and `sha256`.
- Build with `pkgs.bun` (plugin upstream builds with Bun) using a reproducible dependency strategy:
  - lockfile pinned at selected `rev`
  - dependency fetches fixed and pre-resolved for sandboxed builds
  - build does not require live network access
- Install output file as a single JS plugin file in `$out`, named with a stable basename such as `opencode-notifier.js`.

This keeps updates explicit: bump `rev` and `sha256` intentionally.

### 2) Wire derivation into Home Manager plugin sync (explicit directory contract)

Use `modules.opencode.plugins` in `hm-modules/opencode.nix` and ensure it copies plugin files into `~/.config/opencode/plugins/` (plural) during activation.

Design decision:

- This change aligns with OpenCode docs and uses `plugins/` now (not as a follow-up), because plugin discovery path is goal-critical.
- If runtime validation proves `plugin/` is required, this will be explicitly documented and corresponding goals/tests will be adjusted.

### 3) Disable npm auto-install path

Remove:

- `settings.plugin = [ "@mohak34/opencode-notifier@latest" ]`

from `home-manager/opencode/default.nix`, so OpenCode does not auto-install the plugin from npm at startup.

### 4) Add declarative notifier config file

Manage `~/.config/opencode/opencode-notifier.json` through Home Manager, using defaults aligned with upstream plugin and local preferences.

Expected structure:

- `home.file.".config/opencode/opencode-notifier.json".text = builtins.toJSON { ... };`

## Data Flow

1. Nix evaluation fetches pinned plugin source.
2. Nix build compiles plugin to JS artifact.
3. Home Manager activation copies artifact to OpenCode plugin directory.
4. OpenCode loads local plugin file on startup.
5. OpenCode reads declarative notifier config JSON from `~/.config/opencode`.

## Component Architecture

- Nix derivation: fetches and builds pinned notifier source to one JS artifact.
- Home Manager sync: installs artifact into `~/.config/opencode/plugins/`.
- OpenCode loader: discovers and loads local plugin artifact at startup.
- Notifier config: declarative `~/.config/opencode/opencode-notifier.json`.

## Error Handling

- If upstream tag/build changes, derivation fails at build time (fast feedback).
- If hash mismatches, fetch fails deterministically.
- If plugin file copy fails, Home Manager activation fails, preventing partial state.

## Testing and Verification Plan

1. Run Home Manager/Nix eval for the affected host profile.
2. Run switch/apply and confirm files exist:
   - `~/.config/opencode/plugins/opencode-notifier.js` (or installed filename)
   - `~/.config/opencode/opencode-notifier.json`
3. Confirm `opencode.json` no longer contains `settings.plugin` npm entry.
4. Launch OpenCode and verify plugin behavior on an event (for example permission prompt).
5. Validate observability:
   - startup logs indicate plugin load success
   - no npm/Bun plugin auto-install attempt occurs
6. Validate negative paths:
   - malformed notifier JSON has clear/observable failure mode
   - wrong plugin directory name (singular/plural mismatch) is detectable during validation

## Rollback Plan

- Revert the Nix changes to previous git state.
- Re-add npm `settings.plugin` entry only if fallback is required.

## Risks and Mitigations

- **Directory naming mismatch (`plugin` vs `plugins`)**: Validate runtime behavior after apply; if needed, adjust module in a follow-up change.
- **Pinned revision staleness**: acceptable by design; update intentionally.
- **Build tool changes upstream**: caught by deterministic build failure and fixed by derivation update.

## Files Expected to Change (Implementation Phase)

- `home-manager/opencode/default.nix`
- `hm-modules/opencode.nix` (only if plugin dir path adjustment is required)
- New Nix package file for plugin derivation (location TBD by existing repo conventions)
