# Agentic Development — Fleet, Pipeline & Conventions

> Durable global standard for how multi-agent development runs on this machine.
> The enforceable summary lives in `~/.claude/CLAUDE.md` (Agent Fleet +
> Workflow sections); this file is the full reference. Facts verified against
> code.claude.com docs 2026-07-02 (Claude Code 2.1.199).

## The fleet (`~/.claude/agents/`)

`~/.claude/context/skills/fleet/fleet-map.md` is the compact global view, auto-imported
into every session and subagent via `~/.claude/CLAUDE.md`'s `@import`;
`~/.claude/context-local/skills/fleet/ROSTER.md` is the full registry (model/effort/skills
per agent). It lives in the private overlay, not the shipped repo, because it is
user-runtime content `agent-forge` writes, and updates must never touch it. Both are
maintained by **agent-smith** (design) and **agent-forge** (install) as the fleet grows.

Tier philosophy: **fable** = orchestration & synthesis (decompose, plan, gate, spawn
agent-smith on gaps); **opus** = deep specialists (research, domain admin, the
agent-creation engine); **sonnet** = implementation & ops (coding, infra/business
domains, config surgery); **haiku** = utility sponges (cheap, read-only, bulk-input
shields). Models are pinned per agent via frontmatter aliases (resolution rule below).

Model aliases in frontmatter resolve to the **latest** version per tier
(`opus` → latest Opus, `sonnet` → latest Sonnet, `haiku` → latest Haiku,
`fable` → latest Fable). Never pin full model IDs in agent files unless a
specific version is required. Subagent nesting is native (since v2.1.172, max
depth 5); `Agent(name)` in `tools:` restricts which types an agent may spawn.
Subagents inherit the full CLAUDE.md/memory hierarchy automatically — do not
duplicate global context in agent prompts.

## The roster & context web (v2)

- `~/.claude/CLAUDE.md` `@imports context/skills/fleet/fleet-map.md` — combined with the
  full CLAUDE.md/memory hierarchy being auto-inherited by every subagent, the fleet map
  reaches every context in the web with zero manual wiring.
- Audience playbooks (`roster-sdm`, `roster-sde`, `liveliness`) preload via agent
  frontmatter `skills:` — the full skill content is injected at spawn time, and loader
  skills `!cat` the doctrine file live (private `context-local/` overlay first, then the
  shipped `context/` default), so edits propagate with zero sync step.
- **EMPIRICAL:** `@imports` do NOT expand inside agent definition bodies — never rely on
  an `@import` working inside an agent's own `.md` file, only in CLAUDE.md/rules files.
- `Agent(a, b)` spawn lists in frontmatter are behavioral contracts, not enforced by
  Claude Code for subagents.
- Hard cap: `fleet-map.md` stays ≤ ~90 lines; detail lives in `sdm-playbook.md` /
  `sde-support.md` under `~/.claude/context/skills/fleet/`, plus `ROSTER.md` under
  `~/.claude/context-local/skills/fleet/` (private overlay, agent-forge-writable).

## agent-smith — the self-extending fleet

**Trigger mandate:** any Fable orchestrator that sees a recurring task shape or a
missing capability MUST spawn `agent-smith` — mandatory for orchestrators, and
available to users directly via `/new-agent`.

**Pipeline:** `agent-smith` designs the new agent (role, tier, tools, skills) →
`agent-forge` installs it via `config-editor` leaves (agent file, roster row, any
skill/template wiring) → lint + a headless probe verify it → report back. New agents
become available starting **next session**, not the one that created them.

Templates for new agents live in `~/.claude/templates/agents/`.

## Liveliness protocol

Five channels keep the terminal from looking dead while work is delegated:
1. **Hooks** — `SubagentStart`/`SubagentStop` fire `~/.claude/hooks/subagent-liveliness.sh`,
   which emits systemMessage pings and maintains `~/.claude/state/subagents-live.json`.
2. **Statusline** — `~/.claude/statusline.sh` refreshes on an interval and renders the
   live agent count/names from that state file.
3. **Orchestrator narration** — one line per spawn/result/gate (`▶ started:` / `✔ done:` /
   `⟳ gate:`), surfaced by orchestrators every wave.
4. **Native task board** — `TaskCreate`/`TaskUpdate` with `blockedBy`, watched via Ctrl+T;
   never a hand-rolled markdown checklist.
5. **Report contract** — every agent's final report leads with
   `STATUS: ok|partial|blocked — <one line>` then a `TIMELINE:` block.

Wiring lives in `~/.claude/settings.json` (hooks config) +
`~/.claude/hooks/subagent-liveliness.sh` + `~/.claude/statusline.sh`. Full protocol:
`context/skills/fleet/liveliness.md` (preloaded via the `liveliness` skill).

## The pipeline (how a feature/product gets built)

1. **Intake** — main session or `project-manager` receives the goal. Domain
   questions (business facts, infrastructure, pricing/policy) go to the
   matching domain specialist agent if you've created one.
2. **Research fan-out** — PM spawns one `researcher` per topic **in parallel**.
   Each researcher verifies against live sources (never training data), pulls in
   `distiller`s for bulk content, and writes organized markdown to the
   project's `.claude/knowledge/<topic>/`. PM waits for all to complete.
3. **Plan** — PM reads the research and creates/updates the project's central
   execution plan in `~/.claude/planning/<project>/` (see conventions below).
   Work is decomposed into **independent, parallelizable leaves** with explicit
   dependencies — enabled by the functional-core + DI standards (pure modules
   with injected seams are what make multi-agent work on one codebase safe).
