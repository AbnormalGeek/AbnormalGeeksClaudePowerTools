# AbnormalGeeksClaudePowerTools

A deeply-iterated **Claude Code agentic development setup**, packaged so you can replicate it
on your own machine with one command. This is not a starter template — it's a working system
that has been refined over months of daily use: a **self-extending web** of 28 custom
subagents across four model tiers, a research → plan → parallel-implementation → validation
pipeline, centralized planning conventions, engineering standards that make multi-agent work on
one codebase safe, a five-channel liveliness stack so the terminal never looks dead mid-run,
and the glue (skills, commands, statusline, config-as-git) that holds it together.

## What's new in v2

The fleet went from a fixed roster to a **self-extending web**:

- **`agent-smith` + `agent-forge`** — the fleet now grows itself. Spot a recurring task shape or
  a missing capability and spawn `agent-smith` (or run `/new-agent <the gap>`); it designs the
  new agent's tier/tools/roster placement and hands the install mechanics to `agent-forge`.
  New agents are live the next session.
- **Four clean model tiers** (orchestrator/Fable, specialist/Opus, dev-ops/Sonnet,
  utility/Haiku) replace the old ad-hoc model choices, with a template per tier under
  `claude-config/templates/agents/` so every new agent starts from a consistent shape.
- **A live-loading roster web**, not copy-pasted tables: `CLAUDE.md` `@import`s one global
  fleet map, and per-audience playbooks (`roster-sdm` for orchestrators, `roster-sde` for dev
  agents, `liveliness` for the status protocol) preload as skills that `cat` the current roster
  file at invocation time — edit the roster once, every consumer sees it next call, nothing to
  keep in sync.
- **A five-channel liveliness stack** — lifecycle hooks + statusline are automatic; orchestrator
  narration, the native task board, and a `STATUS:`/`TIMELINE:` report contract are the agent's
  job — so long delegated runs never look stalled.
- Full write-up: [docs/how-it-works.md](docs/how-it-works.md).

## How you use it (day to day)

You do not drive this with slash commands. After setup you describe what you want in
plain language, and the installed context does the routing: every session opens as an
orchestrator. Coding routes to the Sonnet dev tier (`java-dev`, `python-dev`, `ts-dev`,
or the generalist `coder`), research routes to `researcher`, and bulk input (web pages,
logs, repo sweeps, library docs) routes to the Haiku utility tier. Git mechanics route
to `git-ops`. The fleet map loads into every session and every subagent, so this
routing knowledge is always present, not something you have to remember or ask for.

While it works, you will see three things: one-line narration for each delegated step
(`▶ started`, `✔ done`, `⟳ gate`), a live task board (`Ctrl+T`), and a statusline
counter showing active agents. The `SubagentStart`/`SubagentStop` hooks that drive this
ship enabled in `settings.json`, so there is nothing to turn on.

The fleet also grows itself. When a task shape keeps recurring, the orchestrator's
standing instruction is to invoke `agent-smith`, which designs and installs a new
specialist for the next session. You can trigger the same thing directly with
`/new-agent`, or copy `domain-agent-template` to stand up your own domain specialist
by hand.

### Optional guided flows

None of these are required. They exist for when you want a structured entry point
instead of describing the goal in plain language.

| Command | What it gives you |
|---------|--------------------|
| `/new-agent` | Adds a new specialist to the fleet |
| `/setup-project` | Drops the per-project rules into a repo |
| `/spec-new`, `/spec-run`, `/spec-status` | Spec-driven feature pipeline: create, run, and check the status of a spec |
| `/ci-check` | Watches CI on the current repo until it goes green |
| `/sync-config` | Commits your `~/.claude` config |
| `/powertools-update` | Pulls the latest PowerTools and re-installs, with review |

Contributors: run `tools/leak-check.sh` before pushing. A pre-push hook enforces it via
`git config core.hooksPath .githooks`. CI runs leak-check, the shipped test suites, and a
persona-skill sync check on every push and pull request against `main`.

## Install: the one-liner

Before running the one-liner you need:

1. Claude Code installed (`claude --version` works)
2. `gh auth login` completed on your machine (used by SETUP.md and some skills)

Then paste this into a terminal:

```bash
claude "Clone https://github.com/AbnormalGeek/AbnormalGeeksClaudePowerTools to ~/ai_workspace/AbnormalGeeksClaudePowerTools, then read SETUP.md in it and follow it exactly to set up this machine."
```

