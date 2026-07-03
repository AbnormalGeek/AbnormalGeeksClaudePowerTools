# How It Works — The Agentic Development System

This is the deep dive on the system installed by this repo: what each piece is, why it's shaped
that way, and how a feature actually flows through it. The enforceable rules live in the
installed `~/.claude/CLAUDE.md`; the full references live in `~/.claude/rules/` — this document
explains the system to you, the human running it.

## The core idea

One smart orchestrator, many cheap specialists, and code standards that make parallel work safe.

Your main session (ideally Fable 5 at `/effort ultracode`) never grinds through bulk work
itself — it decomposes, delegates to purpose-built subagents running cheaper models, and gates
everything through validation before calling anything done. The result is faster (parallel
waves), cheaper (right model per job), and more reliable (nothing is "done" until a validator
says so).

## The fleet (`~/.claude/agents/`)

| Agent | Model | Role |
|-------|-------|------|
| **project-manager** | fable | Orchestrator for features/products: decompose → research fan-out → central plan → parallel implementation waves → validation gates. Can spawn any other agent. |
| **researcher** | opus | Investigates one topic; verifies against **live sources**, never training data; writes findings to the project's `.claude/knowledge/<topic>/`. |
| **coder** | sonnet | One atomic implementation task: a single module/component/fix **plus its tests**, with a targeted test loop. Several run in parallel on independent files. |
| **distiller** | haiku | Parses/condenses large pages, files, logs, command output. Can offload huge inputs to a local LLM if you set one up (see [local-llm-offload.md](local-llm-offload.md)). |
| **validator** | haiku | The completion gate. `targeted` level per leaf, `full` per milestone. May add missing helper scripts (`test:related`, `validate`) to a project's package.json. |
| **context-keeper** | sonnet | Keeps CLAUDE.md, context files, and memory current; handles the config-repo git workflow. |

Plus `agents/domain-agent-template.md` — a commented template for building your own **domain
specialists** (an infra admin, a business-ops agent, whatever your life needs). The pattern:
one agent per durable domain, holding that domain's facts and runbooks in its prompt, pinned to
sonnet.

**Why models are pinned per agent:** the orchestrator needs the smartest model because
decomposition and synthesis are the hard parts. Research needs strong reasoning (opus).
Implementation of a well-specified leaf is sonnet territory. Condensing and gate-running are
mechanical (haiku). Agent frontmatter uses model **aliases** (`fable`, `opus`, `sonnet`,
`haiku`) that resolve to the latest version of each tier — never pin full model IDs unless you
need a specific version. Subagents can nest (an agent's `tools:` list controls what it may
spawn), and they inherit your full CLAUDE.md/memory hierarchy automatically — don't duplicate
global context in agent prompts.

## The pipeline (how a feature gets built)

1. **Intake** — your main session or `project-manager` receives the goal.
2. **Research fan-out** — the PM spawns one `researcher` per topic **in parallel**. Each
   verifies against live sources (docs, changelogs, `--help`), pulls in `distiller`s for bulk
   content, and writes organized markdown to the project's `.claude/knowledge/<topic>/`. The PM
   waits for all to complete.
3. **Plan** — the PM reads the research and creates/updates the project's central execution
   plan in `~/.claude/planning/<slug>/`. Work is decomposed into **independent, parallelizable
   leaves** with explicit dependencies.
4. **Execute in waves** — the PM fans out `coder` agents on independent leaves (parallel within
   a wave; waves ordered by dependency), tracking work on the native task board
   (`TaskCreate`/`TaskUpdate` with `blockedBy`) rather than hand-rolled markdown checkboxes.
5. **Gate** — every leaf ends with `validator` at **targeted** level. A milestone (a completed
   wave, before dependents build on it) gets `validator` at **full** level.
6. **Finalize** — update the execution plan and SPEC_INDEX, have `context-keeper` record
   durable facts, and commit green work (conventional commits, **no attribution trailers** —
   Golden Rule 0).

In an `ultracode` session the main loop may drive this same pipeline itself via the Workflow
tool (script-driven orchestration) instead of a PM subagent. The PM agent exists for delegating
the *whole* pipeline out of your main conversation.

## Central planning — `~/.claude/planning/<slug>/`

Plans are deliberately **not** stored in project repos: they're cross-session, cross-repo state
about work in flight, and they'd pollute project history.

- Each project gets `EXECUTION_PLAN.md` (authoritative status/decisions/next steps),
  `SPEC_INDEX.md` (the board), and `specs/` (one spec triad per workstream: requirements,
  design, tasks).
