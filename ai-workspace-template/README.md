# ~/ai_workspace — your general-purpose AI workspace

This directory is your **primary general-purpose workspace** for Claude Code: the default
place to launch `claude` for anything that isn't tied to a specific project repo.

## What belongs here

- **Machine customization** — dotfiles tweaks, package installs, services, desktop setup.
  Over time, Claude working from here becomes a genuinely capable administrator of this machine.
- **Research and notes** — questions, investigations, comparisons that don't have a repo yet.
- **Scripts and one-offs** — utilities, migrations, experiments before they graduate to a repo.
- **Cross-repo orchestration** — kicking off work that spans several projects.

What does **not** belong here: actual project code. A project gets its own repo and its own
per-repo Claude setup — run `/setup-project` inside the repo to wire it in.

## How it works

- `.claude/CLAUDE.md` in this directory holds **workspace context**: what this machine is,
  key paths, local conventions. Claude loads it automatically (layered on top of your global
  `~/.claude/CLAUDE.md`) whenever you launch a session from here.
- Keep that file current. When something durable about the machine changes (new drive, new
  tool, new convention), update it — or ask the **context-keeper** agent to.
- Cloned repos can live under this directory (e.g. `~/ai_workspace/<repo>/`) or anywhere you
  like; launching Claude inside a repo picks up that repo's own `.claude/` context instead.

## Suggested habits

1. Launch most sessions from here: `cd ~/ai_workspace && claude`.
2. Run substantive sessions as Fable 5 with `/effort ultracode`; delegation to the pinned
   cheaper subagents keeps cost sane.
3. Version this workspace if you want history: `git init` here is fine (add a `.gitignore`
   for anything throwaway).
4. After changing global config (`~/.claude/`), run `/sync-config` to commit it.

For the full system picture — the agent fleet, planning conventions, pipeline — see
`docs/how-it-works.md` in the setup repo this workspace came from.
