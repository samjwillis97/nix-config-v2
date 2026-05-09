---
name: dispatching-parallel-agents
description: Use when considering parallel execution of multiple tasks. Guides when to parallelise vs sequence, how to partition work, and how to handle partial failures.
---

# Dispatching Parallel Agents

## When to Use

- Multiple plan steps are independent
- Multiple files need similar changes
- Multiple reviews or investigations can run concurrently

## Decision: Parallel vs Sequential

### Use Parallel When

- Tasks touch **different files** with no overlap
- Tasks have **no data dependencies** (output of one isn't input to another)
- Tasks have **no ordering requirements**
- Tasks are **similar in scope** (one won't take 10x longer than others)

### Use Sequential When

- Tasks share files (even reading — concurrent reads with writes cause confusion)
- Later tasks depend on earlier task output
- Tasks modify shared state (database, config, environment)
- You're unsure — **sequential is always safe, parallel is an optimisation**

### Never Parallelise

- Test writing + implementation of the same feature
- Refactoring + new feature in the same module
- Multiple steps that touch the same file
- Anything where merge conflicts are likely

## How to Partition

### Good Partitions

```
# Independent modules
tasks:
  - agent: worker, task: "Add validation to user module"
  - agent: worker, task: "Add validation to payment module"

# Independent tests
tasks:
  - agent: worker, task: "Write tests for auth middleware"
  - agent: worker, task: "Write tests for rate limiter"

# Independent investigations
tasks:
  - agent: scout, task: "Investigate how auth works in this codebase"
  - agent: scout, task: "Investigate how the database layer works"
```

### Bad Partitions

```
# Shared files — will conflict
tasks:
  - agent: worker, task: "Add field to User type"       # touches user.ts
  - agent: worker, task: "Add validation to User type"   # also touches user.ts

# Data dependency — step 2 needs step 1's output
tasks:
  - agent: worker, task: "Create the API endpoint"
  - agent: worker, task: "Write integration tests for the API endpoint"
```

## Handling Results

### All Succeeded
Verify the combined result makes sense — parallel workers don't see each other's changes. Check for:
- Duplicate imports or declarations
- Inconsistent naming (one worker chose `userId`, another chose `user_id`)
- Missing integration between the parallel pieces

### Partial Failure
1. Review what succeeded — is it usable standalone?
2. Understand why the failure happened — is it a dependency you missed?
3. Decide:
   - Retry the failed task with more context
   - Re-plan as sequential with the successful output as context
   - Roll back if the pieces don't work independently

### Concurrency Limits

- Maximum 4 concurrent subagents (more causes resource contention)
- If you have 8 tasks, batch them: 4, then 4
- Prefer fewer parallel tasks with clear boundaries over many small ones

## Rules

- When in doubt, go sequential
- Never parallelise tasks that share files
- Review combined output for integration issues
- Keep parallel batches to 4 or fewer
- Each parallel task must be fully self-contained with its own context
