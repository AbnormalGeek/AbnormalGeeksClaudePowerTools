# ai_workspace — <your-machine-name>

The main general-purpose AI workspace on **<your-machine-name>**, running <your-os>.
Working in `ai_workspace` means personal / machine-level work (not a product codebase).

User-level identity, golden rules, and engineering standards come from `~/.claude/CLAUDE.md`.
This file holds context specific to this machine and workspace — keep it lean and current.

<!-- SETUP: fill the placeholders below during first-run setup (SETUP.md Step 2), and keep
     extending this file as durable facts about the machine accumulate. -->

## Machine context

- Hostname: `<your-machine-name>` — role: <your-machine-role, e.g. "primary dev desktop">
- OS: <your-os> · Shell: <your-shell>
- Notable hardware worth knowing when running builds/tests: <your-hardware-notes, e.g. "16 cores / 64GB RAM", or "nothing special">

## Key paths

| Path | Purpose |
|------|---------|
| `~/ai_workspace/` | This workspace — scripts, research, notes, machine work |
| <your-other-key-paths> | e.g. mounted drives, a projects directory, shared storage |

## Notes

- Action-first: do the work; only stop for a sudo password, a reboot, physical hardware,
  or GUI-only steps.
- When a durable fact about this machine is verified (a device path, a service, a quirk),
  record it here or in a memory file so the next session doesn't rediscover it.
- Project repos get their own `.claude/` context via `/setup-project` — don't accumulate
  project-specific detail in this file.
