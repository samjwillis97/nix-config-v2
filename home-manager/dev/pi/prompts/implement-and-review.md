---
description: Worker implements, two-stage review (spec + quality), worker applies feedback
argument-hint: "<task description>"
---
Use the subagent tool with the chain parameter to execute this workflow:

1. First, use the "worker" agent to implement: $@
2. Then, use the "spec-reviewer" agent to check the implementation from the previous step for spec compliance (use {previous} placeholder). Verify ALL requirements were met — do NOT trust the worker's self-report, read the actual code.
3. Then, use the "reviewer" agent to review code quality from the previous steps (use {previous} placeholder). Categorise issues as Critical / Important / Minor.
4. Finally, use the "worker" agent to apply the feedback from the reviews (use {previous} placeholder)

Execute this as a chain, passing output between steps via {previous}.
