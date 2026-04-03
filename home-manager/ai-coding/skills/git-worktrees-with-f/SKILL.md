---
name: git-worktrees-with-f
description: Use when about to run any git worktree command (add, remove, list, prune), git clone for a new repo, or when the user asks to work on a different branch. Also use when you see git worktree in a plan or think about creating parallel working directories.
---

# Git Worktrees: Use `f` and Companion Tools

## Overview

**NEVER use raw `git worktree` or `git clone` commands.** This workspace uses `f`, `worktree`, `rm-tree`, and `git-bare-clone` to manage worktrees with a consistent directory convention. Raw git commands will create worktrees in the wrong locations, miss environment file copying, and break the workspace layout.

## The Rule

| Instead of... | Use... |
|---------------|--------|
| `git worktree add` | `f owner/repo/branch` or `worktree <branch>` |
| `git worktree remove` | `rm-tree <dir>` |
| `git worktree list` | `f -L` |
| `git worktree prune` | `rm-tree` handles this automatically |
| `git clone` | `f owner/repo/branch` (clones + sets up worktree) |
| `git clone --bare` | `git-bare-clone <repo-url>` |

## Directory Convention

All workspaces follow this layout -- never create worktrees outside it:

```
$HOME/code/github.com/<owner>/<repo>/<branch>/
```

## Tool Reference

### `f` -- Workspace Manager

Creates repos, branches, and worktrees in the correct directory structure.

```bash
# Create or switch to a worktree (creates tmux session)
f owner/repo/branch

# If repo doesn't exist locally, f clones it first
f acme/api/feature-auth

# List all worktree paths (agent-safe, no tmux)
f -L

# Resolve a single worktree path (agent-safe)
f -p owner/repo/branch
```

**Agent safety:** Only `f -L` and `f -p` are safe for non-interactive use. Bare `f <args>` creates tmux sessions -- only use when the user explicitly asks to switch to or create a branch.

### `worktree` -- Create Branch Worktree (from within a repo)

Use when you're already inside a repo and need a new branch worktree as a sibling directory.

```bash
# From inside $HOME/code/github.com/acme/api/main/
worktree feature-login
# Creates ../feature-login/ with:
#   - The branch checked out
#   - .env, .envrc, .tool-versions, .mise.toml copied over
#   - node_modules copied (copy-on-write)
#   - direnv allowed
```

- Runs `git pull` first to get latest remote state
- If branch exists (local or remote), checks it out; otherwise creates new branch
- Replaces `/` with `_` in branch names for directory names (e.g., `feat/login` becomes `feat_login`)

### `rm-tree` -- Remove Branch Worktree

```bash
# From the parent directory containing worktree siblings
rm-tree feature-login

# Remove multiple at once
rm-tree feature-a feature-b

# Specify non-default main branch
rm-tree -m develop feature-login
```

- Removes the directory
- Runs `git worktree prune` automatically
- Runs `git branch -D` to clean up the branch
- Defaults to `main` as primary branch, falls back to `master`

### `git-bare-clone` -- Bare Clone Setup

```bash
git-bare-clone git@github.com:owner/repo.git
# Creates .bare/ directory with bare clone
# Creates .git file pointing to .bare/
# Configures remote.origin.fetch for proper tracking
```

## When to Use Which Tool

```
Need a worktree for a different repo?
  → f owner/repo/branch

Need a new branch in the current repo?
  → worktree <branch-name>

Need to remove a worktree?
  → rm-tree <directory>

Need to list existing worktrees?
  → f -L

Need to set up a brand new bare clone?
  → git-bare-clone <repo-url>
```

## Common Mistakes

| Mistake | Why it's wrong | Correct approach |
|---------|---------------|------------------|
| `git worktree add ../feature ../feature` | Wrong directory structure, no env files copied | `worktree feature` |
| `git clone git@github.com:acme/api.git` | Creates repo outside the convention | `f acme/api/main` |
| `rm -rf ../feature-branch` | Leaves dangling worktree refs, doesn't prune | `rm-tree feature-branch` |
| `git worktree list` | Output format differs from workspace convention | `f -L` |
| `git checkout -b new-branch` | Creates branch in current worktree instead of new one | `worktree new-branch` |

## Red Flags -- STOP If You're About To

- Type `git worktree` -- use `f` or `worktree` instead
- Type `git clone` -- use `f` or `git-bare-clone` instead
- Create a directory under a repo for a branch checkout -- use the tools
- Remove a worktree directory with `rm -rf` -- use `rm-tree`
- Run `git branch -D` after removing a worktree -- `rm-tree` handles this
