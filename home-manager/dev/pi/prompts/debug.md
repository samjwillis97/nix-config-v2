---
description: Systematically debug an issue - root cause analysis, not guessing
argument-hint: "<problem description>"
---
Use the subagent tool with a chain to debug this issue:

1. First, use the "scout" agent to investigate: Find all code relevant to this issue: $@. Look for the root cause, not just the symptoms. Check error messages, stack traces, recent git changes, and related test files.

2. Then, use the "worker" agent to fix the issue based on the investigation from the previous step (use {previous} placeholder). Follow systematic debugging:
   - Reproduce the error first
   - Fix the root cause, not a symptom
   - Write a regression test
   - Verify the fix with the full test suite
   - If stuck after 3 attempts, report BLOCKED

Execute this as a chain, passing output between steps via {previous}.
