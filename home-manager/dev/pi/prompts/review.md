---
description: Two-stage code review - spec compliance then code quality
argument-hint: "[target]"
---
Use the subagent tool with a chain to perform a two-stage review:

1. First, use the "spec-reviewer" agent: Review the recent changes for spec compliance. Check that all requirements were met, nothing is missing, and nothing extra was added. Do NOT trust any self-reported status — read the actual code. Target: ${@:1} (or recent changes if not specified).

2. Then, use the "reviewer" agent: Based on the spec compliance review from the previous step (use {previous} placeholder), if spec compliance passed, perform a code quality review. Check architecture, error handling, edge cases, test coverage, and DRY violations. Categorize issues as Critical / Important / Minor.

Execute this as a chain, passing output between steps via {previous}.
