---
description: Stage changes and create a well-formed commit
argument-hint: "[scope or hint]"
---
Review the current changes with `git diff` and `git diff --cached`, then create a commit:

1. Check `git status` to see what's changed
2. Stage the appropriate files — group related changes into one logical commit
3. Write a commit message following the conventional format:
   ```
   <type>: <short description>

   <body explaining what and why>
   ```
   Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`
4. Do NOT commit if tests are failing — run them first
5. Do NOT commit debug logging, commented-out code, or TODO comments without tracking

$@
