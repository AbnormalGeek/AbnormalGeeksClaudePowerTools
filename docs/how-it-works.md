# How It Works — The Agentic Development System (v2: "the web")

This is the deep dive on the system installed by this repo: what each piece is, why it's shaped
that way, and how a feature actually flows through it. The enforceable rules live in the
installed `~/.claude/CLAUDE.md`; the full references live in `~/.claude/rules/` — this document
explains the system to you, the human running it.

## The core idea

One smart orchestrator, a **self-extending web** of cheap specialists, and code standards that
make parallel work safe.

Your main session (ideally Fable 5 at `/effort ultracode`) never grinds through bulk work
itself — it decomposes, delegates to purpose-built subagents running cheaper models, and gates
everything through validation before calling anything done. What's new in v2 is that the fleet
is no longer fixed: an agent whose whole job is designing and installing new agents
(`agent-smith`) means the roster grows to fit your work instead of you working around a fixed
roster. The result is faster (parallel waves), cheaper (right model per job), more reliable
(nothing is "done" until a validator says so), and it gets better fitted to your workflow over
time instead of staying static.

## Orchestrator context discipline (the non-negotiable rule)

This is rule #1 of the fleet and the single idea everything else supports:

> Top-level and orchestrator contexts do planning, sequencing, judgment, gating, and commits —
> nothing else. ALL reading, research, scanning, implementation, and validation go to subagents
> that return conclusions, never raw dumps.

If your top-level session is reading a file, grepping a codebase, or watching test output
scroll by, that's a leaf you skipped delegating. The orchestrator's context is the scarcest,
most expensive resource in the system — protect it by construction, not by discipline you have
to remember every time.

## The four tiers

Every agent in the shipped fleet sits in exactly one tier, picked by task shape, not by
familiarity:

| Tier | Model | Shape | Shipped agents |
|------|-------|-------|-----------------|
| **Orchestrator** | Fable | Orchestration, synthesis, creation | `project-manager`, `agent-smith` |
| **Specialist** | Opus | Deep research / domain brain | `researcher`, `agent-forge` |
| **Dev / ops** | Sonnet | Implementation, one atomic leaf | `coder`, `java-dev`, `python-dev`, `ts-dev`, `git-ops`, `config-editor`, `context-keeper`, `domain-agent-template` (a template, not a running agent) |
| **Utility** | Haiku | Bulk read / parse / extraction, cheap context shield | `web-fetcher`, `log-analyzer`, `repo-scout`, `doc-fetcher`, `distiller`, `validator` |

Agent frontmatter uses model **aliases** (`fable`, `opus`, `sonnet`, `haiku`) that resolve to
the latest version of each tier — never pin full model IDs unless you need a specific version.
Subagents can nest (up to 5 levels deep; an agent's `tools:` list documents which agents it may
spawn), and they inherit your full CLAUDE.md/memory hierarchy automatically — don't duplicate
global context in agent prompts.

**Why the tiers are pinned this way:** the orchestrator needs the smartest model because
decomposition and synthesis are the hard parts. Research and fleet-mechanics need strong
reasoning (opus). Implementation of a well-specified leaf is sonnet territory. Bulk
reading/condensing/gating is mechanical (haiku) — these agents exist specifically to keep large
inputs out of a smarter, more expensive context.

Add your own **domain specialists** (an infra admin, a business-ops advisor, whatever your work
needs) by copying `~/.claude/agents/domain-agent-template.md` — one agent per stable domain,
holding that domain's facts and runbooks in its prompt, pinned to sonnet. Or just describe the
gap to `agent-smith` and let it design one for you (see below).

## The roster web — how agents stay current without drifting

Every agent in the fleet needs to know who else exists and how to delegate, but hard-coding that
table into 18 separate agent files would drift the moment one agent changed. The system solves
this with **live loading**, not sync scripts:

- **Global fleet map, one copy, `@import`ed once.** `~/.claude/CLAUDE.md` contains
  `@rosters/fleet-map.md` — a single `@import` line. Every session (top-level or subagent)
  inherits CLAUDE.md, so every context in the web sees the current fleet map with zero
  per-agent duplication. `rosters/fleet-map.md` itself stays under a ~90-line cap; anything
  bigger belongs in one of the detail files below it.
- **Playbook detail loads per-audience via skills, at invocation time.** Three skills —
  `roster-sdm` (orchestrator playbook), `roster-sde` (dev-agent support roster), and
  `liveliness` (the status-reporting protocol) — are marked `skills:` in the relevant agents'
  frontmatter, so Claude Code auto-preloads them. Each skill's entire body is one line:
  `` !`cat ~/.claude/rosters/<file>.md` `` — a **live shell substitution**, not a static copy. The
  skill re-reads the roster file every time it loads, so there is nothing to keep in sync; edit
  the roster file once and every agent that preloads that skill sees the edit on its very next
  invocation.
