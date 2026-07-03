---
description: Commit (and push, if a remote exists) the ~/.claude global config repo
argument-hint: "[optional commit message]"
allowed-tools: Bash(git -C ~/.claude:*)
---

Commit the global Claude config in `~/.claude`.

Current status:
!`git -C ~/.claude status --short`

Steps:
1. Stage everything: `git -C ~/.claude add -A`
2. Commit with message `config: $ARGUMENTS` (if no message was given, write a concise message summarizing the staged changes).
3. If a remote named `origin` exists (`git -C ~/.claude remote`), push: `git -C ~/.claude push`. If there is no remote, skip the push and report that no remote is configured yet.

Report the commit hash and whether a push happened.
