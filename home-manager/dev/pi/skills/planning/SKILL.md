---
name: planning
description: Use when creating implementation plans. Breaks work into small, verifiable steps with exact file paths and verification commands. Use after brainstorming approval.
---

# Planning

## When to Use

- After a design has been approved (brainstorming complete)
- When asked to implement something non-trivial
- When breaking down a large task

## Process

### 1. Survey the Codebase

Before planning, understand:
- Existing code structure and patterns
- Related files and dependencies
- Test infrastructure
- Build system

### 2. Create the Plan

Use the `plan` tool to create a structured plan:

```
plan create:
  name: "descriptive-name"
  goal: "One sentence describing what we're building"
  steps:
    - description: "Exact action to take"
      files: ["path/to/file.ts"]
      verification: "command to verify this step"
```

### Step Requirements

Each step must be:
- **Small**: 2-5 minutes of work
- **Specific**: exact file paths, exact changes
- **Verifiable**: a command that proves it worked
- **Independent**: completable and verifiable on its own

### Banned in Steps

- ❌ "TODO" or "TBD"
- ❌ "similar to step N"
- ❌ "update the other files accordingly"
- ❌ "etc." or "and so on"
- ❌ Vague descriptions like "refactor the module"

### Good Step Examples

```
Step 1: Create the auth middleware type
  Files: src/middleware/auth.ts
  Action: Create AuthMiddleware interface with validate() method
  Verify: npx tsc --noEmit

Step 2: Write tests for auth middleware
  Files: src/middleware/__tests__/auth.test.ts
  Action: Test validate() with valid token, expired token, missing token
  Verify: npx vitest run auth.test.ts

Step 3: Implement auth middleware
  Files: src/middleware/auth.ts
  Action: Implement validate() using jwt.verify()
  Verify: npx vitest run auth.test.ts
```

### 3. Review the Plan

Before executing:
- Does each step have a verification command?
- Are the steps in dependency order?
- Is each step small enough?
- Are all file paths correct?

### 4. Execute

Use `plan update-step` to track progress as you work:
- Mark steps `in-progress` when starting
- Mark steps `done` with verification output in notes
- Mark steps `failed` with the error in notes

## Red Flags — Rationalizations to Watch For

| Excuse | Why It's Wrong | Do This Instead |
|--------|---------------|------------------|
| "I'll just do it, no plan needed" | Unplanned work leads to rework and missed steps | Even a 3-step plan is better than none |
| "The plan is in my head" | Invisible plans can't be reviewed or tracked | Write it down with the `plan` tool |
| "This step is too small to track" | Small steps compound into lost progress | Track every step — it takes seconds |
| "I'll fill in the details as I go" | Vague steps lead to vague implementations | Be specific now, not later |
| "The verification is obvious" | If it's obvious, it's easy to write down | Write the command explicitly |
| "I'll add more steps if needed" | Plans should be complete before execution | Plan fully, then execute. Add steps only when new requirements emerge |

## Rules

- Every step MUST have a verification command
- Steps must be in dependency order
- No step should take more than 5 minutes
- If a step is too big, split it with `plan add-step`
- Update step status as you work — don't batch updates
