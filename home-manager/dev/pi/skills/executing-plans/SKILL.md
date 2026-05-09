---
name: executing-plans
description: Use when executing an implementation plan. Each step is delegated to a fresh subagent for isolated context, then reviewed before proceeding. Do NOT execute plans inline — use subagents.
---

# Executing Plans via Subagents

## When to Use

- You have a plan (from the `plan` tool or written out) and need to execute it
- Any multi-step implementation task

## Why Subagents?

Executing plan steps inline pollutes your context window with implementation details. Instead:
- **You** are the orchestrator — curate context, dispatch, review
- **Worker subagents** implement each step with fresh context
- **Reviewer subagents** verify each step before you move on

This keeps your context clean for orchestration decisions.

## Process

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

### 3. Review the Result

After each step, check the worker's output:
- Did it report DONE? Read the actual verification output, don't trust the summary.
- Did it report BLOCKED? Understand why before retrying or adjusting the plan.
- Did it report NEEDS_CONTEXT? Provide what's missing and re-dispatch.

For critical steps, dispatch a review:

```
agent: "spec-reviewer"
task: |
  The following step was just implemented: [step description]
  Requirements were: [requirements]
  Worker reported: [worker output]

  Verify the implementation matches the requirements.
  Read the actual code — do NOT trust the worker's report.
```

### 4. Update Plan Status

After reviewing, update the plan:
```
plan update-step:
  stepId: N
  status: "done"  (or "failed")
  notes: "Verification output: [paste key results]"
```

### 5. Continue Without Asking

**Do NOT pause between steps to ask "should I continue?"**

Keep executing steps sequentially unless:
- A step reports BLOCKED
- A review finds Critical issues
- You need human input on a design decision

If none of those apply, proceed to the next step immediately.

## When to Use Parallel Dispatch

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

| Excuse | Why It's Wrong | Do This Instead |
|--------|---------------|-----------------|
| "I'll just do this step inline, it's small" | Small steps still pollute context | Dispatch it — subagents are cheap |
| "I don't need to review this step" | Errors compound; catch them early | At minimum, read the worker's output critically |
| "I'll review everything at the end" | Late review means expensive rework | Review per step, not per plan |
| "The worker said DONE so it's fine" | Workers report optimistically | Check the verification output yourself |
| "I'll batch the plan updates later" | You'll forget or get confused | Update status after each step |
| "Let me ask the user if I should continue" | Interruptions break flow | Continue unless BLOCKED or need design input |

## Rules

- Every plan step gets its own subagent — never execute steps inline
- Curate context per step — don't dump the whole plan on each worker
- Review before marking done — read verification output, not just status
- Update plan status after every step
- Keep going unless blocked — don't ask permission between steps
- Parallelise only when steps are truly independent
