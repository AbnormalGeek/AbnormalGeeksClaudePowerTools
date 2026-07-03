# Plan-Driven Workflow

This project's execution plan lives centrally at `~/.claude/planning/<slug>/`
(slug = this repo's git remote origin name, lowercased, else its directory
basename — see `~/.claude/planning/REGISTRY.md`), unless this repo still has a
legacy local `.claude/planning/` tree, in which case that's the active plan
until migrated (never auto-migrated — see `/setup-project` step 6a). Research
is different: it stays project-local at `.claude/knowledge/<topic>/` (index at
`.claude/knowledge/INDEX.md`), versioned with the code — specs reference it,
they don't restate it. Full conventions: `~/.claude/rules/agentic-development.md`.

## At session start
Read `SPEC_INDEX.md` (status + what's unblocked) and `EXECUTION_PLAN.md`
(authoritative workstreams, dependencies, waves) from the plan location above.

## Working a spec
- Pick the next unblocked spec (all dependencies ✅). Drive it with `/spec-run <id>`; create new specs with `/spec-new <feature>`; check the board with `/spec-status`.
- **Design in plan mode** against the spec's interfaces + correctness properties before editing.
- **Fan out** independent leaves as parallel `coder` subagents (Sonnet 5, via the Agent tool), one wave at a time, gated by `validator` (`targeted` per leaf, `full` per milestone/before commit). Track leaves on the native task board (`TaskCreate`/`TaskUpdate`, `blockedBy` dependencies) alongside the markdown checkboxes — the markdown stays the durable cross-session record.
- **Tests are created in the same task as the code they cover** — never optional, never deferred.

## Gates & discipline
- **Completion gate:** the `validator` subagent must pass (lint/typecheck/test/coverage/build) before a spec is marked ✅.
- **A push triggers deploy** → not done until CI is healthy (`/ci-check`).
- **Forward propagation:** if implementing a spec reveals a change needed in a future spec, update that spec's files immediately with `<!-- Updated YYYY-MM-DD: reason -->`.
- Keep `SPEC_INDEX.md` (⬜→🔨 at dispatch, →✅ when validated, →🔴 if blocked) and `EXECUTION_PLAN.md` current as you go.
- **No optional tasks.** Every spec ends with a finalization task (version bump, changelog, commit, push).
