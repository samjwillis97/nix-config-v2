# Design: work-mbp coding-agent MicroVM framework

## Overview

This design ports the setup from Michael Stapelberg's coding-agent MicroVM post into this repo for `work-mbp`, adapted to macOS constraints and the vfkit Rosetta guidance.

The goal is to keep the same model as the article:

- disposable guest VM(s)
- explicit host-shared paths for workspace and agent state
- reusable base module for creating more VMs later

Initial scope is a reusable framework plus one starter VM optimized for general coding-agent workflows.

## Goals

- Provide one declarative starter MicroVM for `work-mbp`.
- Use `vfkit` on Apple Silicon and enable Rosetta for x86_64 binaries in ARM64 guests.
- Preserve host files safety by default via explicit `virtiofs` mounts only.
- Keep framework reusable so adding VM #2 is mostly data-entry.

## Non-Goals

- No Linux-host bridge/TAP/NAT setup from the article (not applicable to vfkit on macOS).
- No multi-VM matrix in the first pass.
- No major refactor of existing Linux microvm host modules (`modules/virtualisation/microvm-host.nix` etc.).

## Constraints

- Host is `work-mbp` (`aarch64-darwin`).
- Must follow microvm vfkit Rosetta docs:
  - `microvm.hypervisor = "vfkit"`
  - `microvm.vfkit.rosetta.enable = true`
  - `microvm.vfkit.rosetta.install = true`
- vfkit on macOS uses user-mode networking instead of tap/bridge.
- Shared agent state path is `/Users/samuel.willis/opencode-microvm`.

## Proposed Module Layout

Create a dedicated darwin microvm framework under `nix-darwin/microvm`:

- `nix-darwin/microvm/default.nix`
  - imports the pieces below
  - acts as the host-facing entrypoint
- `nix-darwin/microvm/base.nix`
  - shared guest defaults and helper to build guest definitions
- `nix-darwin/microvm/home.nix`
  - home-manager config used inside guests (shell/env/tooling defaults)
- `nix-darwin/microvm/vms.nix`
  - declaration of the initial starter VM

Host wiring:

- `hosts/work-mbp/default.nix` imports `../../nix-darwin/microvm`.
- Keep scope local to `work-mbp` by only importing this stack from that host.

## Architecture

### Host side

- Reuse existing `flake.inputs.microvm` input.
- `microvm.vms.<name>.config` is the Linux-host pattern from the article.
- On `work-mbp` (`aarch64-darwin`), use the equivalent darwin model: dedicated `nixosConfigurations.work-mbp-agentvm` plus `packages.aarch64-darwin.work-mbp-agentvm`.
- Use one starter VM name: `agentvm`.

### Guest side

Each guest imports:

- `flake.inputs.microvm.nixosModules.microvm`
- `flake.inputs.home-manager.nixosModules.home-manager`
- shared guest base from `nix-darwin/microvm/base.nix`
- profile-specific package set in `nix-darwin/microvm/vms.nix`

Guest defaults include:

- `networking.hostName = "agentvm"`
- `microvm.hypervisor = "vfkit"`
- Rosetta enabled and auto-install on missing host installation
- writable store overlay at `/nix/.rw-store`
- one `/var` volume for guest-local mutable state

## Shared Data and Mount Model

All shares use `virtiofs`.

- Host `/Users/samuel.willis/microvm/agentvm`
  - Guest mount: `/workspace`
  - Purpose: project code and files edited by agent
- Host `/nix/store`
  - Guest mount: `/nix/.ro-store`
  - Purpose: avoid large duplicate store images and improve startup/build time
- Host `/Users/samuel.willis/microvm/agentvm/ssh-host-keys`
  - Guest mount: `/etc/ssh/host-keys`
  - Purpose: stable SSH host identity across restarts
- Host `/Users/samuel.willis/opencode-microvm`
  - Guest mount: `/home/sam/opencode-microvm`
  - Purpose: persistent coding-agent state/config

## Guest Home/Shell Setup

Use home-manager inside guest to provide baseline shell behavior.

- enable zsh
- export agent state env vars in shell init:
  - `OPENCODE_CONFIG_DIR=/home/sam/opencode-microvm`
  - `CLAUDE_CONFIG_DIR=/home/sam/opencode-microvm` (compatibility with article workflow)
- start in `/workspace` by default for interactive sessions
- provide optional per-VM extra shell init hook for language-specific setup later

## Starter VM Profile

Starter VM is "general coding agent" oriented.

Base package set (subject to nixpkgs availability):

- `git`, `curl`, `wget`
- `ripgrep`, `fd`, `jq`, `file`, `which`, `tree`
- `gnumake`, `gcc`, `pkg-config`
- `vim` or `neovim`

Rosetta validation helper package:

- `pkgsCross.gnu64.hello` (x86_64 Linux binary runnable via Rosetta)

Resource defaults for first pass:

- `microvm.vcpu = 8`
- `microvm.mem = 4096`

## Networking Model

- Use vfkit user networking (default/compatible path on macOS).
- Do not declare tap/bridge interfaces.
- Add forwarded ports only when needed by workload (initially none required).

## Error Handling and Reliability

- Keep VM mutable state constrained to:
  - shared mounts listed above
  - `/var` image volume
- Preserve SSH host keys in shared host directory to avoid trust churn.
- Keep configuration isolated from existing Linux microvm modules to prevent cross-host regressions.
- If Rosetta is unavailable or fails to install, VM launch should fail early and visibly (expected behavior with `install = true` and no ignore flag).

## Verification Plan

### Build-time checks

- `darwin-rebuild build --flake .#work-mbp`
- `nix eval .#darwinConfigurations.work-mbp.config.system.build.toplevel.drvPath`

### VM launch checks

- Start VM via declared microvm runner from the built configuration.
- Confirm guest architecture:
  - `uname -m` returns `aarch64`

### Rosetta checks in guest

- Verify helper binary architecture:
  - `file $(which hello)` reports `x86-64`
- Execute helper binary:
  - `hello` prints expected output (`Hello, world!`)

### Shared path checks

- Create a file in guest `/workspace` and verify it exists on host in `/Users/samuel.willis/microvm/agentvm`.
- Confirm agent config/state files written under `/home/sam/opencode-microvm` persist across VM restarts.

## Rollout Plan

1. Add new microvm framework modules under `nix-darwin/microvm`.
2. Wire `hosts/work-mbp/default.nix` to import the framework.
3. Define `agentvm` starter guest in `nix-darwin/microvm/vms.nix`.
4. Build and run verification checks.
5. Iterate package set and resource sizing only after baseline passes.
