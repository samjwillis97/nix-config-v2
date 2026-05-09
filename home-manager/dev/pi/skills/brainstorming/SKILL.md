---
name: brainstorming
description: Use when starting a new feature, design change, or architecture decision. Explores approaches and tradeoffs before planning or coding. NEVER skip this for non-trivial work.
---

# Brainstorming

## When to Use

- New feature requests
- Architecture or design changes
- Refactoring decisions
- Any work where the approach isn't obvious

## Process

### 1. Understand the Problem

Ask clarifying questions **one at a time**. Don't overwhelm with a list of 10 questions.

Focus on:
- What problem does this solve?
- Who/what is affected?
- What are the constraints?

### 2. Explore Approaches

Present **2-3 concrete approaches** with tradeoffs:

```
## Approach A: [Name]
- How it works: ...
- Pros: ...
- Cons: ...
- Effort: low/medium/high

## Approach B: [Name]
- How it works: ...
- Pros: ...
- Cons: ...
- Effort: low/medium/high
```

### 3. Recommend

State which approach you'd recommend and why. Be specific about the tradeoffs.

### 4. Get Approval

Wait for the human to approve an approach before proceeding. Do NOT start coding.

### 5. Document (for significant designs)

Write a design doc to `docs/specs/`:

```
docs/specs/YYYY-MM-DD-<topic>-design.md
```

Include: problem statement, chosen approach, key decisions, open questions.

For smaller features, this is optional — a verbal discussion is sufficient.

## Red Flags — Rationalizations to Watch For

| Excuse | Why It's Wrong | Do This Instead |
|--------|---------------|------------------|
| "It's simple enough to just code" | Simple problems often have non-obvious tradeoffs | Brainstorm — it takes 2 minutes for simple things |
| "I already know the best approach" | Confidence ≠ correctness. Explore alternatives | Present at least 2 approaches, even if one is clearly better |
| "The user seems to want it done quickly" | Rushing leads to rework. Design is faster long-term | Brainstorm briefly — even 3 bullet points per approach helps |
| "There's only one way to do this" | There's almost never only one way | Think harder. Different tradeoffs exist |
| "Let me just prototype and we'll see" | Prototyping without design leads to commitment to bad approaches | Design first, then prototype the chosen approach |
| "This is just a config/style/naming change" | If it doesn't need design, it doesn't need this skill — but be honest about whether it really is trivial | Skip brainstorming only for truly mechanical changes |

## Rules

- **NO CODE** during brainstorming. Design docs and pseudocode only.
- One question at a time. Wait for answers.
- Don't skip brainstorming because "it's obvious" — even obvious solutions benefit from exploring alternatives.
- The human partner must explicitly approve before moving to planning.
- If you're in the brainstorming workflow phase, use `/advance` when the design is approved.
