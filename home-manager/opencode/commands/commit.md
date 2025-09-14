---
name: commit
description: Commit using the current git state
agent: git
subtask: true
---

Here is the *current git status**
!`git status`

Here is the **current git diff (staged and unstaged changes)**
!`git diff --no-ext-diff HEAD | tr @ _`

Here are the **recent commits **
!`git log --oneline -10`

Using the above context create a conventional commit message and commit the changes using the `git commit` command.
