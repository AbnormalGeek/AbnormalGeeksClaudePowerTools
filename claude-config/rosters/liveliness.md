# Liveliness Protocol — the terminal must never look dead

> Why: when everything is delegated to agents, the user sees silence unless we
> deliberately surface progress. Five channels below — the first two are automatic
> (hooks + statusline); the last three are YOUR job. Loaded into orchestrators and
> dev agents via the `liveliness` skill.

## Automatic channels (already wired — don't duplicate them)

1. **Lifecycle hooks**: `SubagentStart`/`SubagentStop` hooks print `▶ <agent> started`
   / `✔ <agent> done` system lines and maintain `~/.claude/state/subagents-live.json`.
2. **Statusline**: refreshes every second and renders the live agent count + names from
   that state file, so the footer always shows the web working.

## Channel 3 — Orchestrator narration (every orchestrator, every wave)

- Before each spawn or wave: one line — `▶ started: <what> → <agent>(s)`.
- After each result lands: one line — `✔ done: <what> — <one-clause outcome>`.
- Before each gate: `⟳ gate: <validator/reviewer> on <what>`.
- On direction change or blocker: one plain sentence, immediately.
- Only TOP-LEVEL text reaches the user. If you are the main session, narrate what your
  orchestrator subagents report. If you are a subagent orchestrator, your narration
  duty becomes your TIMELINE (below) so your parent can relay it.

## Channel 4 — Native task board

- Orchestrators create the wave plan as tasks (TaskCreate) BEFORE fanning out, set
  in_progress when a leaf starts, completed when its gate passes. The user watches
  live via Ctrl+T. Use blockedBy to encode wave ordering. Never a hand-rolled
  markdown checkbox board.

## Channel 5 — Report contract (EVERY agent's final report)

First lines of every final report, no exceptions:

```
STATUS: ok | partial | blocked — <one line: what happened>
TIMELINE: <2-6 compact lines: did X, found Y, spawned Z, gate result>
```

Then the body your caller asked for. `BLOCKERS:` section only if status ≠ ok, with
what you need. Never bury a failure in prose — the STATUS line is where parents and
users look first. Utility (Haiku) agents may compress TIMELINE to one line.

## Rules of thumb

- Narration lines are ≤1 line each, present tense, no filler ("▶ started: JWT refresh
  leaf → ts-dev" beats a paragraph).
- Silence longer than one wave is a protocol violation — if a long-running leaf is
  still going, say so ("⏳ still running: full validation suite, ~2min in").
- Don't spam: one line per event, not per tool call.