- **EMPIRICAL — `@import` does NOT expand inside agent definition bodies.** This was tested
  directly against Claude Code 2.1.212: an `@path` line placed inside an agent's own `.md` body
  (as opposed to `CLAUDE.md`) stays literal text — the target file's content never appears in
  that agent's context. This is *why* the roster detail files are wired through skills'
  `` !`cat` `` mechanism instead of `@import` lines inside each agent file: `@import` only
  expands where Claude Code's own context-loading walks (CLAUDE.md and its import chain), never
  inside a subagent's prompt body. Don't rely on `@import` for agent-to-agent knowledge sharing
  — it silently does nothing.
- **`Agent(a, b)` spawn lists are behavioral, not enforced.** An agent's frontmatter `tools:`
  line can include `Agent(agent-forge, researcher)` to document who it may call — but Claude
  Code does not actually restrict subagent spawning to that list at runtime. Treat these as the
  web's documented edges (and honor them), not as a security boundary. If a spawn restriction is
  genuinely load-bearing, the real enforcement point is `permissions.deny` in settings, and the
  agent's doc comment should say so.

## The context library and personas

Agent prompts accumulate copy-pasted doctrine over time: the same testing philosophy, the same
review checklist, the same tone guide, repeated across a dozen files. `claude-config/context/`
gives that doctrine one home instead of a dozen copies. It holds two kinds of file:

- **Slices** (`context/skills/<category>/<slice>.md`): one doctrine concern per file, always a
  leaf (a slice never references another slice; a dependency between concerns belongs in a
  persona manifest instead).
- **Personas** (`context/personas/<group>/<persona>.md`): a thin manifest that lists the slices
  one role actually needs, in load order, plus a short role summary.

The manifest format, naming rules, and the full slice/persona catalog live in
[claude-config/context/README.md](../claude-config/context/README.md) and
[claude-config/context/INDEX.md](../claude-config/context/INDEX.md); this section covers only why
the system is shaped the way it is.

**Why a generated loader skill, not a direct `@import`.** The roster web section above
established the empirical fact that `@import` only expands inside the CLAUDE.md/rules-file
import chain, never inside an agent definition body. Personas hit the same wall: an agent can't
`@import` a persona manifest directly. `tools/gen-persona-skills.sh` bridges the gap by reading
each manifest's frontmatter `slices:` list and emitting a `persona-<group>-<persona>` loader
skill under `claude-config/skills/`, in the same live-loading shape as the
`roster-sdm`/`roster-sde`/`liveliness` skills: the generated skill's body is a single `` !`cat` ``
line that reads the slice files straight from `~/.claude/context/` at invocation time, not a
frozen copy. An agent picks up a persona by listing that generated skill's name in its own
frontmatter `skills:` list.

**Dual consumption, one manifest.** A persona is written once and read two different ways:

1. **Session-level**, via `@import`: a `CLAUDE.md` or rules file can `@import` a persona
   manifest directly, and the manifest's own `@` lines then pull in each slice in turn. This
   works precisely because CLAUDE.md/rules files are where Claude Code's import walk runs.
2. **Agent-level**, via the generated loader skill described above, for agent definition bodies,
   where `@import` doesn't expand.

All 17 shipped agents compose their role-specific prose with a persona this way, rather than
inlining shared doctrine by hand into each agent file.

**The private overlay: `~/.claude/context-local/`.** The installer creates this directory empty,
and this repo never ships content into it. It mirrors the same
`skills/<category>/<slice>.md` and `personas/<group>/<persona>.md` layout, for doctrine that's
private or site-specific and has no business in a public repo. If you keep `~/.claude` itself
under version control, add `context-local/` to that repo's `.gitignore` too.

**Regeneration workflow.** Edit a slice or manifest under `context/`, run
`tools/gen-persona-skills.sh` from the repo root, and commit the source edit together with the
skill(s) it regenerates. Generated skills carry an `AUTO-GENERATED` marker in their own header;
hand-editing one is a mistake the next regeneration will overwrite.

## agent-smith — the fleet's self-extension mechanism

`agent-smith` (Fable) is the only agent that changes the fleet's shape. It designs; a paired
agent, `agent-forge` (Opus), does the mechanics — writing the file, updating roster rows, and
validating — so a bad install can't corrupt the config repo from a rushed edit.

**Trigger it whenever:**
- The same task shape recurs twice in different jobs — that's a template, not a coincidence.
- You're about to hand-roll the same multi-step inline workflow again (more than ~3 steps).
- A domain or tool has no owner in the roster.
- An existing agent is repeatedly asked to be "X, but always for Y" — that's a specialization
  worth carving out.

This is a **mandatory reflex for Fable orchestrators**, not just a suggestion — the fleet map
states it as delegation rule #4. Anyone can invoke it directly with the `/new-agent <the gap>`
skill, which spawns `agent-smith` with your gap report and relays its design decisions back
(tier, model, tools, roster placement) once `agent-forge` has installed the result.

