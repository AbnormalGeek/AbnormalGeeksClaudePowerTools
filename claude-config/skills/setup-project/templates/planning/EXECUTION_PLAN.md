# Execution Plan — <PROJECT>

**Authoritative source of truth.** Workstreams, dependencies, waves, and status.
Quick status lives in `SPEC_INDEX.md`; per-spec detail in `specs/`.

## North Star
> One-paragraph: what this project is and the outcome this plan drives toward.

## Locked Decisions (ADRs)
- (Decisions made during research/planning — do not re-litigate. Date them.)

## Workstreams
A workstream = a small, independently-deployable slice (~2–5 dev-days incl. tests + deploy).
Cross-package dependencies go in separate workstreams. 1 point ≈ 1 dev-day.

| WS | Name | Pts | Status | Depends on | Wave | Notes |
|----|------|-----|--------|-----------|------|-------|
| ws01 | … | 3 | ⬜ | — | 1 | … |

Status: ⬜ Not Started · 📋 Spec Created · 🔨 In Progress · ✅ Complete · 🔴 Blocked

## Parallelization Waves
- **Wave 1** (no deps): ws…
- **Wave 2** (after wave 1): ws…

<!-- Archive completed milestones to specs/_archived/ and reset this file; see ARCHIVED_CONTEXT.md. -->
