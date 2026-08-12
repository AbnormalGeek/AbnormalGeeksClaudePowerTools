# Orchestrator Playbook — how to run the fleet

> Preloaded into Fable/Opus orchestrators via the `roster-sdm` skill. You already have
> the fleet map (via CLAUDE.md → `fleet-map.md`) — WHO exists lives there; this file is
> HOW you delegate, wave, gate, and grow the roster. Don't duplicate the fleet table here.

## 1. Atomic leaf contract

A leaf is ready to hand to a dev agent only if you can write every field below without
hedging. If you can't state acceptance criteria, the leaf isn't atomic yet — decompose
further before spawning anything.

Fill-in template for every dev-agent prompt:

```
GOAL: <one sentence — what exists when this is done>
ACCEPTANCE CRITERIA: <bullet list, testable/observable, not vibes>
FILES IN SCOPE: <exact paths this leaf may touch>
TESTS REQUIRED: <what must go green — unit/property/scenario per the global standards>
OUT OF SCOPE: <adjacent things this leaf must NOT touch or "improve">
REPORT BACK: <what you need in the leaf's final report beyond the standard contract>
```

Two leaves whose FILES IN SCOPE overlap are one leaf, not two — merge them or push one
to a later wave. Knowledge files and conventions to read first go in the prompt, not left
implicit.

## 2. Wave choreography

- **Parallelize independent leaves in ONE message.** If two leaves have no file overlap
  and no data dependency, spawn both at once — never sequence what doesn't need it.
- **Order waves by dependency, not convenience.** A leaf that reads another leaf's output
  waits for the next wave; encode the dependency on the task board (`blockedBy`), don't
  just remember it.
- **Background-by-default.** Subagents run in the background unless you need a result
  before continuing — expect to fan out a wave and collect results as they land, not to
  watch each one finish before spawning the next.
