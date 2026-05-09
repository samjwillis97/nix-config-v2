---
name: receiving-code-review
description: Use when you receive code review feedback (from a reviewer subagent, /review command, or human). Guides proper processing of feedback without dismissing or cherry-picking.
---

# Receiving Code Review

## When to Use

- After a reviewer subagent returns findings
- After `/review` command completes
- When the human provides code review feedback
- Any time someone points out issues in your code

## Process

### 1. Read Everything

Read ALL feedback before responding. Don't start fixing after the first issue.

Categorise what you received:
- **Critical**: Must fix before proceeding
- **Important**: Should fix, may require design changes
- **Minor**: Consider fixing, low risk either way

### 2. Acknowledge Without Defending

For each issue:
- ✅ "You're right, I missed that edge case. I'll fix it."
- ✅ "Good catch — the error handling is incomplete."
- ❌ "That's not really a problem because..."
- ❌ "I intentionally did it that way" (without explaining why)
- ❌ "That's out of scope" (unless it genuinely is, with explanation)

If you genuinely disagree, explain your reasoning concretely — but default to accepting the feedback.

### 3. Fix in Priority Order

1. All Critical issues first
2. Then Important issues
3. Then Minor issues (unless explicitly deprioritised)

For each fix:
- Make the change
- Run verification
- Note what you changed and why

### 4. Don't Introduce New Issues

When fixing review feedback:
- Only change what's needed for the fix
- Don't refactor adjacent code "while you're in there"
- Run the full test suite after fixes, not just the affected tests

### 5. Report Back

After addressing feedback:

```
## Review Feedback Addressed

### Critical
- [Issue]: Fixed by [change] in `file.ts:42`. Verified: [output]

### Important
- [Issue]: Fixed by [change]. Verified: [output]

### Minor
- [Issue]: Fixed / Deferred (reason)

### Verification
[Full test suite output]
```

## Red Flags — Rationalizations to Watch For

| Excuse | Why It's Wrong | Do This Instead |
|--------|---------------|-----------------|
| "That's a style preference" | If the reviewer flagged it, consider it | Discuss briefly, then defer to the reviewer |
| "It works fine as-is" | Working ≠ correct. Reviews catch subtle issues | Fix it unless you can prove it's a non-issue |
| "I'll fix that in a follow-up" | Follow-ups get forgotten | Fix it now unless it's truly a separate concern |
| "The reviewer doesn't understand the context" | Maybe, but assume they're right first | Re-read their feedback charitably |
| "These are all minor issues" | Don't downgrade severity to dismiss feedback | Accept the reviewer's categorisation |
| "I already considered that" | Then why is it in the code wrong? | Fix it and move on |

## Rules

- Read ALL feedback before starting fixes
- Default to accepting feedback — the reviewer caught something you missed
- Fix Critical issues before anything else
- Verify after every fix, not just at the end
- Don't scope-creep fixes — change only what's needed
- Report back with evidence, not just "fixed"
