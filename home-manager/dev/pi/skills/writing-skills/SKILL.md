---
name: writing-skills
description: Use when creating new skills for the agent. Follows a test-driven approach - observe failure without the skill, write the skill, then verify it closes the gap.
---

# Writing Skills

## When to Use

- Creating a new skill for a recurring workflow
- Improving an existing skill that agents bypass
- The human asks you to create a skill

## Skill Structure

```
skill-name/
├── SKILL.md              # Required: frontmatter + instructions
└── references/           # Optional: detailed docs loaded on-demand
    └── detailed-guide.md
```

### SKILL.md Format

```markdown
---
name: skill-name
description: Specific description of when to use this skill. Be detailed — this determines auto-loading.
---

# Skill Name

## When to Use
[Triggering conditions]

## Process
[Step-by-step instructions]

## Red Flags — Rationalizations to Watch For
[Table of excuses and counters]

## Rules
[Non-negotiable requirements]
```

### Naming Rules

- Lowercase letters, numbers, hyphens only
- No leading/trailing hyphens, no consecutive hyphens
- Must match parent directory name
- Max 64 characters

## Writing Process

### 1. Identify the Gap

What goes wrong without this skill? Be specific:
- "The agent jumps to implementation without exploring alternatives"
- "The agent claims completion without running tests"
- "The agent makes random fix attempts instead of investigating root causes"

### 2. Write the Description

The description is the most important part — it determines when the agent loads the skill. Be specific about triggers:

- ✅ "Use when fixing bugs, investigating errors, or diagnosing unexpected behavior. Enforces root-cause analysis."
- ❌ "Helps with debugging."

### 3. Write the Process

Step-by-step, specific, actionable. Each step should be:
- Clear enough that following it mechanically produces good results
- Ordered logically
- Verifiable

### 4. Add Anti-Rationalization Tables

This is what separates good skills from ignored skills. For each rule, anticipate HOW the agent will try to skip it:

```markdown
## Red Flags — Rationalizations to Watch For

| Excuse | Why It's Wrong | Do This Instead |
|--------|---------------|-----------------|
| "It's too simple for this" | Simple problems benefit from process too | Follow the process — it's fast for simple cases |
| "I already know the answer" | Confidence ≠ correctness | Verify your assumption with the process |
```

Think adversarially: if you were trying to skip this skill, what would you say?

### 5. Add Rules

Non-negotiable requirements. Keep them short and absolute:
- "NEVER do X without Y"
- "ALWAYS do Z before claiming completion"
- "If A happens, STOP and do B"

### 6. Test the Skill

Verify the skill works by using it. Check:
- Does the description trigger loading for the right tasks?
- Are the steps clear enough to follow mechanically?
- Are there rationalizations not covered by the red flags table?
- Does following the skill produce better outcomes?

## Skill Quality Checklist

- [ ] Name matches directory, follows naming rules
- [ ] Description is specific about when to use (not generic)
- [ ] Process has clear, numbered steps
- [ ] Each step is verifiable
- [ ] Red flags table covers at least 4-5 common rationalizations
- [ ] Rules section has absolute requirements
- [ ] References to other files use relative paths
- [ ] No vague language ("consider", "might want to", "optionally")

## Rules

- Skills are behavioural directives, not suggestions
- Every skill MUST have a red flags / rationalization table
- Descriptions must be specific enough to trigger auto-loading
- Test skills against real tasks before considering them done
- Place skills in the nix-config repo: `home-manager/dev/pi/skills/`
