---
name: brainstorming
description: Use when starting a new feature, design change, or architecture decision. Explores approaches and tradeoffs before planning or coding. NEVER skip this for non-trivial work.
---

# Brainstorming Ideas Into Designs

Help turn ideas into fully formed designs through natural collaborative dialogue.

Start by understanding the current project context, then ask questions one at a time to refine the idea. Once you understand what you're building, present the design and get user approval.

<HARD-GATE>
Do NOT write any code, scaffold any project, or take any implementation action until you have presented a design and the user has approved it. This applies to EVERY project regardless of perceived simplicity.
</HARD-GATE>

## Anti-Pattern: "This Is Too Simple To Need A Design"

Every project goes through this process. A todo list, a single-function utility, a config change — all of them. "Simple" projects are where unexamined assumptions cause the most wasted work. The design can be short (a few sentences for truly simple projects), but you MUST present it and get approval.

## Checklist

You MUST complete these in order:

1. **Explore project context** — check files, docs, recent commits
2. **Ask clarifying questions** — one at a time, understand purpose/constraints/success criteria
3. **Propose 2-3 approaches** — with trade-offs and your recommendation
4. **Present design** — in sections scaled to their complexity, get user approval after each section
5. **Write design doc** (if significant) — save to `docs/specs/YYYY-MM-DD-<topic>-design.md`
6. **Spec self-review** — check for placeholders, contradictions, ambiguity, scope (see below)
7. **User reviews written spec** — ask user to review before proceeding
8. **Transition to planning** — load the planning skill to create the implementation plan

## The Process

### Understanding the idea

- Check out the current project state first (files, docs, recent commits)
- Before asking detailed questions, assess scope: if the request describes multiple independent subsystems (e.g., "build a platform with chat, file storage, billing, and analytics"), flag this immediately. Don't spend questions refining details of a project that needs to be decomposed first.
- If the project is too large for a single spec, help the user decompose into sub-projects: what are the independent pieces, how do they relate, what order should they be built? Then brainstorm the first sub-project through the normal design flow. Each sub-project gets its own spec → plan → implementation cycle.
- For appropriately-scoped projects, ask questions one at a time to refine the idea
- Prefer multiple choice questions when possible, but open-ended is fine too
- Only one question per message — if a topic needs more exploration, break it into multiple questions
- Focus on understanding: purpose, constraints, success criteria

### Exploring approaches

- Propose 2-3 different approaches with trade-offs
- Present options conversationally with your recommendation and reasoning
- Lead with your recommended option and explain why

### Presenting the design

- Once you believe you understand what you're building, present the design
- Scale each section to its complexity: a few sentences if straightforward, up to 200-300 words if nuanced
- Ask after each section whether it looks right so far
- Cover: architecture, components, data flow, error handling, testing
- Be ready to go back and clarify if something doesn't make sense

### Design for isolation and clarity

- Break the system into smaller units that each have one clear purpose, communicate through well-defined interfaces, and can be understood and tested independently
- For each unit, you should be able to answer: what does it do, how do you use it, and what does it depend on?
- Can someone understand what a unit does without reading its internals? Can you change the internals without breaking consumers? If not, the boundaries need work.
- Smaller, well-bounded units are also easier for you to work with — you reason better about code you can hold in context at once, and your edits are more reliable when files are focused. When a file grows large, that's often a signal that it's doing too much.

### Working in existing codebases

- Explore the current structure before proposing changes. Follow existing patterns.
- Where existing code has problems that affect the work (e.g., a file that's grown too large, unclear boundaries, tangled responsibilities), include targeted improvements as part of the design — the way a good developer improves code they're working in.
- Don't propose unrelated refactoring. Stay focused on what serves the current goal.

## Spec Self-Review

After writing the spec document, look at it with fresh eyes:

1. **Placeholder scan:** Any "TBD", "TODO", incomplete sections, or vague requirements? Fix them.
2. **Internal consistency:** Do any sections contradict each other? Does the architecture match the feature descriptions?
3. **Scope check:** Is this focused enough for a single implementation plan, or does it need decomposition?
4. **Ambiguity check:** Could any requirement be interpreted two different ways? If so, pick one and make it explicit.

Fix any issues inline. No need to re-review — just fix and move on.

## After the Design

**Documentation (for significant designs):**

- Write the validated design to `docs/specs/YYYY-MM-DD-<topic>-design.md`
- Commit the design document to git

**User Review Gate:**

After the spec review loop passes, ask the user to review the written spec:

> "Spec written and committed to `<path>`. Please review it and let me know if you want to make any changes before we start writing out the implementation plan."

Wait for the user's response. If they request changes, make them and re-run the spec review loop. Only proceed once the user approves.

**Implementation:**

- Load the planning skill to create a detailed implementation plan
- Do NOT jump to implementation. Planning is the next step.

## Key Principles

- **One question at a time** — Don't overwhelm with multiple questions
- **Multiple choice preferred** — Easier to answer than open-ended when possible
- **YAGNI ruthlessly** — Remove unnecessary features from all designs
- **Explore alternatives** — Always propose 2-3 approaches before settling
- **Incremental validation** — Present design, get approval before moving on
- **Be flexible** — Go back and clarify when something doesn't make sense

## Red Flags — Rationalizations to Watch For

| Excuse                                              | Why It's Wrong                                                        | Do This Instead                                              |
| --------------------------------------------------- | --------------------------------------------------------------------- | ------------------------------------------------------------ |
| "I already know the best approach"                  | Confidence ≠ correctness. Explore alternatives                        | Present at least 2 approaches, even if one is clearly better |
| "There's only one way to do this"                   | There's almost never only one way                                     | Think harder. Different tradeoffs exist                      |
| "Let me just prototype and we'll see"               | Prototyping without design leads to commitment to bad approaches      | Design first, then prototype the chosen approach             |
| "This is too simple for a design"                   | Simple projects are where unexamined assumptions cause the most waste | Short design is fine. No design is not.                      |
| "The user just wants it done"                       | Instructions say WHAT, not HOW. "Add X" doesn't mean skip design.     | Design quickly, but design.                                  |
| "I'll figure out the details during implementation" | Details discovered late cause rework                                  | Nail down the important details now                          |

## Rules

- **NO CODE** during brainstorming. Design docs and pseudocode only.
- One question at a time. Wait for answers.
- Don't skip brainstorming because "it's obvious" — even obvious solutions benefit from exploring alternatives.
- The human must explicitly approve before moving to planning.
- If you're in the brainstorming workflow phase, use `/advance` when the design is approved.
