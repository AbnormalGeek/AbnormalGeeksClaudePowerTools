# wsNN — <Spec Name> · Tasks

Numbered `N.M`. **No optional tasks.** Every task that creates logic creates/updates
its tests in the same task. Group independent tasks into waves and fan them out as
parallel `coder` subagents (via the Agent tool); sequence dependent waves. Mirror
tasks onto the native task board (`TaskCreate`/`TaskUpdate`, `blockedBy`) alongside
these checkboxes.

- [ ] 1. <task> — incl. tests (`tests/…`)
- [ ] 2. <task> — incl. tests
- [ ] 3. …

## Task N: Spec Finalization & Release
- [ ] N.1 Add/update integration/E2E tests for new user-facing flows (or mark N/A with reason — the suite must still pass)
- [ ] N.2 Run the full validation gate (validator subagent, level `full`: lint + typecheck + test:coverage + build [+ e2e])
- [ ] N.3 Update this plan's `EXECUTION_PLAN.md` (mark ✅, note deviations) and `SPEC_INDEX.md` (status → ✅, refresh "What Can Start Right Now") — at `~/.claude/planning/<slug>/` (central) or this repo's `.claude/planning/` (legacy local); see `~/.claude/planning/REGISTRY.md`
- [ ] N.4 Forward-propagate any discoveries into affected future specs
- [ ] N.5 Bump version (semver) + add a `CHANGELOG.md` entry (user-facing language)
- [ ] N.6 Commit (`chore: release vX.Y.Z — <spec>`); if pushing, confirm CI healthy (`/ci-check`)
