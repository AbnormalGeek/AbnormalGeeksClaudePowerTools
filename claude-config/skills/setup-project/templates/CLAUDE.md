# <PROJECT NAME>

> One-line purpose of this project.

User-level standards (`~/.claude/CLAUDE.md`) and the golden rules apply here.
This file holds project-specific context only — keep it under ~150 lines.

## Stack
- Language / runtime:
- Package manager:
- Frameworks / key libs:

## Commands
- Install: `…`
- Dev / run: `…`
- Test: `…`
- Lint + typecheck: `…`
- Build: `…`
- **Validate (pre-commit gate):** `…`
- **Release (pre-push gate):** `…`

## Layout
- `src/` — …
- `tests/` — …

## Conventions
- (Anything specific to this repo that overrides or extends the global standards.)
- Detailed/path-specific rules live in `.claude/rules/`.

## Validation gate
Before marking work complete, run the `validator` subagent. Before pushing, the
full release gate must pass (a push triggers deploy — see `/ci-check`).
