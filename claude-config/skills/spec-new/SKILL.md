---
name: spec-new
description: Plan and scaffold a new wsNN spec (requirements/design/tasks) for a feature, and register it in the project's execution plan (central by default, or its existing local plan).
argument-hint: "<feature description>"
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(find:*), Bash(mkdir:*), Bash(git remote:*)
---

# New Spec

Create a spec for: **$ARGUMENTS**

Repo remote (for slug resolution):
!`git remote get-url origin 2>/dev/null || true`

Local planning tree, if this repo has one:
!`find .claude/planning -maxdepth 3 -type f 2>/dev/null || true`

## Steps
1. **Resolve the project slug and plan root.**
   - Slug = the git remote origin repo name, lowercased (basename of the URL above, minus `.git`); if there's no remote, use the current directory's basename.
   - If `.claude/planning/` exists in this repo (see above), that's the plan root — **use it** (this project is `location: local` in the REGISTRY; mention migration to `~/.claude/planning/<slug>/` is available but don't do it here).
   - Otherwise the plan root is `~/.claude/planning/<slug>/` (`location: central`). If it doesn't exist yet, create it from the templates at `~/.claude/skills/setup-project/templates/planning/` (`EXECUTION_PLAN.md`, `SPEC_INDEX.md`) and fill in the project North Star.
   - Read `~/.claude/planning/REGISTRY.md`. If there's no row for this slug (or the location disagrees), add/update one: `| <slug> | <absolute repo path> | central|local | <one-line description> |`.
2. **Number it.** Determine the next `wsNN` from existing specs / the index in the plan root.
3. **Design first (use plan mode for anything non-trivial).** Explore the codebase and any relevant `.claude/knowledge/<topic>/` notes in this repo (research lives there, versioned with the code — specs reference it, they don't restate it), then author the three files in `<plan-root>/specs/<area>/wsNN-<short-name>/` from the templates at `~/.claude/skills/spec-new/templates/`:
   - `requirements.md` — user story + EARS acceptance criteria (SHALL/WHEN/IF…THEN), each mapped to a test.
   - `design.md` — interfaces/signatures, data model, numbered correctness properties (P1, P2…), testing strategy, and links to the `.claude/knowledge/` files it draws on.
   - `tasks.md` — numbered `N.M` tasks, **tests created alongside code**, final "Spec Finalization & Release" task. No optional tasks.
4. **Register it.** Add a workstream row to `<plan-root>/EXECUTION_PLAN.md` (id, name, points, deps, wave, status 📋) and a row to `<plan-root>/SPEC_INDEX.md` (status 📋); refresh "What Can Start Right Now".
5. **Report** the spec path, its dependencies, which wave it belongs to, and the plan's location (central/local). Don't implement yet — that's `/spec-run`.
