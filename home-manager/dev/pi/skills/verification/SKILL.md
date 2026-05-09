---
name: verification
description: Use before claiming any work is complete. Ensures actual verification evidence exists - tests run, builds pass, behavior confirmed. No hedging.
---

# Verification Before Completion

## When to Use

- Before saying "done", "complete", "finished", "implemented", "fixed"
- Before any completion claim whatsoever
- Always. Every time. No exceptions.

## Requirements

Before claiming completion, you MUST have:

### 1. Test Evidence

Run the relevant tests and show the output:
```bash
# Run the test suite
npm test
# or the specific tests
npx vitest run path/to/test.ts
```

Show the actual output. "Tests pass" without output is NOT sufficient.

### 2. Build Evidence (if applicable)

```bash
npm run build
# or
cargo build
# or
nix build
```

### 3. Behavioral Evidence

Demonstrate the change works:
- For API changes: curl/httpie showing the response
- For CLI changes: run the command, show output
- For UI changes: describe what you see, or take a screenshot
- For config changes: show the config is loaded correctly

### 4. Regression Check

Verify you didn't break existing functionality:
- Run the full test suite, not just new tests
- Check related features still work

## Banned Language

These phrases are NOT allowed in completion claims:

| ❌ Don't say | ✅ Say instead |
|---|---|
| "should work" | "Tests pass: [output]" |
| "probably fine" | "Verified by running: [command]" |
| "I believe this is correct" | "Output confirms: [evidence]" |
| "seems to work" | "Tested with: [specific test]" |
| "likely works" | "All 14 tests pass: [output]" |
| "this should fix it" | "Error no longer reproduces: [output]" |

## Red Flags — Rationalizations to Watch For

| Excuse | Why It's Wrong | Do This Instead |
|--------|---------------|------------------|
| "I just ran the tests a few turns ago" | Stale evidence is not evidence | Run them again NOW, before claiming completion |
| "The change is too small to need verification" | Small changes can break things in surprising ways | Verify anyway — it takes seconds |
| "The tests would be the same as before" | You changed something — prove it still works | Run them and show output |
| "I can tell from the code it's correct" | Code review is not verification | Run it, don't read it |
| "There are no tests for this" | That's a problem, not an excuse | Write a test, or at minimum demonstrate the behaviour manually |
| "The build system is slow" | Slow builds still need to pass | Run it. Time doesn't exempt you from verification |

## Process

1. Run tests → paste output
2. Run build → paste output (if applicable)
3. Verify behavior → paste evidence
4. THEN say "Complete" with a summary referencing the evidence

## Rules

- No completion claims without fresh evidence from THIS turn
- Evidence must be from commands you ran, not from memory
- If tests fail, fix them before claiming completion
- If there are no tests, that's a problem — mention it
- Partial completion is fine: "Steps 1-3 complete (verified), step 4 remaining"
