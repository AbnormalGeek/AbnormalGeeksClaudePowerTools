# AbnormalGeeksClaudePowerTools

A deeply-iterated **Claude Code agentic development setup**, packaged so you can replicate it
on your own machine with one command. This is not a starter template — it's a working system
that has been refined over months of daily use: a fleet of custom subagents, a research → plan →
parallel-implementation → validation pipeline, centralized planning conventions, engineering
standards that make multi-agent work on one codebase safe, and the glue (skills, commands,
statusline, config-as-git) that holds it together.

## Install: the one-liner

This is a **private repo**. Before running the one-liner you need:

1. Claude Code installed (`claude --version` works)
2. `gh auth login` completed on your machine
3. Read access to this repo (ask [@AbnormalGeek](https://github.com/AbnormalGeek) to grant it)

Then paste this into a terminal:

```bash
claude "Clone https://github.com/AbnormalGeek/AbnormalGeeksClaudePowerTools to ~/ai_workspace/AbnormalGeeksClaudePowerTools (private repo — use gh), then read SETUP.md in it and follow it exactly to set up this machine."
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

1. **project-manager** decomposes a goal into research topics and independent work leaves.
2. **Parallel researchers** (one per topic) verify against live sources and write findings to
   the project-local `.claude/knowledge/<topic>/` — versioned with the code it explains.
3. A **central plan** lives in `~/.claude/planning/<project-slug>/` (EXECUTION_PLAN, SPEC_INDEX,
   specs), cross-session and cross-repo, with a `REGISTRY.md` mapping slugs to repo paths.
4. **Parallel coder waves** implement independent leaves concurrently — safe because the
   engineering standards (functional core + dependency injection, one module per concern)
   keep leaves from colliding.
5. **Validator gates** everything: targeted (related tests only) per leaf, full (lint +
   typecheck + all tests + build) per milestone and before any commit.
6. **Memory habits** persist durable facts across sessions: an auto-memory `MEMORY.md` index
   plus one-topic-per-file notes, so no session re-learns what a previous one verified.

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
| `claude-config/` | `~/.claude/` | `CLAUDE.md`, `settings.json`, `statusline.sh`, `agents/`, `commands/`, `rules/`, `skills/`, `planning/`, `.gitignore` |
| `ai-workspace-template/` | `~/ai_workspace/` | Workspace README + starter `.claude/CLAUDE.md` |

`install.sh` is idempotent, needs no sudo, and **backs up any existing file it would overwrite**
to `~/.claude.backup-<timestamp>/` before copying — SETUP.md then has Claude diff and merge
anything meaningful from your previous config rather than losing it. It never touches
`~/.claude/settings.local.json`, credentials, sessions, or project state. Existing
`~/ai_workspace` files are skipped, never overwritten.

After install, `~/.claude` becomes a git repo (an allowlist-style `.gitignore` is included) so
your config is versioned; the `/sync-config` command commits and pushes changes.
