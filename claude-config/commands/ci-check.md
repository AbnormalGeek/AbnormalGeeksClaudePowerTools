---
description: Watch the latest CI run for the current repo until it finishes (golden rule — a push is not done until deploy is healthy)
allowed-tools: Bash(gh run list:*), Bash(gh run watch:*), Bash(gh run view:*)
---

Enforce the golden rule: **a push is not done until CI/deploy is confirmed healthy.**

Latest runs:
!`gh run list --limit 5`

Steps:
1. Identify the most recent run for the current branch.
2. Watch it to completion: `gh run watch <run-id>` (or `gh run watch` for the latest).
3. If it **fails**, pull the failing logs: `gh run view <run-id> --log-failed`, then summarize the failure and the likely fix. Do NOT consider the work done.
4. If it **passes**, confirm the deploy is healthy and report success.

$ARGUMENTS
