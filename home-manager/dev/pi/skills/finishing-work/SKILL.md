---
name: finishing-work
description: Use when implementation is complete and you need to decide how to integrate the work - guides completion by presenting structured options for merge, PR, or cleanup
---

# Finishing Work

## Overview

Guide completion of development work by presenting clear options and handling the chosen workflow.

**Core principle:** Verify tests → Present options → Execute choice → Clean up.

## The Process

### Step 1: Verify Tests

**Before presenting options, verify tests pass:**

```bash
# Run project's test suite
npm test / cargo test / pytest / go test ./...
```

**If tests fail:**

```
Tests failing (<N> failures). Must fix before completing:

[Show failures]

Cannot proceed with merge/PR until tests pass.
```

Stop. Don't proceed to Step 2.

**If tests pass:** Continue to Step 2.

### Step 2: Determine Base Branch

```bash
# Try common base branches
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```

Or ask: "This branch split from main — is that correct?"

### Step 3: Present Options

**Present exactly these 4 options:**

```
Implementation complete. What would you like to do?

1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
4. Discard this work

Which option?
```

**Don't add explanation** — keep options concise.

### Step 4: Execute Choice

#### Option 1: Merge Locally

```bash
git checkout <base-branch>
git pull
git merge --no-ff <feature-branch>
```

Verify tests on merged result. Only after merge succeeds:

```bash
git branch -d <feature-branch>
```

#### Option 2: Push and Create PR

```bash
# Push branch
git push -u origin <feature-branch>

# Create PR
gh pr create --title "<title>" --body "$(cat <<'EOF'
## Summary
<2-3 bullets of what changed>

## Test Plan
- [ ] <verification steps>
EOF
)"
```

**Do NOT delete the branch** — user needs it alive to iterate on PR feedback.

#### Option 3: Keep As-Is

Report: "Keeping branch `<name>`. Ready to pick back up later."

Don't clean up anything.

#### Option 4: Discard

**Confirm first:**

```
This will permanently delete:
- Branch <name>
- All commits: <commit-list>

Type 'discard' to confirm.
```

Wait for exact confirmation. If confirmed:

```bash
git checkout <base-branch>
git branch -D <feature-branch>
```

## Quick Reference

| Option           | Merge | Push | Keep Branch | Cleanup       |
| ---------------- | ----- | ---- | ----------- | ------------- |
| 1. Merge locally | yes   | —    | —           | delete branch |
| 2. Create PR     | —     | yes  | yes         | —             |
| 3. Keep as-is    | —     | —    | yes         | —             |
| 4. Discard       | —     | —    | —           | force delete  |

## Common Mistakes

**Skipping test verification**

- **Problem:** Merge broken code, create failing PR
- **Fix:** Always verify tests before offering options

**Open-ended questions**

- **Problem:** "What should I do next?" is ambiguous
- **Fix:** Present exactly 4 structured options

**Deleting branch for Option 2**

- **Problem:** Remove branch user needs for PR iteration
- **Fix:** Only cleanup for Options 1 and 4

**No confirmation for discard**

- **Problem:** Accidentally delete work
- **Fix:** Require typed "discard" confirmation

## Red Flags

**Never:**

- Proceed with failing tests
- Merge without verifying tests on result
- Delete work without confirmation
- Force-push without explicit request

**Always:**

- Verify tests before offering options
- Present exactly 4 options
- Get typed confirmation for Option 4
- Use `--no-ff` for merge to preserve branch history
