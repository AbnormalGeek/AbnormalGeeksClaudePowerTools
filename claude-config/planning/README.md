# Central Planning — all projects

Cross-project execution plans live here, one directory per project slug:

```
~/.claude/planning/
  REGISTRY.md          ← slug → repo path → description (the index; keep current)
  <slug>/
    EXECUTION_PLAN.md  ← authoritative status, decisions, next steps
    SPEC_INDEX.md      ← spec board (quick-reference status)
    specs/<area>/wsNN-<name>/   ← requirements / design / tasks triads
```

- **Slug** = git remote origin repo name (lowercased); else directory basename.
  Check REGISTRY.md for collisions before creating a new dir.
- Research/knowledge does NOT live here — it is project-local at
  `<repo>/.claude/knowledge/<topic>/` and versioned with the code.
- Legacy project-local `.claude/planning/` trees still work; the spec skills
  detect them. Migrate by moving the tree here + adding a REGISTRY row at a
  natural boundary.
- Full conventions: `~/.claude/rules/agentic-development.md`.
