---
name: setup-project
description: Scaffold a best-practice Claude Code .claude/ setup into the current repo and tailor it to the detected stack.
argument-hint: "[optional: path or notes]"
disable-model-invocation: true
allowed-tools: Bash(cp:*), Bash(mkdir:*), Bash(ls:*), Bash(test:*), Bash(chmod:*), Bash(mv:*), Bash(find:*), Bash(git remote:*), Read, Write, Edit, Glob, Grep
---

# Setup Project

Set up Claude Code for the repository in the current working directory, using the
bundled templates in this skill's `templates/` directory. The skill lives at
`~/.claude/skills/setup-project/` — reference templates by that absolute path.

Current directory:
!`ls -la`

Repo remote (for slug resolution):
!`git remote get-url origin 2>/dev/null || true`

Stack signals:
!`find . -maxdepth 2 -name node_modules -prune -o -type f \( -name package.json -o -name pnpm-lock.yaml -o -name yarn.lock -o -name package-lock.json -o -name pyproject.toml -o -name requirements.txt -o -name go.mod -o -name Cargo.toml -o -name '*.csproj' -o -name '*.sln' \) -print 2>/dev/null`

## Steps

1. **Confirm the repo root.** Look for `.git` plus a manifest (package.json, pyproject.toml, go.mod, Cargo.toml, *.sln). If this isn't a repo root, ask the user which directory to target before continuing.

2. **Resolve the project slug and plan location.** Slug = the git remote origin repo name, lowercased (basename of the URL above, minus `.git`); if there's no remote, use the current directory's basename.
   - Check `~/.claude/planning/REGISTRY.md` for a row with this slug (watch for collisions — same slug, different repo path).
   - Check whether this repo already has a local `.claude/planning/` tree. If it does, this project is `location: local` — its plan stays where it is (the spec skills use it as-is); don't create a central dir in step 4. Mention migration to `~/.claude/planning/<slug>/` is available at a natural boundary, but don't do it here.
   - Otherwise this project's plan will live centrally at `~/.claude/planning/<slug>/` (`location: central`), scaffolded in step 4.
   - Add or update the REGISTRY row: `| <slug> | <absolute repo path> | central|local | <one-line description> |`.

3. **Detect the stack** — language, package manager (from the lockfile), and the actual `lint` / `typecheck` / `test` / `build` / `validate` / `release` scripts. You'll fill these into the CLAUDE.md.

