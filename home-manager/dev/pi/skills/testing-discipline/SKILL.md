---
name: testing-discipline
description: Use when implementing features or fixing bugs to determine whether tests should be written. Context-aware - scouts existing test infrastructure before deciding. Not all code needs tests.
---

# Testing Discipline

## Overview

Testing should be context-aware, not dogmatic. The decision to write tests depends on whether the project already has test infrastructure for the area you're working in.

**Core principle:** Match the project's existing testing culture. Add tests where tests exist. Don't scaffold test infrastructure where none was asked for.

## The Decision Flow

```
1. SCOUT: Does the project have test infrastructure?
2. ASSESS: Does this area have existing tests?
3. DECIDE: Based on context, should you write tests?
4. EXECUTE: If yes, follow TDD (red-green-refactor)
```

## Phase 1: Scout Test Infrastructure

Before writing any code, check what testing exists:

```bash
# Find test files
find . -name '*test*' -o -name '*spec*' -o -name '__tests__' | head -20

# Check for test frameworks in package.json / Cargo.toml / pyproject.toml
grep -i 'jest\|vitest\|mocha\|pytest\|cargo test\|go test' package.json Cargo.toml pyproject.toml 2>/dev/null

# Check for test scripts
grep -i 'test' package.json 2>/dev/null | head -5

# Count existing tests
find . -name '*.test.*' -o -name '*.spec.*' | wc -l
```

## Phase 2: Assess Testing Context

Based on what you found, classify the situation:

### Situation A: Tests exist for this area

The project has test infrastructure AND there are existing tests covering the area you're modifying (same module, same service, same layer).

**Action:** Follow TDD. Write tests. This is non-negotiable when the project already tests this area.

### Situation B: Tests exist elsewhere but not here

The project has test infrastructure, but the specific area you're working on has no tests.

**Action:** Use judgment:

- If you're adding a new module in a well-tested codebase → add tests (follow the pattern)
- If you're making a small change to an untested legacy area → don't add tests unless asked
- If you're adding a public API or service endpoint → add tests (these are boundaries)

### Situation C: No test infrastructure

The project has no test framework configured, no test files, no test scripts.

**Action:** Do NOT add tests. Do NOT scaffold a test framework. The human didn't ask for it, and adding test infrastructure is a significant decision that should be made deliberately, not as a side-effect of a feature.

### Situation D: Bug fix (any project)

You're fixing a bug, regardless of existing test infrastructure.

**Action:** Write a regression test IF test infrastructure exists for this area. Regression tests for bugs are high-value — they prove the fix works and prevent the bug from returning. If no test infrastructure exists, fix the bug and verify manually.

## Phase 3: Follow TDD (When Tests Are Expected)

When you've determined tests should be written, follow the red-green-refactor cycle:

### RED — Write Failing Test

Write one minimal test showing what should happen.

**Requirements:**

- One behavior per test
- Clear name describing the behavior
- Real code (no mocks unless unavoidable)

```typescript
test("rejects empty email", async () => {
  const result = await submitForm({ email: "" });
  expect(result.error).toBe("Email required");
});
```

### Verify RED — Watch It Fail

**MANDATORY. Never skip.**

Run the test. Confirm:

- Test fails (not errors)
- Failure message is expected
- Fails because feature is missing (not typos)

**Test passes?** You're testing existing behavior. Fix test.

### GREEN — Minimal Code

Write simplest code to pass the test. Don't add features, refactor other code, or "improve" beyond the test.

### Verify GREEN — Watch It Pass

Run the test. Confirm:

- Test passes
- Other tests still pass
- Output pristine (no errors, warnings)

**Test fails?** Fix code, not test.

### REFACTOR — Clean Up

After green only: remove duplication, improve names, extract helpers. Keep tests green. Don't add behavior.

### Repeat

Next failing test for next behavior.

## Quick Reference

| Situation                       | Tests Exist Here? | Infrastructure? | Action                      |
| ------------------------------- | ----------------- | --------------- | --------------------------- |
| Modifying tested module         | Yes               | Yes             | TDD (mandatory)             |
| New module in tested codebase   | No                | Yes             | Add tests (follow pattern)  |
| Small change to untested legacy | No                | Yes             | Skip unless asked           |
| New public API/endpoint         | No                | Yes             | Add tests (boundary)        |
| No test infrastructure at all   | No                | No              | Skip — don't scaffold       |
| Bug fix in tested area          | Yes               | Yes             | Regression test (mandatory) |
| Bug fix without test infra      | No                | No              | Skip — verify manually      |
| User explicitly asks for tests  | N/A               | N/A             | Always write tests          |

## Red Flags — Rationalizations to Watch For

| Excuse                                        | Reality                                                             |
| --------------------------------------------- | ------------------------------------------------------------------- |
| "Tests are always good"                       | Uninvited test scaffolding is scope creep                           |
| "TDD is dogmatic, I'm being pragmatic"        | TDD IS pragmatic when tests already exist for this area             |
| "I'll write tests after"                      | Tests-after prove nothing. If you're going to test, test first.     |
| "Tests slow me down"                          | Tests in a tested area catch bugs that would slow you down more     |
| "This is too simple to test"                  | If tests exist for similar code, test this too                      |
| "I need to add a test framework first"        | That's a separate decision. Don't bolt it on during feature work.   |
| "Manual testing is enough"                    | In a project with test infrastructure, automated tests are expected |
| "The existing tests are bad, mine won't help" | Follow existing patterns. Improve incrementally, not heroically.    |

## Common Testing Anti-Patterns

When writing tests, avoid:

- **Testing mock behavior instead of real behavior** — if you mock everything, you're testing your mocks
- **Adding test-only methods to production classes** — tests should use the public API
- **Snapshot tests for logic** — snapshots verify structure, not behavior. Use assertions for logic.
- **Testing implementation details** — test WHAT it does, not HOW it does it. Tests should survive refactoring.

## Rules

- Scout test infrastructure BEFORE deciding whether to test
- Follow the project's existing testing patterns
- When tests are warranted, follow TDD strictly (red-green-refactor)
- Never add test framework scaffolding as a side-effect of feature work
- Always write regression tests for bugs (when test infrastructure exists)
- If the human asks for tests, write tests — regardless of existing infrastructure
