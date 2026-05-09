---
name: git-workflow
description: Use when starting new work, managing branches, or finishing features. Covers branch creation, commit discipline, and merge workflows.
---

# Git Workflow

## When to Use

- Starting new work (should you branch?)
- Making commits (what to commit, when, messages)
- Finishing a feature (merge, PR, cleanup)

## Red Flags — Rationalizations to Watch For

| Excuse | Why It's Wrong | Do This Instead |
|--------|---------------|------------------|
| "It's a small change, I'll commit to main" | Small changes can still break things and are hard to revert | Branch for anything touching 3+ files |
| "I'll commit at the end" | Large commits are hard to review and revert | Commit after each logical unit |
| "WIP" as a commit message | Meaningless to future readers | Describe WHAT and WHY, even briefly |
| "I'll clean up the history later" | You won't. Write good messages now | Take 10 seconds to write a real message |
| "Tests pass locally, let me push" | Was a review done? | Run /review before pushing |

## Branch Strategy

### When to Branch

Create a feature branch for:
- Any change that touches 3+ files
- Any change that might need to be reverted
- Any change that will take multiple turns

Stay on current branch for:
- Single-file fixes
- Documentation updates
- Trivial config changes

### Branch Naming

```
<type>/<short-description>

feat/add-auth-middleware
fix/null-pointer-in-parser
refactor/extract-validation-logic
```

### Creating a Branch

```bash
git checkout -b feat/description
```

## Commit Discipline

### When to Commit

- After each logical unit of work
- After each plan step completes with verification
- NOT after every single file edit

### Commit Messages

```
<type>: <short description>

<body explaining what and why>
```

Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`

### What NOT to Commit

- Broken code (tests must pass)
- Debug logging left in
- Commented-out code
- TODO comments without tracking

## Finishing Work

### Pre-Finish Checklist

Before considering any branch finished:

1. \[ \] All tests pass (`npm test`, `cargo test`, etc.)
2. \[ \] Build succeeds (if applicable)
3. \[ \] Code review completed (use `/review`)
4. \[ \] No remaining TODOs or FIXMEs
5. \[ \] Commit history is clean and meaningful
6. \[ \] No debug logging or commented-out code

### Options Menu

Present these options to the human:

1. **Merge** — `git checkout main && git merge --no-ff feat/branch`
   - Only if ALL checklist items pass
   - Use `--no-ff` to preserve branch history

2. **PR** — Push and create a pull request
   - `git push -u origin feat/branch`
   - `gh pr create --title "..." --body "..."`
   - Include: what changed, how to test, checklist status

3. **Keep** — Leave the branch for later
   - Explain what's done and what remains
   - Commit any WIP with a clear message

4. **Discard** — Delete the branch entirely
   - Requires typed confirmation: "I want to discard this branch"
   - `git checkout main && git branch -D feat/branch`
   - This is irreversible

## Rules

- Never force push to shared branches
- Always verify tests pass before merge
- Use meaningful commit messages (not "fix", "update", "wip")
- Don't commit secrets, credentials, or API keys
