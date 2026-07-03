---
name: spec-run
description: Implement a spec end-to-end — plan-mode design, parallel coder fan-out per wave, validator-gated completion, finalize, and update the execution plan.
argument-hint: "<spec id e.g. ws42 — omit to take the next unblocked spec>"
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Agent, TaskCreate, TaskUpdate
---

# Run Spec

Target: **$ARGUMENTS** (if omitted, pick the next unblocked spec from `SPEC_INDEX.md`).

Repo remote (for slug resolution):
!`git remote get-url origin 2>/dev/null || true`

Local planning tree, if this repo has one:
!`find .claude/planning -maxdepth 3 -name '*.md' 2>/dev/null || true`

## Steps
1. **Resolve the plan root.** Slug = git remote origin repo name, lowercased; else the directory basename. If `.claude/planning/` exists locally (see above), that's the plan root (`location: local`); otherwise it's `~/.claude/planning/<slug>/` (`location: central` — check `~/.claude/planning/REGISTRY.md` and add the row if missing). Load the target spec's `requirements.md`, `design.md`, `tasks.md` from `<plan-root>/specs/<area>/wsNN-*/`. Confirm every dependency is ✅ in `SPEC_INDEX.md` — if not, stop and report the blocker.
2. **Load context.** Read any `.claude/knowledge/<topic>/` files the spec references (project-local, not in the plan) — don't re-derive research the knowledge base already has.
3. **Mark in progress.** Set the spec's status to 🔨 in `<plan-root>/SPEC_INDEX.md`.
4. **Design pass.** In plan mode, confirm the implementation approach against the design's interfaces and correctness properties (P1, P2…). Decompose `tasks.md` into **waves of independent leaves** — no two leaves in the same wave touch the same file; sequence waves by dependency. Mirror the leaves onto the native task board (`TaskCreate`, one per leaf, `blockedBy` for cross-wave dependencies) so state survives across turns — the markdown `tasks.md`/`SPEC_INDEX.md` stay the durable cross-session record.
5. **Execute in waves.** For each wave, spawn one `coder` subagent (Sonnet 5) per leaf **via the Agent tool, in parallel, in a single message** — a self-contained prompt: files to touch, acceptance criteria, the knowledge files to read first, test expectations. (In an `ultracode` session the Workflow tool may drive the same shape instead.) After each leaf completes, run the `validator` subagent at **targeted** level, mark the task done (`TaskUpdate`) and tick the checkbox; fix and re-run on failure before moving on.
6. **Milestone gate.** After each wave (and always before a commit), run `validator` at **full** level (lint + typecheck + all tests + coverage + build). Do **not** proceed until it returns PASSED.
7. **Forward-propagate.** Apply any discovered changes to affected future specs immediately, with a dated comment.
8. **Finalize.** Complete the spec's finalization task (version bump, `CHANGELOG.md`, commit). If pushing, run the release gate and verify CI is healthy with `/ci-check` — a push isn't done until deploy is green.
9. **Close out.** Update `<plan-root>/SPEC_INDEX.md` → ✅ (or 🔴 with reason) and `EXECUTION_PLAN.md`; refresh "What Can Start Right Now". Report the outcome, what's now unblocked, and confirm the `REGISTRY.md` row is current.