- **Project slug** = git remote origin repo name (lowercased), else directory basename.
- `~/.claude/planning/REGISTRY.md` maps every slug → absolute repo path → one-line description.
  It's the traceability link back to the repo and the collision check. This repo ships it as an
  empty table; the spec skills fill it in.
- The `/spec-new`, `/spec-run`, `/spec-status` skills operate on this layout.

## Project-local knowledge — `.claude/knowledge/`

Research findings live **with the code they explain**:

- Path: `<repo>/.claude/knowledge/<topic-kebab>/<NN>-<subtopic>.md`
- Each file starts with frontmatter: `date`, `sources` (URLs), `confidence`.
- `<repo>/.claude/knowledge/INDEX.md` lists every topic with a one-line hook — researchers
  append to it; the PM reads it first.
- Knowledge is versioned with the code because it explains *why the code is shaped the way it
  is*. Plans do **not** go here.

## Memory habits

Claude Code's auto-memory (`MEMORY.md` + topic files, per project directory) is treated as a
first-class part of the system:

- `MEMORY.md` is a lean **index**: one line per topic file with a hook describing what's inside.
- Each topic file holds one durable subject (a deployment's architecture, a tool's gotchas, a
  decision and its rationale) — not session logs.
- **What belongs in memory:** verified non-obvious facts that a future session would otherwise
  re-fetch or re-derive (API quirks, environment specifics, "we tried X, it failed because Y").
- **What belongs in the repo instead:** anything that explains the code (→ `.claude/knowledge/`)
  or configures behavior (→ `CLAUDE.md`/rules). Memory is for the assistant's continuity, not
  for documentation.
- The **Verify, Don't Assume** rule feeds this loop: anything versioned/living (model names,
  CLI flags, library APIs, pricing) is looked up live, and once verified, durable findings are
  saved to memory so the next session doesn't re-fetch.

## Skills (slash commands)

| Skill | What it does |
|-------|--------------|
| `/setup-project` | Drops the per-project scaffolding (rules, knowledge dir, project CLAUDE.md) into a repo |
| `/spec-new` | Creates a new spec triad in the central planning dir and registers the slug |
| `/spec-run` | Executes the next unblocked tasks from a spec, via the pipeline |
| `/spec-status` | Shows the board across specs/workstreams |
| `/ci-check` | Watches the latest CI run to completion — because a push triggers a deploy, a push isn't done until CI is green |
| `/sync-config` | Commits (and pushes) the `~/.claude` config repo |

## Validation levels

- **targeted** (default per coder leaf): `git diff --name-only` → run only related tests
  (`vitest related` / `jest --findRelatedTests` / `pytest <files>` / `go test <pkgs>`), lint
  changed files, typecheck.
- **full** (milestone gate + before any commit): the project's composite validate script —
  lint + typecheck + all tests with coverage + build.
- The validator may add missing helper scripts to `package.json` when a project lacks them.

This is what backs the Golden Rules: never declare work complete without validation passing,
and commit only when green.

## Why parallel agents don't collide: the code standards

Multi-agent work on one codebase is only safe if the code itself is parallelizable. The
installed engineering standards (full reference: `~/.claude/rules/testable-business-logic.md`)
are the enabler, not an afterthought:

- **Functional core, imperative shell** — all business logic lives in pure functions (plain
  data in, plain data out); all effects (DB, network, clock, randomness) live in a thin shell
  at the edges. Pure modules with narrow interfaces are exactly what independent agents can
  build concurrently without stepping on each other.
- **Dependency injection at the edges** — collaborators injected via constructor or a
  default-param seam, never constructed inside logic. Every module's dependencies are explicit,
  so a coder agent working on one leaf can't create hidden coupling to another.
- **One module per concern, no cross-cutting edits in a leaf.** If two leaves must touch the
  same file, they are one leaf — or two sequential waves.
- **Tests ship with the code, in the same leaf** — unit + property tests for the pure core,
  which the targeted validator can run in isolation.

## Escalation cheat sheet

- Default session: **Fable 5**; subagents carry their own tiers.
- `/effort ultracode` — session-only; maximum reasoning effort plus multi-agent Workflow
  orchestration for substantive jobs.
- `ultrathink` in any prompt — one-off deeper reasoning, no session change.
- Parallelize by default: independent leaves → one agent each, same message, concurrent.
  Cheap/bulk → haiku (or local LLM). Research → opus. Implementation → sonnet.
  Orchestration/hard synthesis → fable.
