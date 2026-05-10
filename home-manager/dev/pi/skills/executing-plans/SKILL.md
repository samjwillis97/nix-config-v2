---
name: executing-plans
description: Use when executing an implementation plan. Each step is delegated to a fresh subagent for isolated context, then reviewed before proceeding. Do NOT execute plans inline — use subagents.
---

# Executing Plans via Subagents

## Overview

Execute plan by dispatching fresh subagent per task, with review after each.

**Core principle:** Fresh subagent per task + review = high quality, fast iteration.

**Continuous execution:** Do not pause to check in with the human between tasks. Execute all tasks from the plan without stopping. The only reasons to stop are: BLOCKED status you cannot resolve, ambiguity that genuinely prevents progress, or all tasks complete. "Should I continue?" prompts waste time — they asked you to execute the plan, so execute it.

## When to Use

- You have a plan (from the `plan` tool or written out) and need to execute it
- Any multi-step implementation task

## Why Subagents?

Executing plan steps inline pollutes your context window with implementation details. Instead:

- **You** are the orchestrator — curate context, dispatch, review
- **Worker subagents** implement each step with fresh context
- **Reviewer subagents** verify each step before you move on

This keeps your context clean for orchestration decisions.

## The Process

### 1. Prepare Context Per Step

Before dispatching each step, curate exactly what the subagent needs:

- The step description from the plan
- Relevant file paths and their current state
- Any output from previous steps that's needed
- Project conventions (test commands, build commands)

**Do NOT** just paste the entire plan. Give each subagent only its step.

### 2. Dispatch Worker

Use the `subagent` tool in single mode:

```
agent: "worker"
task: |
  Task: [step description from plan]

  Context:
  - Project uses [framework], tests run with [command]
  - Related files: [list relevant files]
  - Previous step output: [if relevant]

  Requirements:
  - [specific requirements for this step]
  - Run verification: [verification command from plan]
  - Report status: DONE / DONE_WITH_CONCERNS / BLOCKED / NEEDS_CONTEXT
```

### 3. Handle Worker Status

Worker subagents report one of four statuses. Handle each appropriately:

**DONE:** Proceed to review. Read the actual verification output — don't trust the summary.

**DONE_WITH_CONCERNS:** The worker completed the work but flagged doubts. Read the concerns before proceeding. If concerns are about correctness or scope, address them before review. If they're observations (e.g., "this file is getting large"), note them and proceed to review.

**NEEDS_CONTEXT:** The worker needs information that wasn't provided. Provide the missing context and re-dispatch.

**BLOCKED:** The worker cannot complete the task. Assess the blocker:

1. If it's a context problem, provide more context and re-dispatch
2. If the task requires more reasoning, consider breaking it into smaller pieces
3. If the plan itself is wrong, escalate to the human

**Never** ignore an escalation or force the same approach to retry without changes. If the worker said it's stuck, something needs to change.

### 4. Review

For critical steps, dispatch a spec-reviewer:

```
agent: "spec-reviewer"
task: |
  The following step was just implemented: [step description]
  Requirements were: [requirements]
  Worker reported: [worker output]

  Verify the implementation matches the requirements.
  Read the actual code — do NOT trust the worker's report.
```

**If reviewer finds issues:**

- Dispatch worker to fix
- Reviewer reviews again
- Repeat until approved
- Don't skip the re-review

### 5. Update Plan Status

After reviewing, update the plan:

```
plan update-step:
  stepId: N
  status: "done"  (or "failed")
  notes: "Verification output: [paste key results]"
```

### 6. Continue Without Asking

**Do NOT pause between steps to ask "should I continue?"**

Keep executing steps sequentially unless:

- A step reports BLOCKED
- A review finds Critical issues
- You need human input on a design decision

If none of those apply, proceed to the next step immediately.

## Model Selection

Use the least powerful model that can handle each role to conserve cost and increase speed.

**Mechanical implementation tasks** (isolated functions, clear specs, 1-2 files): use a fast, cheap model. Most implementation tasks are mechanical when the plan is well-specified.

**Integration and judgment tasks** (multi-file coordination, pattern matching, debugging): use a standard model.

**Architecture, design, and review tasks**: use the most capable available model.

**Task complexity signals:**

- Touches 1-2 files with a complete spec → cheap model
- Touches multiple files with integration concerns → standard model
- Requires design judgment or broad codebase understanding → most capable model

## Parallel Dispatch

If multiple steps are independent (no shared files, no dependency), dispatch them in parallel:

```
subagent parallel:
  tasks:
    - agent: "worker", task: "Step 3: ..."
    - agent: "worker", task: "Step 4: ..."
```

Only parallelise when steps have:

- No overlapping files
- No data dependencies
- No ordering requirements

When in doubt, execute sequentially.

## Red Flags — Rationalizations to Watch For

| Excuse                                      | Why It's Wrong                             | Do This Instead                                 |
| ------------------------------------------- | ------------------------------------------ | ----------------------------------------------- |
| "I'll just do this step inline, it's small" | Small steps still pollute context          | Dispatch it — subagents are cheap               |
| "I don't need to review this step"          | Errors compound; catch them early          | At minimum, read the worker's output critically |
| "I'll review everything at the end"         | Late review means expensive rework         | Review per step, not per plan                   |
| "The worker said DONE so it's fine"         | Workers report optimistically              | Check the verification output yourself          |
| "I'll batch the plan updates later"         | You'll forget or get confused              | Update status after each step                   |
| "Let me ask the user if I should continue"  | Interruptions break flow                   | Continue unless BLOCKED or need design input    |
| "Close enough on spec compliance"           | Spec issues compound downstream            | Spec reviewer found issues = not done           |
| "I'll skip the re-review"                   | Reviewer found issues = fix = review again | Always re-review after fixes                    |

## Rules

- Every plan step gets its own subagent — never execute steps inline
- Curate context per step — don't dump the whole plan on each worker
- Review before marking done — read verification output, not just status
- Update plan status after every step
- Keep going unless blocked — don't ask permission between steps
- Parallelise only when steps are truly independent
- Handle all four worker statuses explicitly
