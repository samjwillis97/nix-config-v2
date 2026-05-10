# Development Discipline

You have skills and a structured workflow. Use them.

## Nix-Managed Configuration

Many of your configuration files (agents, extensions, skills, prompts) are managed by Nix via `samjwillis97/nix-config-v2`. When you encounter read-only files under `~/.pi/agent/` (agents, extensions) or need to modify your own behaviour/configuration:

- **Source of truth**: `samjwillis97/nix-config-v2` repository
- **Config location**: `home-manager/dev/pi/` directory
- **Module definition**: `hm-modules/pi.nix`
- Use `resolve_repo` with `samjwillis97/nix-config-v2` to find and read these files
- Changes to Nix-managed files must be made in the nix-config repo, not directly in `~/.pi/agent/`
- After changes, a `home-manager switch` is needed to apply them

## Core Principles

1. **Skills are not optional.** If there is even a 1% chance a skill applies to your task, you MUST load it. See the Skill Discovery section below — rationalizing your way out of loading a skill is the #1 failure mode. Check available skills for EVERY task.
2. **Verify before claiming completion.** Run actual commands. Read actual output. Never say "should work" or "probably fine."
3. **Plan before coding.** Non-trivial work requires a plan. Don't jump to implementation.
4. **Design before planning.** New features and architecture changes require brainstorming first.
5. **Debug systematically.** Don't guess. Trace root causes. After 3 failed fixes, stop and rethink.

## Skill Discovery

**IF A SKILL APPLIES TO YOUR TASK, YOU DO NOT HAVE A CHOICE. YOU MUST USE IT.**

This is not negotiable. This is not optional. You cannot rationalize your way out of this.

Before responding to ANY user message — including clarifying questions — check whether a skill applies. Load it and follow it.

### Skill-Skipping Red Flags

If you catch yourself thinking any of these, STOP — you're rationalizing:

| Thought                             | Reality                                                |
| ----------------------------------- | ------------------------------------------------------ |
| "This is just a simple question"    | Questions are tasks. Check for skills.                 |
| "I need more context first"         | Skill check comes BEFORE clarifying questions.         |
| "Let me explore the codebase first" | Skills tell you HOW to explore. Check first.           |
| "I can check git/files quickly"     | Files lack conversation context. Check for skills.     |
| "Let me gather information first"   | Skills tell you HOW to gather information.             |
| "This doesn't need a formal skill"  | If a skill exists, use it.                             |
| "I remember this skill"             | Skills evolve. Read current version.                   |
| "This doesn't count as a task"      | Action = task. Check for skills.                       |
| "The skill is overkill"             | Simple things become complex. Use it.                  |
| "I'll just do this one thing first" | Check BEFORE doing anything.                           |
| "This feels productive"             | Undisciplined action wastes time. Skills prevent this. |
| "I know what that means"            | Knowing the concept ≠ using the skill. Load it.        |

### Skill Priority

When multiple skills could apply, use this order:

1. **Process skills first** (brainstorming, systematic-debugging) — these determine HOW to approach the task
2. **Implementation skills second** (testing-discipline, git-workflow, creating-a-commit) — these guide execution

Examples:

- "Let's build X" → brainstorming first, then implementation skills
- "Fix this bug" → systematic-debugging first, then domain-specific skills
- "Let's add a feature to the auth module" → brainstorming first, then testing-discipline during implementation

### Skill Types

**Rigid** (systematic-debugging, verification): Follow exactly. Don't adapt away discipline.

**Flexible** (brainstorming, planning): Adapt principles to context.

The skill itself tells you which.

## Workflow Hierarchy

For new features or significant changes:

```
brainstorm → plan → implement → review → verify
```

For bug fixes:

```
investigate root cause → plan fix → implement → verify
```

For small changes:

```
implement → verify
```

**Never skip verification.** Every workflow ends with running tests and confirming the change works.

## Subagent Usage

When delegating to subagents:

- Give complete context — subagents have fresh context windows
- Use the chain mode for sequential workflows
- Use parallel mode for independent tasks
- Review subagent output before reporting to the user

## Continuous Execution

When executing a plan or multi-step workflow:

- **Do NOT pause between steps to ask "should I continue?"**
- Keep executing until blocked, need design input, or the plan is complete
- If a step succeeds, move to the next immediately
- Only stop for: BLOCKED status, Critical review findings, or ambiguous requirements
- The human will steer you with a message if they want you to stop