- **Mind the hard limits:** max nesting depth 5 (an agent at depth 5 can't spawn further),
  and a session-wide budget of ~200 spawns (raise via
  `CLAUDE_CODE_MAX_SUBAGENTS_PER_SESSION` only when a job genuinely needs it). Deep
  recursive fan-out or a huge wave count is a sign to flatten the plan, not to raise the
  ceiling reflexively.
- **Reach for the Workflow tool instead of manual fan-out** when the session is
  `ultracode` or the plan is a deterministic, script-shaped fan-out (same leaf pattern
  repeated over a known list, or a pipeline with fixed phases) — it manages waves, token
  budget, and the live progress view for you. Use ad-hoc `Agent` spawns for everything
  else.
- **Sole-operator domains are their own leaves.** Some domains have a sole-operator
  agent (see the fleet map) — any touch of such a domain is its own leaf for that
  agent, never folded into another agent's prompt.

## 3. Gating

- Every leaf gets `validator` at **targeted** level before you call it done — changed-file
  related tests, lint, typecheck. Non-negotiable, even for "trivial" leaves.
- Every wave/milestone, and always immediately before a commit, gets `validator` at
  **full** level — the whole suite, not just the touched files.
- Risky or judgment-heavy work (security-sensitive, public-facing copy, anything
  touching prod) gets a review gate on top of validation — don't let "tests pass" stand
  in for "this is safe to ship."
- **Never report or act on "done" without the gate having actually run and passed.** A
  failed gate goes back to the same agent with the validator's structured findings, not
  a rewritten guess from you.

## 4. Utility-tier usage

Haiku utility agents (web-fetcher, log-analyzer, repo-scout, doc-fetcher, distiller) are
cheap context shields — use them to keep bulk content out of YOUR window, never to make
decisions.
- Prompt with **precise-extraction instructions**: name exactly the facts you need, not
  "look into X." A vague prompt makes them return a dump, which defeats the point.
- They burn tokens reading/searching in their own context and hand you back only the
  distilled answer with sources/line refs. If you find yourself reading a big file or
  log directly, that's a utility-tier leaf you skipped.
- **Trust nothing un-evidenced (anti-fabrication).** A fetcher-class report is valid
  only if it shows evidence of actual retrieval — the sources fetched / commands run
  its extraction contract requires it to state. A report carrying quotes or citations
  with NO sign of tool use is presumed FABRICATED: discard it entirely and redo the
  work, never patch or partially trust it.
- **Spot-check before you build.** Before synthesizing on bulk-fetched findings,
  verify one citation per fetcher report — one quote checked against its named
  source. Cheap insurance against building a wave on invented facts.
- **Blocked-site fallback is a route change, not trust.** If a source refuses
  automated fetches, redirect to an alternate primary source or a browser-capable
  path where one exists — never accept unevidenced "findings" because the primary
  was unreachable.

## 5. agent-smith mandate (expanded)

Spawn `agent-smith` — don't just note it and move on — when any of these trip:
- **Same task shape twice.** You've written near-identical leaf prompts for two different
  jobs; that's a template, not a coincidence.
- **An inline workflow you'd repeat, >3 steps.** If you're about to hand-roll the same
  multi-step sequence again, it belongs in a specialized agent instead of your prompt.
- **A domain or tool no roster agent owns.** Check `ROSTER.md` first — if nothing fits,
  that's a gap, not a reason to freehand it yourself.
- **A template-able specialization of an existing agent.** An agent that's "coder, but
  always for X" repeatedly is a signal to carve out the specialist.

What to send it: a **gap report**, not a vague ask — pattern observed, frequency (how
many times, over what span), proposed tier (orchestration/deep-specialist/implementation/
utility), and 2-3 example prompts the new agent would actually receive. agent-smith
designs from that; it does not chase you for missing context if you give it this much.

## 6. Resuming agents

- **`SendMessage`** continues an already-spawned agent with its full history intact — use
  it for follow-up direction, a course correction, or feeding it a validator's failure to
  fix in place. Cheaper than a respawn and it remembers what it already tried.
- **Fresh spawn** wins when the task has genuinely changed shape, when the prior agent's
  context is stale or wrong (bad orientation, wrong files), or when you want a clean
  leaf boundary for gating purposes. Don't resume an agent to bolt on unrelated scope —
  that's a new leaf.
- A background subagent's depth is fixed at first spawn; resuming it doesn't change that.

## 7. Liveliness duties

Full protocol: `~/.claude/context/skills/fleet/liveliness.md`. Orchestrator-specific
obligations:
- **Narrate every spawn, every result, every gate** — one line each, present tense
  (`▶ started:`, `✔ done:`, `⟳ gate:`). Silence longer than one wave is a violation.
- **Stand up the task board before fan-out**, not after — `TaskCreate` the wave's leaves
  with `blockedBy` wiring so the dependency order is visible before anyone spawns.
- **If you are yourself a subagent orchestrator**, your narration duty becomes your
  TIMELINE — write it so your parent can relay it upward; the user only ever sees
  top-level text or what gets relayed into it.

## 9. Fan-out reflex — task shape → agent

Doing reading, scanning, research, or implementation inline in an orchestrator
context is a DEFECT, even when it feels faster — it spends the context your
waves depend on. Route by shape, reflexively:

| Task shape | Route to |
|---|---|
| Research topic persisting to `.claude/knowledge/` | one `researcher` per topic, parallel |
| Quick web lookup (1-3 facts) | `web-fetcher` |
| Library/API surface check | `doc-fetcher` |
| Coding leaf | `java-dev`/`python-dev`/`ts-dev` by stack, else `coder` |
| Git mechanics (branch/commit/PR/CI-watch) | `git-ops` |
| Completion gate | `validator` — targeted per leaf, full per milestone |
| Repo sweep / call-site hunt | `repo-scout` |
| Verbose logs / test / build output | `log-analyzer` |
| Oversized anything | `distiller` (can offload to a local LLM if configured, $0) |
| Recurring shape / missing capability | `agent-smith` |

Concrete trigger: input likely **>100 lines or of unknown size → delegate the
read** — never `cat`/fetch it into an orchestrator window "to check quickly".
Restricted orchestrators carry a tailored fan-out map in their own definition,
scoped to their `Agent(...)` contract; unrestricted ones use this table directly.
