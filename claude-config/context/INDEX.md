# Context Library Index

One-line purpose: quick lookup of every slice and persona in this library, and what
each one is for.

> Loader skills (`claude-config/skills/persona-*/`) are **auto-generated** by
> `tools/gen-persona-skills.sh` from the manifests in `personas/` — never hand-edit
> a generated skill; edit the manifest/slices and rerun the generator.

## Slices

| Path | Hook |
|------|------|
| `skills/code/atomic-leaf.md` | Do exactly one leaf of work per invocation, staying inside acceptance criteria and scope so parallel agents never collide. |
| `skills/code/functional-core.md` | Compressed functional-core + DI statement: pure decisions, effects pushed to a thin shell, nothing hidden non-deterministic. |
| `skills/code/validation-loop.md` | Verify unfamiliar APIs live before coding against them, then close every leaf with a targeted gate before claiming done. |
| `skills/config/precision-editing.md` | Treat shared config/agent/roster/rules edits as exact-spec-in, exact-edit-out — no scope creep, no incidental reformatting. |
| `skills/git/golden-rules.md` | Non-negotiable git/GitHub mechanics: no attribution trailers, conventional commits, gates before pushing. |
| `skills/orchestration/delegation-discipline.md` | Plan, sequence, gate, and integrate; delegate all reading/research/scanning/implementation to subagents. |
| `skills/reporting/status-timeline.md` | The STATUS/TIMELINE report contract every agent opens its final report with. |
| `skills/research/verify-living-facts.md` | Never answer a versioned/living-software question from training data; verify against a current authoritative source first. |
| `skills/utility/extract-contract.md` | Return only the facts the caller asked for, with identifiers preserved verbatim — never a raw dump. |
| `skills/utility/read-only.md` | Observe and report without changing state — no writes, installs, or destructive commands. |

## Personas

| Persona | Loader skill | Slices | Intended agent roles |
|---------|---------------|--------|------------------------|
| devs/core | `persona-devs-core` | atomic-leaf, functional-core, validation-loop, status-timeline | implementation/dev agents |
| ops/git | `persona-ops-git` | golden-rules, status-timeline | git/CI operator |
| ops/steward | `persona-ops-steward` | precision-editing, status-timeline | config stewards |
| orch/lead | `persona-orch-lead` | delegation-discipline, status-timeline | orchestrators |
| research/deep | `persona-research-deep` | verify-living-facts, extract-contract, status-timeline | deep research specialists |
| utility/gate | `persona-utility-gate` | extract-contract, status-timeline | validation gate |
| utility/sponge | `persona-utility-sponge` | read-only, extract-contract, status-timeline | read-only utility sponges |

See `README.md` for the slice/persona structure and the manifest format.
