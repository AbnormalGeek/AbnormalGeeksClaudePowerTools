---
name: spec-status
description: Show the project's execution-plan status board and what's unblocked to start next.
argument-hint: ""
disable-model-invocation: true
allowed-tools: Read, Glob, Bash(find:*), Bash(git remote:*)
---

# Spec Status

Repo remote (for slug resolution):
!`git remote get-url origin 2>/dev/null || true`

Local planning tree, if this repo has one:
!`find .claude/planning -maxdepth 3 -name '*.md' 2>/dev/null || true`

Resolve the plan root: slug = git remote origin repo name, lowercased, else the
current directory's basename. If a local `.claude/planning/` tree exists (see
above), read `SPEC_INDEX.md`/`EXECUTION_PLAN.md` from there directly (`location:
local`). Otherwise read them from `~/.claude/planning/<slug>/` (`location:
central` — check `~/.claude/planning/REGISTRY.md` for the slug if unsure).

Report:
- Each spec's status (⬜ 📋 🔨 ✅ 🔴).
- **What's unblocked right now** — specs whose dependencies are all ✅.
- Anything 🔴 blocked, and why.
- Suggested next action.

If there's no plan at either location, say so and suggest running `/setup-project` (to scaffold it) or `/spec-new` (to start the first spec).

$ARGUMENTS
