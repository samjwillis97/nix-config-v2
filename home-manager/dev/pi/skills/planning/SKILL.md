---
name: planning
description: Use when creating implementation plans. Breaks work into small, verifiable steps with exact file paths and verification commands. Use after brainstorming approval.
---

# Writing Plans

## Overview

Write comprehensive implementation plans assuming the implementer has zero context for the codebase and questionable taste. Document everything they need to know: which files to touch for each task, code, testing, docs they might need to check, how to test it. Give them the whole plan as bite-sized tasks. DRY. YAGNI. Frequent commits.

Assume they are a skilled developer, but know almost nothing about the toolset or problem domain.

## When to Use

- After a design has been approved (brainstorming complete)
- When asked to implement something non-trivial
- When breaking down a large task

## Process

### 1. Survey the Codebase

Before planning, understand:

- Existing code structure and patterns
- Related files and dependencies
- Test infrastructure (does it exist? what framework? what areas are covered?)
- Build system

### 2. Scope Check

If the spec covers multiple independent subsystems, it should have been broken into sub-project specs during brainstorming. If it wasn't, suggest breaking this into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

### 3. File Structure

Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.

- Design units with clear boundaries and well-defined interfaces. Each file should have one clear responsibility.
- You reason best about code you can hold in context at once, and your edits are more reliable when files are focused. Prefer smaller, focused files over large ones that do too much.
- Files that change together should live together. Split by responsibility, not by technical layer.
- In existing codebases, follow established patterns. If the codebase uses large files, don't unilaterally restructure — but if a file you're modifying has grown unwieldy, including a split in the plan is reasonable.

This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.

### 4. Create the Plan

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

## Bite-Sized Task Granularity

**Each step is one action (2-5 minutes):**

- "Write the failing test" — step
- "Run it to make sure it fails" — step
- "Implement the minimal code to make the test pass" — step
- "Run the tests and make sure they pass" — step
- "Commit" — step

## Step Requirements

Each step must be:

- **Small**: 2-5 minutes of work
- **Specific**: exact file paths, exact changes
- **Verifiable**: a command that proves it worked
- **Independent**: completable and verifiable on its own

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

## No Placeholders

Every step must contain the actual content an implementer needs. These are **plan failures** — never write them:

- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" (without actual test structure)
- "Similar to step N" (repeat the content — the implementer may read tasks out of order)
- Steps that describe what to do without showing how
- "Update the other files accordingly"
- "etc." or "and so on"
- References to types, functions, or methods not defined in any task
- Vague descriptions like "refactor the module"

## Plan Self-Review

After writing the complete plan, check it against the spec. This is a checklist you run yourself — not a subagent dispatch.

**1. Spec coverage:** Skim each section/requirement in the spec. Can you point to a task that implements it? List any gaps.

**2. Placeholder scan:** Search your plan for red flags — any of the patterns from the "No Placeholders" section above. Fix them.

**3. Type consistency:** Do the types, method signatures, and property names you used in later tasks match what you defined in earlier tasks? A function called `clearLayers()` in Task 3 but `clearFullLayers()` in Task 7 is a bug.

If you find issues, fix them inline. No need to re-review — just fix and move on. If you find a spec requirement with no task, add the task.

## Execution Handoff

After creating the plan, offer execution choice:

**"Plan complete. Two execution options:**

**1. Subagent-Driven (recommended)** — I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** — Execute tasks in this session, batch execution with checkpoints

**Which approach?"**

If Subagent-Driven chosen: Load the executing-plans skill.

## Red Flags — Rationalizations to Watch For

| Excuse                               | Why It's Wrong                                | Do This Instead                                                       |
| ------------------------------------ | --------------------------------------------- | --------------------------------------------------------------------- |
| "The plan is in my head"             | Invisible plans can't be reviewed or tracked  | Write it down with the `plan` tool                                    |
| "I'll fill in the details as I go"   | Vague steps lead to vague implementations     | Be specific now, not later                                            |
| "The verification is obvious"        | If it's obvious, it's easy to write down      | Write the command explicitly                                          |
| "I'll add more steps if needed"      | Plans should be complete before execution     | Plan fully, then execute. Add steps only when new requirements emerge |
| "This step is self-explanatory"      | Every step needs explicit how, not just what  | Show the code or command                                              |
| "The implementer will figure it out" | They shouldn't have to. That's the plan's job | Be explicit                                                           |

## Rules

- Every step MUST have a verification command
- Steps must be in dependency order
- No step should take more than 5 minutes
- If a step is too big, split it with `plan add-step`
- No placeholders — every step contains actual content
- Self-review the plan against the spec before finalising
- Update step status as you work — don't batch updates