**Pipeline:** gap report in → `agent-smith` reads `ROSTER.md` and `fleet-map.md`, picks a tier by
task shape (using the same four-tier table above), designs least-privilege tools and a
`skills:` preload appropriate to the tier, and starts from the matching
`~/.claude/templates/agents/<tier>.md` template → hands `agent-forge` a complete spec → the new
agent file is written, `ROSTER.md`/`fleet-map.md` rows are added, and it's validated. **New and
changed agents are live starting the next Claude Code session**, not the one that created them —
`agent-smith` always says so explicitly in its report.

## The five-channel liveliness stack

When most of the real work happens off-screen in subagent context windows, a quiet terminal
looks like a stall even when the fleet is working hard. Liveliness is the fix: five channels,
the first two automatic, the last three the agent's job.

1. **Lifecycle hooks (automatic).** A `SubagentStart`/`SubagentStop` hook
   (`hooks/subagent-liveliness.sh`) fires on every subagent transition, prints a short
   `▶ started` / `✔ done` system line, and maintains a live-agent state file so other channels
   (below) can read current fleet activity. It's written to never block a spawn — any
   unexpected input degrades to a silent no-op.
2. **Statusline (automatic).** The statusline script refreshes on a short interval and renders
   the live agent count/names straight from that same state file, so the footer always reflects
   the web actually working, not just the top-level turn.
3. **Orchestrator narration.** Every orchestrator prints one line before each spawn or wave
   (`▶ started: <what> → <agent>(s)`), one line after each result lands (`✔ done: <what> — <one
   clause>`), and one line before each gate (`⟳ gate: <validator> on <what>`). Only top-level
   text reaches the user, so a subagent orchestrator's narration duty becomes its **TIMELINE**
   (below) — written so its parent can relay it upward.
4. **Native task board.** Orchestrators stand up the wave plan with `TaskCreate` *before*
   fanning out (not after), mark tasks in-progress/completed as leaves run, and encode wave
   ordering with `blockedBy`. The user watches progress live; this replaces any hand-rolled
   markdown checkbox board.
5. **Report contract.** Every agent's final report opens with the same two lines, no exceptions:
   ```
   STATUS: ok | partial | blocked — <one line: what happened>
   TIMELINE: <2-6 compact lines: did X, found Y, spawned Z, gate result>
   ```
   followed by a `BLOCKERS:` section only when status isn't `ok`, then the body the caller
   asked for. A parent orchestrator relays this cheaply instead of re-deriving what happened.

Silence longer than one wave is treated as a protocol violation, not a quirk — if a long-running
leaf is still going, the rule is to say so ("⏳ still running: full validation suite, ~2min in"),
not to go quiet until it finishes.

## The pipeline (how a feature gets built)

1. **Intake** — your main session or `project-manager` receives the goal.
2. **Research fan-out** — the PM spawns one `researcher` per topic **in parallel**. Each
   verifies against live sources (docs, changelogs, `--help`), pulls in `distiller`s for bulk
   content, and writes organized markdown to the project's `.claude/knowledge/<topic>/`. The PM
   waits for all to complete.
3. **Plan** — the PM reads the research and creates/updates the project's central execution
   plan in `~/.claude/planning/<slug>/`. Work is decomposed into **independent, parallelizable
   leaves** with explicit dependencies, following the atomic-leaf contract (goal, acceptance
   criteria, files in scope, tests required, out of scope, report-back ask) — a leaf you can't
   fill that template out for isn't atomic yet.
4. **Execute in waves** — the PM fans out dev-tier agents (the right language specialist, or
   `coder` as the generalist fallback) on independent leaves — parallel within a wave, waves
   ordered by dependency — tracking work on the native task board (`TaskCreate`/`TaskUpdate`
   with `blockedBy`) rather than hand-rolled markdown checkboxes.
5. **Gate** — every leaf ends with `validator` at **targeted** level. A milestone (a completed
   wave, before dependents build on it) gets `validator` at **full** level, and anything
   judgment-heavy (security-sensitive, public-facing copy, prod-touching) gets a review gate on
   top.
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
| `/new-agent <gap>` | Spawns `agent-smith` to design and install a new roster agent for a recurring task shape |
| `/ci-check` | Watches the latest CI run to completion — because a push triggers a deploy, a push isn't done until CI is green |
| `/sync-config` | Commits (and pushes) the `~/.claude` config repo |

`roster-sdm`, `roster-sde`, and `liveliness` are also skills, but they're auto-preloaded via
agent frontmatter rather than invoked directly — see "The roster web" above. Running them
manually (`/roster-sdm`, etc.) just shows you the current roster content.

## Validation levels

- **targeted** (default per dev-tier leaf): `git diff --name-only` → run only related tests
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
  so a dev agent working on one leaf can't create hidden coupling to another.
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
  Cheap/bulk → haiku (or an optional local LLM — see
  [local-llm-offload.md](local-llm-offload.md)). Research → opus. Implementation → sonnet.
  Orchestration/hard synthesis → fable.
