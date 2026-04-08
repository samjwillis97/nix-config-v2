---
name: address-pr-comments
description: Use when evaluating and addressing unresolved PR review comments, before implementing any fixes from code review feedback on a pull request
---

# Address PR Comments

## Overview

Systematically evaluate unresolved PR review comments, determine which are valid and worth addressing, create an implementation plan, and wait for user confirmation before making changes.

**Core principle:** Evaluate before acting. Not all review comments are worth implementing -- assess each on technical merit before committing to changes.

## Process Flow

```
1. FETCH    — Get all unresolved review comments from the PR
2. EVALUATE — Assess each comment for validity and merit
3. PLAN     — Create an actionable plan for valid comments
4. CONFIRM  — Present plan and wait for user approval
5. IMPLEMENT — Execute approved changes
```

## Step 1: Identify the PR

Determine the PR number:
- If a PR number was provided as an argument, use it
- Otherwise, detect from the current branch:

```bash
gh pr view --json number --jq '.number'
```

If no PR is found, stop and ask the user for the PR number.

## Step 2: Fetch Unresolved Comments

Retrieve all review comments on the PR:

```bash
# Get PR review comments (not issue comments)
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments --paginate
```

Filter to unresolved comments only. A comment is unresolved if it is NOT part of a resolved review thread. Check thread resolution status:

```bash
# Get review threads via GraphQL
gh api graphql -f query='
  query($owner: String!, $repo: String!, $pr: Int!) {
    repository(owner: $owner, name: $repo) {
      pullRequest(number: $pr) {
        reviewDecision
        reviews(last: 50) {
          nodes {
            author { login }
            state
            body
          }
        }
        reviewThreads(first: 100) {
          nodes {
            isResolved
            isOutdated
            path
            line
            comments(first: 20) {
              nodes {
                author { login }
                body
                createdAt
              }
            }
          }
        }
      }
    }
  }
' -f owner='{owner}' -f repo='{repo}' -F pr={pr_number}
```

**Important:** Only process threads where `isResolved: false`. Skip resolved and outdated threads.

## Step 3: Evaluate Each Comment

For each unresolved comment thread, read the relevant code and evaluate:

### Assessment Criteria

| Criteria | Question |
|----------|----------|
| **Correctness** | Does the reviewer identify a genuine bug or issue? |
| **Relevance** | Is this comment about code changed in this PR, or pre-existing? |
| **Specificity** | Is the request clear and actionable? |
| **Merit** | Does the suggestion improve the code (readability, performance, safety)? |
| **Scope** | Is this in-scope for the PR, or scope creep? |
| **Codebase fit** | Does the suggestion fit the patterns and conventions of this codebase? |

### Categorize Each Comment

Assign each comment one of these categories:

- **Address** — Valid, actionable, and in-scope. Should be fixed.
- **Discuss** — Has merit but needs clarification, is ambiguous, or the reviewer may be missing context. Needs discussion before implementing.
- **Decline** — Out of scope, technically incorrect, or conflicts with existing codebase patterns. Should be declined with reasoning.
- **Already resolved** — The concern has been addressed in a subsequent commit or the code has changed.

### Evaluation Rules

```
IF comment identifies a real bug or correctness issue:
  → Address (always fix bugs)

IF comment is a style/preference disagreement with no objective improvement:
  → Decline (unless it aligns with established codebase conventions)

IF comment suggests a refactor that's unrelated to the PR's purpose:
  → Decline (scope creep)

IF comment is unclear or you can't determine what change is requested:
  → Discuss (ask for clarification)

IF comment points out a valid improvement but you disagree on approach:
  → Discuss (propose alternative)

IF reviewer lacks context about why the code is written a certain way:
  → Discuss (explain context, ask if they still want the change)
```

## Step 4: Present the Plan

Present findings to the user in this format:

```
## PR #<number> — Comment Evaluation

### Address (<count>)
For each:
- **File:** <path>:<line>
- **Reviewer:** <author>
- **Comment:** <summary>
- **Assessment:** <why this should be addressed>
- **Proposed fix:** <what you'll change>

### Discuss (<count>)
For each:
- **File:** <path>:<line>
- **Reviewer:** <author>
- **Comment:** <summary>
- **Concern:** <what needs clarification>
- **Suggested response:** <draft reply to reviewer>

### Decline (<count>)
For each:
- **File:** <path>:<line>
- **Reviewer:** <author>
- **Comment:** <summary>
- **Reason:** <why this should be declined>
- **Suggested response:** <draft reply to reviewer>

### Already Resolved (<count>)
For each:
- **File:** <path>:<line>
- **Comment:** <summary>
- **Resolution:** <how/when it was resolved>
```

After presenting, ask:

> "Review the plan above. You can:
> 1. Approve all — I'll implement the 'Address' items and post replies for 'Discuss' and 'Decline' items
> 2. Approve with changes — tell me which items to recategorize
> 3. Pick specific items — tell me which items to address
>
> What would you like to do?"

**STOP and wait for user confirmation. Do NOT implement anything until the user responds.**

## Step 5: Implement Approved Changes

After user confirmation:

1. Implement each approved fix one at a time
2. After each fix, verify it doesn't break anything (run tests if applicable)
3. For "Discuss" items the user approved replying to, post the reply as a review comment in the thread
4. For "Decline" items the user approved replying to, post the reply as a review comment in the thread

To reply in a thread:
```bash
# Reply to a review comment thread
gh api repos/{owner}/{repo}/pulls/{pr_number}/comments/{comment_id}/replies \
  -f body='<reply text>'
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Implementing before user confirms | Always wait for explicit approval |
| Treating all comments as valid | Evaluate each on merit — decline scope creep |
| Missing unresolved threads | Use GraphQL to check thread resolution status |
| Fixing code not in the PR diff | Only address comments about code changed in this PR |
| Blind agreement with reviewer | Evaluate technically — push back when warranted |
| Forgetting to reply to declined items | Draft courteous replies explaining the reasoning |

## Red Flags — STOP

- About to implement a change without user approval
- Agreeing with a comment you haven't verified against the code
- Addressing a comment about code outside the PR's scope
- Making changes without checking thread resolution status first