4. **Scaffold `.claude/`, never overwriting existing files.** For each target, only copy if it doesn't already exist:
   - `.claude/CLAUDE.md`        ← `~/.claude/skills/setup-project/templates/CLAUDE.md`
   - `.claude/settings.json`    ← `~/.claude/skills/setup-project/templates/settings.json`
   - `.claude/rules/engineering.md` ← `~/.claude/skills/setup-project/templates/rules/engineering.md`
   - `.claude/rules/typescript.md`  ← `~/.claude/skills/setup-project/templates/rules/typescript.md` (TS/JS projects only — skip otherwise)
   - `.claude/hooks/format.sh`  ← `~/.claude/skills/setup-project/templates/hooks/format.sh`  (then `chmod +x`)
   - `.claude/rules/planning-workflow.md` ← `~/.claude/skills/setup-project/templates/rules/planning-workflow.md`
   - `.claude/knowledge/INDEX.md` ← create empty (`# Knowledge Index` + a line noting researchers append a one-line hook per topic here). This is where research lives — project-local, versioned with the code, never inside the plan.
   - **Plan scaffold, only if step 2 found no local `.claude/planning/`** (`location: central`): `mkdir -p ~/.claude/planning/<slug>/specs` and copy `EXECUTION_PLAN.md` / `SPEC_INDEX.md` from `~/.claude/skills/setup-project/templates/planning/` into `~/.claude/planning/<slug>/` (fill in the project North Star). If `location: local`, the plan already exists there — nothing to scaffold.
   (Skip the plan + `planning-workflow.md` rule for trivial single-purpose repos that won't track multi-step work — ask if unsure. If step 6a will relocate an existing plan into the central dir, skip the two stub files there and let the real ones land.)
   If a `.claude/CLAUDE.md` already exists, suggest improvements instead of overwriting.

5. **Tailor the files to the detected stack:**
   - Fill in `.claude/CLAUDE.md`: project name, one-line purpose, real build/test/run commands, key directories, project-specific conventions. Keep it under ~150 lines.
   - Prune `rules/engineering.md` and `rules/typescript.md` to match the toolchain. For non-TS stacks, delete `typescript.md` and adapt the gates/standards (e.g. `cargo clippy && cargo test`, `ruff && mypy && pytest`, `go vet && go test`).
   - The bundled `format.sh` and the `PostToolUse` hook in `settings.json` already no-op when no formatter is installed — leave them unless the project has a different formatter.
   - **`@import` paths resolve relative to the importing file.** From `.claude/CLAUDE.md`, import a sibling as `@context/x.md` — NOT `@.claude/context/x.md` (which resolves to `.claude/.claude/...` and silently fails to load).

6. **Migrate prior planning & work context** (only if it exists). First detect what's there (Glob/Grep/Read): an existing plan structure (`.dev/planning/`, `.kiro/specs/`), and loose knowledge (`.kiro/steering/` esp. `*MEMORY_BANK*`/`CONTEXT.md`/`ARCHITECTURE.md`, `AGENTS.md`, `.cursorrules`, `.windsurfrules`, root `CLAUDE.md`, `TODO`/`ROADMAP`). Handle the two kinds **differently**:

   **6a — Relocate an existing execution plan INTACT (do NOT summarize it).** If a real plan structure exists (e.g. `.dev/planning/` with `EXECUTION_PLAN.md`/`SPEC_INDEX.md` and `specs/<area>/wsNN-*/`, possibly `_archived/`, `SPEC_CONVENTIONS.md`, `RESEARCH_INDEX.md`, `research/`), **move the plan tree verbatim into the central location `~/.claude/planning/<slug>/`** (create with `mkdir -p` if step 4 didn't already), preserving every spec folder, file, and status marker — these are implementation guides, not notes. Research is a separate move, into the repo, not the plan:
   - Move `EXECUTION_PLAN.md`, `SPEC_INDEX.md`, the entire `specs/` tree (including `_archived/`), and any `SPEC_CONVENTIONS.md` → `~/.claude/planning/<slug>/`. These **supersede the template stubs** created in step 4 (overwrite the empty `EXECUTION_PLAN.md`/`SPEC_INDEX.md`).
   - Move research (`RESEARCH_INDEX.md` + `research/`, or per-spec `_research/` folders) → **project-local** `.claude/knowledge/<topic-kebab>/` inside this repo — not into the central plan. Research is versioned with the code (see `~/.claude/rules/agentic-development.md`). Write/update `.claude/knowledge/INDEX.md` with a one-line hook per topic, and rewrite the moved specs' internal references from `research/…` to `.claude/knowledge/…`.
   - **Use plain `mv`, not `git mv`** — the plan is moving out of this repo into `~/.claude`, a *different* git repository, so there is no single-repo rename to preserve. If the source was tracked in this repo's git, `git rm -r` the old path once the copy is verified, so the removal itself is a normal commit here. `~/.claude` is its own git repo; the moved plan files land there uncommitted until the next `/sync-config` run — don't try to commit them through this repo's git.
   - Add or update the REGISTRY row for this slug to `location: central`.
   - **Verify the relocation (diff counts, spec count) before removing the source**; if anything is uncertain, copy and leave a `MOVED → ~/.claude/planning/<slug>/` pointer in the old location instead of deleting.
   - This relocated plan is the live source of truth the `/spec-new` · `/spec-run` · `/spec-status` skills drive.

   **6b — Condense loose context (summarize the still-relevant parts; never delete originals).** For accumulated knowledge that isn't a structured plan:
   - **Durable decisions, architecture, gotchas, lessons** → condense into `.claude/context/decisions.md` (referenced from CLAUDE.md), or `.claude/rules/` if they're enforceable standards.
   - **Investigation/research-shaped content** (library evaluations, API notes, comparisons) → `.claude/knowledge/<topic-kebab>/` instead, with an `INDEX.md` entry — not `decisions.md`.
   - **Project facts** (build/run commands, layout, conventions) → fold directly into `.claude/CLAUDE.md`.
   - Skip anything archived or obsolete.

   Report what was relocated vs condensed, from where, the spec count moved, and flag anything large you summarized so the user can verify nothing important was dropped.

7. **Gitignore.** Add `.claude/settings.local.json` to the repo's `.gitignore` if not already present. `.claude/knowledge/` is versioned **with** the code (committed, not gitignored) — it's why-context for the code. If this project's plan is `location: local` (a legacy `.claude/planning/` tree inside the repo), **preserve its tracking intent**: if its source (e.g. `.dev/planning/`) was gitignored, keep `.claude/planning/` gitignored too — it likely contains IP that shouldn't be committed; otherwise it's committed with the repo (team-shared). The central plan at `~/.claude/planning/<slug>/` lives outside this repo entirely, so there's nothing to gitignore for it. Confirm with the user if ambiguous.

8. **Report** what was created, what was tailored, what context was migrated, the plan's location (central/local) and its REGISTRY row, and what the user should review (commands, conventions, MCP servers if any).

## Notes
- This scaffolds the modern recommended layout: `CLAUDE.md` + `settings.json` (with a guarded auto-format hook + secret-deny rules) + path-scoped `rules/` + a `hooks/` script + a `.claude/knowledge/` research index + the central execution-plan workflow. Add `.mcp.json` or subagents per project as needed.
- Plan-driven workflow: `/spec-new` to scaffold a spec, `/spec-run` to implement it (plan mode → parallel `coder` fan-out via the Agent tool, validator-gated → finalize), `/spec-status` for the board. `~/.claude/planning/<slug>/` (or this repo's legacy local `.claude/planning/`) is the durable cross-session source of truth; `.claude/knowledge/` holds the research that informs it.

$ARGUMENTS