Claude clones the repo and follows [SETUP.md](SETUP.md): it runs the installer, interviews you
to personalize the config (name, GitHub username, shell, preferences), registers the MCP
servers, turns `~/.claude` into a git repo, and verifies everything. If you already have
`~/.claude` content, nothing is clobbered — see [What gets installed](#what-gets-installed).

## Your AI workspace

The setup creates **`~/ai_workspace`** and recommends it as your primary general-purpose
workspace: launch Claude Code there by default for anything that isn't tied to a specific
project — machine customization, research, scripts, notes, orchestrating work across repos.
It gets its own `.claude/CLAUDE.md` with your machine's context. Actual project repos get their
own per-repo setup via the included `/setup-project` skill.

## Linux recommended (not required)

This system shines on **Linux**: Claude Code is very good at interacting with and customizing a
Linux distro to your liking — package management, services, dotfiles, desktop tweaks — and an
`ai_workspace` on Linux becomes a genuinely capable machine administrator over time. That said,
**nothing here requires Linux.** The core value is the agentic workflows, and those are
OS-agnostic; the installer and configs work on macOS too.

## Quick tips

- **Run most sessions as Fable 5 with `/effort ultracode`.** The top-level agent is the
  orchestrator — it should be the smartest model available. Cost stays sane because the custom
  subagents have cheaper models pinned in their own configs (opus for research, sonnet for
  implementation, haiku for bulk/validation), so delegated work runs on the right tier
  automatically. Don't over-frugalize the orchestrator; tune down later if usage shows it's safe.
- Use `ultrathink` in a prompt for one-off deeper reasoning without changing session effort.
- For any non-trivial feature: plan mode first, then fan out subagents — or hand the whole
  pipeline to the **project-manager** agent.

## How the system works (short version)

Full detail in [docs/how-it-works.md](docs/how-it-works.md).

1. **The orchestrator never does the work itself.** Top-level and orchestrator contexts plan,
   sequence, gate, and commit — reading, research, implementation, and validation all go to
   subagents that return conclusions, never raw dumps.
2. **project-manager** decomposes a goal into research topics and independent work leaves;
   **agent-smith** grows the roster itself when a recurring task shape has no owner yet.
3. **Parallel researchers** (one per topic) verify against live sources and write findings to
   the project-local `.claude/knowledge/<topic>/` — versioned with the code it explains.
4. A **central plan** lives in `~/.claude/planning/<project-slug>/` (EXECUTION_PLAN, SPEC_INDEX,
   specs), cross-session and cross-repo, with a `REGISTRY.md` mapping slugs to repo paths.
5. **Parallel dev-tier waves** (a language specialist or the generalist `coder`) implement
   independent leaves concurrently — safe because the engineering standards (functional core +
   dependency injection, one module per concern) keep leaves from colliding.
6. **Validator gates** everything: targeted (related tests only) per leaf, full (lint +
   typecheck + all tests + build) per milestone and before any commit.
7. **A five-channel liveliness stack** keeps the terminal honest during long delegated runs:
   automatic lifecycle hooks and statusline, plus orchestrator narration, a live task board,
   and a `STATUS:`/`TIMELINE:` report contract from every agent.
8. **Memory habits** persist durable facts across sessions: an auto-memory `MEMORY.md` index
   plus one-topic-per-file notes, so no session re-learns what a previous one verified.
9. **A context library backs dev-tier agents with shared doctrine.** `claude-config/context/`
   holds small, reusable doctrine slices (testing philosophy, review checklists, tone guides)
   grouped into named personas, instead of the same text being copy-pasted into every agent
   file. `tools/gen-persona-skills.sh` turns each persona manifest into an auto-generated
   `persona-<group>-<persona>` loader skill that pulls its slices live from `~/.claude/context/`
   at spawn time, the same pattern `roster-sdm`/`roster-sde`/`liveliness` already use (needed
   because `@import` never expands inside an agent definition body). All 27 shipped agents
   compose their role-specific prose with a persona this way. Full detail:
   [claude-config/context/README.md](claude-config/context/README.md).

## MCP servers

Two servers are part of the core setup:

- **context7** — live library documentation. Consulted before writing code against any external
  API, so the agent never codes from stale training data.
- **playwright** — real-browser automation for E2E verification of web work.

[SETUP.md](SETUP.md) registers both automatically (and `install.sh` prints the commands as
hints). Exact registration commands, plus optional servers worth considering (read-only
postgres, GitHub official vs `gh` CLI), are in [docs/mcp-servers.md](docs/mcp-servers.md).

There's also an optional zero-cost local-LLM offload pattern for bulk text distillation — see
[docs/local-llm-offload.md](docs/local-llm-offload.md).

## What gets installed

The repo touches exactly two locations:

| Source | Destination | Contents |
|--------|-------------|----------|
| `claude-config/` | `~/.claude/` | `CLAUDE.md`, `settings.json`, `statusline.sh`, `agents/` (includes the Unity sub-web: `unity-lead`, `unity-cli`, `unity-code-dev`, `unity-reviewer`, `unity-context-gather`, `unity-asset-dev`, `unity-ui-dev`, `unity-asset-finder`, `unity-asset-finder-online`; plus `sketchfab-ops`), `commands/`, `rules/`, `skills/` (including the auto-generated `persona-*` loader skills), `templates/`, `hooks/`, `planning/`, `context/` (doctrine slices incl. fleet-doctrine `skills/fleet/`, Unity doctrine `skills/unity/`, + persona manifests), `.gitignore` |
| `ai-workspace-template/` | `~/ai_workspace/` | Workspace README + starter `.claude/CLAUDE.md` |

`install.sh` is idempotent, needs no sudo, and **backs up any existing file it would overwrite**
to `~/.claude.backup-<timestamp>/` before copying — SETUP.md then has Claude diff and merge
anything meaningful from your previous config rather than losing it. It never touches
`~/.claude/settings.local.json`, credentials, sessions, or project state. Existing
`~/ai_workspace` files are skipped, never overwritten. It also creates an empty
`~/.claude/context-local/` directory: the private overlay for your own site-specific doctrine
slices and personas, which this repo never ships content into.

After install, `~/.claude` becomes a git repo (an allowlist-style `.gitignore` is included) so
your config is versioned; the `/sync-config` command commits and pushes changes.
