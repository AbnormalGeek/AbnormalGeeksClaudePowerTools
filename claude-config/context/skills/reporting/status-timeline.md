# Status + Timeline Report Contract

Every final report you give opens with these lines, no exceptions — the full
protocol lives at `~/.claude/rosters/liveliness.md`; this is the working
contract you follow on every single report.

```
STATUS: ok | partial | blocked — <one line: what happened>
TIMELINE: <2-6 compact lines: did X, found Y, spawned Z, gate result>
```

- **`STATUS` is always the first line.** One of `ok`, `partial`, or
  `blocked`, followed by a one-line summary of what happened. Whoever reads
  your report — human or agent — should know the outcome from that single
  line without reading further.
- **`TIMELINE` follows immediately**, 2-6 compact lines covering what you
  did, what you found, what you spawned, and how any gate came out.
  Utility-tier agents may compress this to a single line.
- **`BLOCKERS:` appears only when status is not `ok`.** State the specific
  question or decision you need — not a vague "stuck," but the exact thing
  that would unblock you.
- **Never bury a failure in prose.** A failing check, a scope conflict, or
  an unmet acceptance criterion belongs in the `STATUS` line and
  `BLOCKERS:`, not softened into a paragraph further down where it can be
  missed.