4. **Execute in waves** — PM fans out `coder` agents on independent leaves
   (parallel within a wave; waves ordered by dependency). Tracks work on the
   native task board (`TaskCreate`/`TaskUpdate` with `blockedBy`) — not
   hand-rolled markdown checkboxes.
5. **Gate** — every leaf ends with `validator` at **targeted** level (tests
   related to the changed files only). A milestone (a wave/tree completed,
   before dependents build on it) gets `validator` at **full** level.
6. **Finalize** — update the execution plan + SPEC_INDEX, `context-keeper`
   records durable facts, commit green work (conventional commits, **no
   attribution trailers** — Golden Rule 0).

In an `ultracode` session the main loop may use the Workflow tool instead of a
PM subagent — same pipeline, script-driven. The PM agent is for delegating the
whole pipeline out of the main conversation.

## Conventions

### Research knowledge — project-local `.claude/knowledge/`
- Path: `<repo>/.claude/knowledge/<topic-kebab>/<NN>-<subtopic>.md`
- Each file starts with frontmatter: `date`, `sources` (URLs), `confidence`.
- `<repo>/.claude/knowledge/INDEX.md` lists every topic with a one-line hook —
  researchers append to it; PM reads it first.
- Knowledge is versioned **with the code** (it explains why the code is shaped
  the way it is). Do not put plans here.

### Execution plans — global `~/.claude/planning/<project>/`
- Central, cross-session, cross-repo: `EXECUTION_PLAN.md` (authoritative
  status/decisions/next steps), `SPEC_INDEX.md` (board), `specs/` (wsNN triads).
- **Project slug** = git remote origin repo name (lowercased), else directory
  basename. Every project gets a row in `~/.claude/planning/REGISTRY.md`
  (slug → absolute repo path → one-line description) — the traceability link
  back to the repo and the collision check.
- Legacy project-local `.claude/planning/` trees keep working: the spec skills
  detect them and use them until migrated; migrate a project by moving its
  tree to `~/.claude/planning/<slug>/` and adding the REGISTRY row on the next
  natural touch.
- Permissions for these paths are pre-allowed in `~/.claude/settings.json`.

### Validation levels
- **targeted** (default for every coder leaf): `git diff --name-only` →
  run only related tests (`vitest related` / `jest --findRelatedTests` /
  `pytest <files>` / `go test <pkgs>`), lint changed files, typecheck.
- **full** (milestone/tree gate + before any commit): the project's composite
  validate/release script — lint + typecheck + all tests w/ coverage + build.
- **Unity**: headless batchmode NUnit —
  `Unity -runTests -batchmode -projectPath . -testPlatform EditMode|PlayMode -testResults out.xml`,
  parse the XML.
- The validator may add missing helper scripts to `package.json`
  (`test:related`, `validate`) when a project lacks them.

### Local LLM offload — `askllm` (optional, zero-token bulk work)
- Entirely optional. If you run a local OpenAI-compatible gateway (e.g.
  LiteLLM/vLLM/Ollama at `http://<your-llm-host>:4000/v1`), a small
  `~/.local/bin/askllm` script pipes stdin + an instruction to it:
  `cat big.log | askllm "extract every ERROR with root cause"`.
  Standard env vars: `LLM_API_URL`, `LLM_API_KEY`, `LLM_MODEL`. Full setup +
  the script live in `docs/local-llm-offload.md` in the setup repo this config
  came from.
- Use it for: bulk research distillation, giant-file/log summarization,
  mechanical text transforms. Never for decisions, code, or anything needing
  current knowledge. If the gateway is down (or you never set one up), fall
  back to `distiller` (Haiku).

### Frontmatter conventions (2.1.212)
- **Effort** per tier: haiku utility agents = `low`; fable orchestrators = `high`;
  everything else defaults to `inherit`.
- **Color** per tier: purple (fable), blue (opus), green (sonnet dev/config — coder,
  config-editor, context-keeper), orange (sonnet infra/business-domain ops — git-ops,
  plus any domain agents you add from `domain-agent-template.md`), cyan (haiku).
- Subagents run **background by default**; spawn depth cap is **5**; session cap is
  **~200 spawns** (`CLAUDE_CODE_MAX_SUBAGENTS_PER_SESSION`).
- `MEMORY.md` hard limits: **200 lines / 25KB** — trim before either is hit.

## MCP servers

| Server | Scope | Status | Notes |
|--------|-------|--------|-------|
| context7 | user | **recommended** | live library docs; use before writing against any external API |
| playwright | user | **recommended** | real-browser E2E driving; keep committed E2E as Playwright test files run via Bash (≈4× cheaper) |
| postgres (crystaldba/postgres-mcp) | user | optional | only with a read-only role on the target DB; run `--access-mode=restricted` |
| github official | — | usually skip | `gh` CLI covers it; revisit only for structured Actions-log/security-alert reads |
| filesystem/fetch/search/memory/sequential-thinking MCPs | — | skip | duplicate Claude Code natives |

Give MCP tools to agents via `tools:` allowlist (`mcp__<server>` = whole
server); wire project-specific servers (game engines, app DBs) in that repo's
`.mcp.json` so they never load in unrelated sessions.

## Parallelize by default

- Independent leaves → one agent each, same message, concurrent.
- Code must stay parallel-agent-safe: functional core + DI, one module per
  concern, no cross-cutting edits in a leaf. If two leaves must touch the same
  file, they are one leaf or two waves.
- Cheap/bulk → haiku or `askllm`. Research → opus. Implementation → sonnet.
  Orchestration/hard synthesis → fable. Don't over-frugalize: tune down later
  where usage shows it's safe, not preemptively.
