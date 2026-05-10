---
name: writing-skills
description: Use when creating new skills for the agent. Follows a test-driven approach - observe failure without the skill, write the skill, then verify it closes the gap.
---

# Writing Skills

## Overview

**Writing skills IS Test-Driven Development applied to process documentation.**

You write test cases (pressure scenarios with subagents), watch them fail (baseline behavior), write the skill (documentation), watch tests pass (agents comply), and refactor (close loopholes).

**Core principle:** If you didn't watch an agent fail without the skill, you don't know if the skill teaches the right thing.

## What is a Skill?

A **skill** is a reference guide for proven techniques, patterns, or tools. Skills help future agent instances find and apply effective approaches.

**Skills are:** Reusable techniques, patterns, tools, reference guides.

**Skills are NOT:** Narratives about how you solved a problem once.

## Skill Types

### Technique

Concrete method with steps to follow (root-cause-tracing, condition-based-waiting).

### Pattern

Way of thinking about problems (design for isolation, fail-fast).

### Reference

API docs, syntax guides, tool documentation.

## When to Create

**Create when:**

- Technique wasn't intuitively obvious to you
- You'd reference this again across projects
- Pattern applies broadly (not project-specific)
- Others would benefit

**Don't create for:**

- One-off solutions
- Standard practices well-documented elsewhere
- Project-specific conventions (put in AGENTS.md)
- Mechanical constraints (if it's enforceable with regex/validation, automate it — save documentation for judgment calls)

## Directory Structure

```
skills/
  skill-name/
    SKILL.md              # Main reference (required)
    supporting-file.*     # Only if needed
```

**Flat namespace** — all skills in one searchable namespace.

**Separate files for:**

1. **Heavy reference** (100+ lines) — API docs, comprehensive syntax
2. **Reusable tools** — Scripts, utilities, templates

**Keep inline:**

- Principles and concepts
- Code patterns (< 50 lines)
- Everything else

## SKILL.md Structure

**Frontmatter (YAML):**

- Two required fields: `name` and `description`
- `name`: Use letters, numbers, and hyphens only (no parentheses, special chars)
- `description`: Third-person, describes ONLY when to use (NOT what it does)
  - Start with "Use when..." to focus on triggering conditions
  - **NEVER summarize the skill's process or workflow**
  - Keep under 500 characters if possible

```markdown
---
name: skill-name
description: Use when [specific triggering conditions]
---

# Skill Name

## Overview

What is this? Core principle in 1-2 sentences.

## When to Use

Bullet list with SYMPTOMS and use cases.
When NOT to use.

## Core Pattern

Before/after code comparison.

## Quick Reference

Table or bullets for scanning common operations.

## Common Mistakes

What goes wrong + fixes.
```

## Search Optimization (CSO)

### Rich Description Field

**CRITICAL: Description = When to Use, NOT What the Skill Does.**

Testing revealed that when a description summarizes the skill's workflow, the agent may follow the description instead of reading the full skill content. A description saying "code review between tasks" caused the agent to do ONE review, even though the skill's content clearly showed TWO reviews (spec compliance then code quality).

When the description was changed to just "Use when executing implementation plans with independent tasks" (no workflow summary), the agent correctly read the full content and followed the two-stage review process.

**The trap:** Descriptions that summarize workflow create a shortcut the agent will take. The skill body becomes documentation it skips.

```yaml
# ❌ BAD: Summarizes workflow — agent may follow this instead of reading skill
description: Use when executing plans - dispatches subagent per task with code review between tasks

# ❌ BAD: Too much process detail
description: Use for TDD - write test first, watch it fail, write minimal code, refactor

# ✅ GOOD: Just triggering conditions, no workflow summary
description: Use when executing implementation plans with independent tasks in the current session

# ✅ GOOD: Triggering conditions only
description: Use when implementing any feature or bugfix, before writing implementation code
```

### Keyword Coverage

Use words the agent would search for:

- Error messages: "Hook timed out", "ENOTEMPTY", "race condition"
- Symptoms: "flaky", "hanging", "zombie", "pollution"
- Synonyms: "timeout/hang/freeze", "cleanup/teardown/afterEach"
- Tools: Actual commands, library names, file types

### Descriptive Naming

**Use active voice, verb-first:**

- ✅ `creating-skills` not `skill-creation`
- ✅ `condition-based-waiting` not `async-test-helpers`

**Gerunds (-ing) work well for processes:**

- `creating-skills`, `testing-skills`, `debugging-with-logs`

## TDD for Skills (RED-GREEN-REFACTOR)

### The Iron Law

```
NO SKILL WITHOUT A FAILING TEST FIRST
```

This applies to NEW skills AND EDITS to existing skills. Write skill before testing? Delete it. Start over.

### RED: Write Failing Test (Baseline)

Run pressure scenario with subagent WITHOUT the skill. Document exact behavior:

- What choices did they make?
- What rationalizations did they use (verbatim)?
- Which pressures triggered violations?

This is "watch the test fail" — you must see what agents naturally do before writing the skill.

### GREEN: Write Minimal Skill

Write skill that addresses those specific rationalizations. Don't add extra content for hypothetical cases.

Run same scenarios WITH skill. Agent should now comply.

### REFACTOR: Close Loopholes

Agent found new rationalization? Add explicit counter. Re-test until bulletproof.

## Bulletproofing Against Rationalization

Skills that enforce discipline (like TDD, verification) need to resist rationalization. Agents are smart and will find loopholes when under pressure.

### Close Every Loophole Explicitly

Don't just state the rule — forbid specific workarounds:

```
Bad:  "Write code before test? Delete it."

Good: "Write code before test? Delete it. Start over.
       - Don't keep it as 'reference'
       - Don't 'adapt' it while writing tests
       - Don't look at it
       - Delete means delete"
```

### Address "Spirit vs Letter" Arguments

Add foundational principle early:

```
Violating the letter of the rules is violating the spirit of the rules.
```

This cuts off the entire class of "I'm following the spirit" rationalizations.

### Build Rationalization Table

Capture rationalizations from baseline testing. Every excuse agents make goes in the table:

```markdown
| Excuse               | Reality                                    |
| -------------------- | ------------------------------------------ |
| "Too simple to test" | Simple code breaks. Test takes 30 seconds. |
| "I'll test after"    | Tests passing immediately prove nothing.   |
```

### Create Red Flags List

Make it easy for agents to self-check when rationalizing.

## Testing Methodology

Different skill types need different test approaches:

### Discipline-Enforcing Skills (rules/requirements)

**Test with:**

- Academic questions: Do they understand the rules?
- Pressure scenarios: Do they comply under stress?
- Multiple pressures combined: time + sunk cost + exhaustion

**Success criteria:** Agent follows rule under maximum pressure.

### Technique Skills (how-to guides)

**Test with:**

- Application scenarios: Can they apply the technique correctly?
- Variation scenarios: Do they handle edge cases?
- Missing information tests: Do instructions have gaps?

**Success criteria:** Agent successfully applies technique to new scenario.

### Pattern Skills (mental models)

**Test with:**

- Recognition scenarios: Do they recognize when pattern applies?
- Application scenarios: Can they use the mental model?
- Counter-examples: Do they know when NOT to apply?

**Success criteria:** Agent correctly identifies when/how to apply pattern.

### Reference Skills (documentation/APIs)

**Test with:**

- Retrieval scenarios: Can they find the right information?
- Application scenarios: Can they use what they found correctly?
- Gap testing: Are common use cases covered?

**Success criteria:** Agent finds and correctly applies reference information.

## Common Rationalizations for Skipping Testing

| Excuse                         | Reality                                                          |
| ------------------------------ | ---------------------------------------------------------------- |
| "Skill is obviously clear"     | Clear to you ≠ clear to other agents. Test it.                   |
| "It's just a reference"        | References can have gaps, unclear sections. Test retrieval.      |
| "Testing is overkill"          | Untested skills have issues. Always. 15 min testing saves hours. |
| "I'll test if problems emerge" | Problems = agents can't use skill. Test BEFORE deploying.        |
| "Too tedious to test"          | Testing is less tedious than debugging bad skill in production.  |
| "No time to test"              | Deploying untested skill wastes more time fixing it later.       |

## Anti-Patterns

- ❌ **Narrative Example:** "In session 2025-10-03, we found empty projectDir caused..." — too specific, not reusable
- ❌ **Multi-Language Dilution:** example-js.js, example-py.py, example-go.go — mediocre quality, maintenance burden
- ❌ **Generic Labels:** helper1, helper2, step3, pattern4 — labels should have semantic meaning

## Skill Creation Checklist

**RED Phase — Write Failing Test:**

- [ ] Create pressure scenarios (3+ combined pressures for discipline skills)
- [ ] Run scenarios WITHOUT skill — document baseline behavior verbatim
- [ ] Identify patterns in rationalizations/failures

**GREEN Phase — Write Minimal Skill:**

- [ ] Name uses only letters, numbers, hyphens
- [ ] YAML frontmatter with required `name` and `description` fields
- [ ] Description starts with "Use when..." and includes specific triggers/symptoms
- [ ] Description written in third person
- [ ] Keywords throughout for search (errors, symptoms, tools)
- [ ] Clear overview with core principle
- [ ] Address specific baseline failures identified in RED
- [ ] One excellent example (not multi-language)
- [ ] Run scenarios WITH skill — verify agents now comply

**REFACTOR Phase — Close Loopholes:**

- [ ] Identify NEW rationalizations from testing
- [ ] Add explicit counters (if discipline skill)
- [ ] Build rationalization table from all test iterations
- [ ] Create red flags list
- [ ] Re-test until bulletproof

**Quality Checks:**

- [ ] Quick reference table
- [ ] Common mistakes section
- [ ] No narrative storytelling
- [ ] Supporting files only for tools or heavy reference

**Deployment:**

- [ ] Commit skill to git
