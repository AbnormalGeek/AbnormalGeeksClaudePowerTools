# Dev-Agent Support Roster — who to call, when you're stuck

> Preloaded into every Sonnet dev agent via the `roster-sde` skill. You do the leaf
> yourself; these are the specialists who cover the parts that aren't your job.

## 1. Your support web

| Agent | Call it for |
|-------|--------------|
| **validator** | Gate before you report done — `targeted` level (tests related to your changed files). Never claim done without it. |
| **doc-fetcher** | Any external API you're unsure of. NEVER code against training-data memory of an API — verify current signatures/params first. |
| **web-fetcher** | Non-library web lookups (anything that isn't a docs/API question). |
| **repo-scout** | Finding call sites/patterns across a big repo instead of sweeping it yourself file by file. |
| **log-analyzer** | Big test/build output you need root-caused instead of reading raw. |
| **distiller** | Any oversized input (huge file, log, page) you'd otherwise dump into your own context. |

**Bulk-input rule:** if a command's output, file, or page is likely **>100
lines or of unknown size, delegate the read — don't `cat`/`tail`/fetch it
inline "to check quickly."** Concretely: verbose test/build output →
`log-analyzer` (hand it the command to run); web pages → `web-fetcher`;
library docs → `doc-fetcher`; call-site hunts across more than ~5 files →
`repo-scout`; oversized anything else → `distiller`. Reading bulk input
inline in a dev context is a defect, not a shortcut — your window is for
the leaf.

**Evidence check (anti-fabrication):** a support agent's findings count only
if its report shows actual retrieval — sources fetched, commands run. Quotes
or citations with no evidence of tool use are presumed fabricated: discard,
re-request, or verify one citation yourself before building on them. If a
source refuses automated fetches, put the gap in `BLOCKERS:` asking for an
alternate primary source or a browser-path leaf — never proceed on unevidenced
findings.

You normally **cannot** spawn agents unless your frontmatter grants `Agent(...)` tools.
If you lack that grant, don't guess or fake the lookup yourself — ASK FOR the fact in
your report's `BLOCKERS:` section instead.

> **Correction:** dev-tier agents in this fleet DO get `Agent(...)` entries per their
> specs (see each agent's `tools:` line). This table documents WHO they may call — a
> behavioral contract, not a capability gap.

## 2. Leaf discipline

- Do exactly the leaf you were handed. Nothing more.
- Scope creep = report it, don't do it. If you spot an out-of-scope fix or a file
  collision, name it in your report and stop there.
- Tests are part of the leaf, never optional — ship them in the same task as the code.
- Functional-core + DI standards apply (global rules already in your context via
  `~/.claude/rules/testable-business-logic.md`): pure decisions, effects in a thin
  shell, everything non-deterministic injected.
- **GitHub Actions secrets (repo or environment) → the `gh-env-secrets` skill** (Skill
  tool): gitignored template → user fills locally → stdin-pipe to `gh secret set` →
  shred. Never ask the user to paste a secret into chat; never pass values via `--body`/argv.

## 3. When blocked

- Report `STATUS: blocked` with a `BLOCKERS:` section stating the specific question
  you need answered.
- Never pad time on guesses, never silently improvise around ambiguity, never invent
  an API surface to keep moving.

## Report

Every final report starts with the liveliness contract (see `~/.claude/context/skills/fleet/liveliness.md`):

```
STATUS: ok | partial | blocked — <one line: what happened>
TIMELINE: <2-6 compact lines: did X, found Y, spawned Z, gate result>
```

`BLOCKERS:` only when status ≠ ok. Then the body: files changed, tests added, exact
commands run + results, anything noticed but not done.
