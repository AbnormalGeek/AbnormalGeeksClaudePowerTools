# Engineering Standards

Extends the global standards in `~/.claude/CLAUDE.md`. Loaded unconditionally
(no `paths` frontmatter). Adapt to the actual stack when scaffolding.

## Architecture — Three-Layer Pattern
```
HANDLERS (presentation) → SERVICES (business) → REPOSITORIES (data)
```
- Handlers: no business logic, no direct DB access.
- Services: no presentation concerns, no direct DB access.
- Repositories: no business logic; transform data before returning.

## Type Safety & DI
- **Zero tolerance for `any`** — use proper types, generics, or `unknown` + type guards.
- Inject dependencies via constructor; never `new Database()` inside a service.

## Testing
- Every feature/logic change ships with passing tests. Targets: **70% lines/functions, 60% branches.**
- Tests independently runnable; Arrange-Act-Assert; file naming `[Component].test.ts`.

## Naming
| Type | Convention | Example |
|------|------------|---------|
| Variables/Functions | camelCase | `getUserById` |
| Classes/Components | PascalCase | `UserService` |
| Files/Directories | kebab-case | `user-service.ts` |
| Constants | UPPER_SNAKE | `MAX_RETRIES` |

## Git & Validation Gates
- **Commit** only when green. Conventional commits: `type(scope): description`.
- **Pre-commit gate:** `validate` (lint + typecheck + test:coverage).
- **Pre-push gate:** `release` (validate + e2e + build). Run it yourself before pushing — never bypass with `--no-verify`. A push triggers deploy → not done until CI is healthy (`/ci-check`).
- Use the `validator` subagent as the completion gate.

## Changelog (when versioning)
Keep a Changelog + SemVer. Always a version number; group by Added/Changed/Fixed/Removed/Deprecated/Security; user-facing language; ISO dates; newest first.
