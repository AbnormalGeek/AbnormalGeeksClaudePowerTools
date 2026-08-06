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
| `skills/delegation/bulk-input.md` | Route oversized or unknown-size input to a utility agent instead of reading it inline. |
| `skills/ops/credential-hygiene.md` | Treat a domain operator's credentials as material that must never enter a transcript, report, or committed file. |
| `skills/unity/cli-core.md` | The Unity CLI's command surface, invocation defaults, exit-code caveats, and concurrency/locking contract. |
| `skills/unity/editor-tools.md` | The live Unity editor tool catalog's invocation contract, tool categories, and safety-flag conventions. |
| `skills/unity/testing.md` | Unity's test-gate doctrine: live run for leaf gates, batch-on-a-clone for milestone gates, NUnit XML as the only truth. |
| `skills/unity/seat.md` | Unity editor access protocol: CLI-first multi-client concurrency etiquette and the legacy relay fallback. |
| `skills/unity/project-profile.md` | Per-project Unity parameterization: how a Unity agent resolves project path, editor version, and package profile instead of assuming one fixed project. |

### Fleet doctrine slices (consumed differently)

> `skills/fleet/*` are read live by the hand-maintained `roster-sdm` / `roster-sde` /
> `liveliness` skills (each `!cat`s its file, private `context-local/` overlay first, then
> this shared copy) and by the `CLAUDE.md` `@import` of `fleet-map.md`. They are **not**
> wired into the generated-persona system above; listed here for discoverability only.

| Path | Hook |
|------|------|
| `skills/fleet/fleet-map.md` | WHO does what: the delegation rules and tier tables every session and subagent inherits via the CLAUDE.md `@import`. |
| `skills/fleet/sdm-playbook.md` | HOW orchestrators delegate: the atomic-leaf contract, waving, gating, and growing the roster. |
| `skills/fleet/sde-support.md` | WHO a dev agent calls when stuck: the support web (validator, doc-fetcher, web-fetcher, repo-scout, log-analyzer, distiller) plus leaf discipline. |
| `skills/fleet/liveliness.md` | The five-channel liveliness protocol so the terminal never looks dead while work is delegated. |

## Personas

| Persona | Loader skill | Slices | Intended agent roles |
|---------|---------------|--------|------------------------|
| devs/core | `persona-devs-core` | atomic-leaf, functional-core, validation-loop, status-timeline | implementation/dev agents |
| devs/unity | `persona-devs-unity` | atomic-leaf, bulk-input, status-timeline | engine/editor-side implementation agents (Unity code/asset/UI dev) |
| ops/domain | `persona-ops-domain` | credential-hygiene, extract-contract, status-timeline | sole-operator domain agents (one external/infra service's credentials) |
| ops/git | `persona-ops-git` | golden-rules, status-timeline | git/CI operator |
| ops/steward | `persona-ops-steward` | precision-editing, status-timeline | config stewards |
| orch/lead | `persona-orch-lead` | delegation-discipline, status-timeline | orchestrators |
| research/deep | `persona-research-deep` | verify-living-facts, extract-contract, status-timeline | deep research specialists |
| utility/gate | `persona-utility-gate` | extract-contract, status-timeline | validation gate |
| utility/scout | `persona-utility-scout` | extract-contract, status-timeline | search-and-retrieve agents (repo/asset scouts) |
| utility/sponge | `persona-utility-sponge` | read-only, extract-contract, status-timeline | read-only utility sponges |

See `README.md` for the slice/persona structure and the manifest format.
