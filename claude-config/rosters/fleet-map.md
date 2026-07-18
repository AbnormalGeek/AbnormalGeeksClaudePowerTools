# Fleet Map — the agent web

> Source of truth for WHO does WHAT. Maintained by **agent-smith** (via agent-forge).
> Loaded globally: `~/.claude/CLAUDE.md` @imports this file, and every subagent inherits
> CLAUDE.md — so every context in the web sees this map. HARD CAP ~90 lines; detail
> belongs in `rosters/sdm-playbook.md`, `rosters/sde-support.md`, `rosters/ROSTER.md`.

## Delegation rules (non-negotiable)

1. **Orchestrator context discipline.** Top-level and orchestrator contexts do planning,
   sequencing, judgment, gating, and commits — nothing else. ALL reading, research,
   scanning, implementation, and validation go to subagents that return conclusions,
   never raw dumps.
2. **All coding → Sonnet dev tier**, one atomic well-defined leaf per agent (acceptance
   criteria + files in scope + tests required). Use the language specialist when one
   fits (java-dev / python-dev / ts-dev), else coder. Fable/Opus agents never write
   feature code inline. Git mechanics (branch/commit/PR/CI-watch) → git-ops.
3. **All bulk input → Haiku utility tier** (web pages → web-fetcher, verbose logs/output
   → log-analyzer, repo sweeps → repo-scout, library docs → doc-fetcher, condensing
   anything big → distiller). Prompt them with a precise extraction instruction; they
   return only the asked facts.
4. **See a recurring task shape or missing capability? Spawn agent-smith.** It designs
   and installs a new roster agent for next session. MANDATORY reflex for Fable
   orchestrators; encouraged for everyone. Repetition is a design smell.
5. **Liveliness.** Narrate delegation as it happens (`▶ started:` / `✔ done:` /
   `⟳ gate:`), keep the native task board current, and honor the report contract in
   `rosters/liveliness.md`. The user must always see progress.

## Tiers

### Fable — orchestration, synthesis, creation
| agent | use for |
|-------|---------|
| project-manager | any multi-step feature/product: research → plan → coder waves → gates |
| agent-smith | designing + installing NEW agents when a gap or recurring pattern appears |

### Opus — deep specialists
| agent | use for |
|-------|---------|
| researcher | one topic, live-source verified, persists to `.claude/knowledge/` |
| agent-forge | mechanics of agent creation: fans out config-editors, validates, registers (agent-smith's engine) |

### Sonnet — implementation & ops
| agent | use for |
|-------|---------|
| coder | one atomic coding leaf, any stack (generalist fallback) |
| java-dev / python-dev / ts-dev | one atomic coding leaf in that language's ecosystem, idiomatic + tested |
| git-ops | branch/commit/PR/merge/CI-watch mechanics under the Golden Rules |
| config-editor | `.claude` config, agent-file, roster, and rules surgery (agent-forge's editor) |
| context-keeper | CLAUDE.md/context/memory upkeep + config-repo git workflow |
| domain-agent-template | not a running agent — copy + fill in to stand up your own domain specialist (infra, business ops, a cloud service you operate) so that knowledge doesn't live in every session's context |

### Haiku — utility sponges (cheap context shields; read-only)
| agent | use for |
|-------|---------|
| web-fetcher | pull specific web page(s)/URLs → extracted facts only |
| log-analyzer | run diagnostic commands / read verbose logs → errors, causes, timings |
| repo-scout | sweep a codebase → file:line facts, structure, call sites |
| doc-fetcher | library/API docs (context7-first) → just the needed API surface |
| distiller | condense any oversized input; can offload to an optional local LLM (see `docs/local-llm-offload.md`), $0 |
| validator | completion gate: targeted (per leaf) / full (per milestone) test+lint+build runs |

## Notes
- `Agent(a, b)` spawn lists in frontmatter are **behavioral contracts** (Claude Code
  does not enforce them for subagents) — honor them anyway; they define the web's edges.
- Subagents run in the **background by default** (2.1.198+); orchestrators fan out
  parallel leaves freely and gate on results, minding the 5-level depth cap.
- Models are pinned per tier in each agent's frontmatter (aliases resolve to latest).
  Don't over-frugalize new agents; tune down when usage proves it safe.
