---
name: systematic-debugging
description: Use when fixing bugs, investigating errors, or diagnosing unexpected behavior. Enforces root-cause analysis over guess-and-check. MUST use after 2+ failed fix attempts.
---

# Systematic Debugging

## When to Use

- Bug reports or error investigation
- Tests failing unexpectedly
- Behavior doesn't match expectations
- You've already tried a fix and it didn't work

## The 4 Phases

### Phase 1: Root Cause Investigation

**DO NOT GUESS.** Trace the error backward:

1. **Read the actual error** — full stack trace, not just the message
2. **Find the origin** — trace backward through the call chain
3. **Reproduce** — run a command that triggers the error consistently
4. **Understand** — explain WHY the error occurs, not just WHERE

Questions to answer:
- What is the exact error?
- What triggers it?
- When did it start? (git log, git bisect)
- What changed recently?

### Phase 2: Pattern Analysis

Is this error systemic or isolated?

- Are there similar patterns elsewhere in the code?
- Is this a symptom of a deeper design issue?
- Are there related errors that share a root cause?

### Phase 3: Hypothesis Testing

Form a hypothesis and test it **before** writing a fix:

1. State your hypothesis clearly: "The error occurs because X"
2. Predict what you'll see if the hypothesis is correct
3. Run a test/command that validates the hypothesis
4. If wrong, form a new hypothesis — don't force the fix

### Phase 4: Implementation

Only after confirming the root cause:

1. Write the fix
2. Write a regression test that would have caught this
3. Run the full test suite
4. Verify the original error is gone

## Escalation Rules

After **3 failed fix attempts** for the same error:

🔴 **STOP.** Do not try another fix.

Instead:
1. List what you've tried and why each failed
2. Question your assumptions:
   - Is the error where you think it is?
   - Are you fixing the root cause or a symptom?
   - Is there a design problem that makes this unfixable with patches?
3. Consider:
   - Reading more of the codebase for context
   - Checking git history for when this worked
   - Looking at the problem from a different angle
   - Asking the human partner for guidance

## Supporting Techniques

### Root-Cause Tracing

```
Error at line N in file.ts
  ← Called by function Y in caller.ts
    ← Called by handler Z in entry.ts
      ← Triggered by [event/request/input]

Root cause: [the actual origin, not just the crash site]
```

### Defense in Depth

Validate at every layer:
- Entry point: validate input
- Business logic: assert preconditions
- Data layer: check return values
- Environment: verify external state

### Condition-Based Waiting

When dealing with async/timing issues:
- Never use `sleep()` or `setTimeout()` as fixes
- Poll for the actual condition to be true
- Set a reasonable timeout with clear error messages

## Red Flags — Rationalizations to Watch For

| Excuse | Why It's Wrong | Do This Instead |
|--------|---------------|------------------|
| "I think I know what's wrong" | Thinking ≠ knowing. Investigate first | Reproduce the error, then trace the root cause |
| "Let me try a quick fix" | Quick fixes without understanding cause more bugs | Understand the cause BEFORE writing a fix |
| "It's probably a typo/config issue" | Maybe, but verify. Don't guess at categories | Find the actual error and trace it |
| "I'll just add a null check" | Defensive coding hides bugs, doesn't fix them | Find WHY it's null and fix the source |
| "The error message says X so the fix is Y" | Error messages can be misleading | Trace the actual execution path |
| "Let me try reverting and redoing" | If you don't understand why it broke, you'll break it the same way | Understand first, then fix |
| "This is taking too long, let me try something different" | Random pivots waste more time | Follow the 4 phases. If stuck, escalate |

## Rules

- NEVER guess at fixes — investigate first
- ALWAYS reproduce before fixing
- ONE change at a time — don't batch fixes
- Run tests after EVERY change
- If it's not working after 3 tries, STOP and rethink
