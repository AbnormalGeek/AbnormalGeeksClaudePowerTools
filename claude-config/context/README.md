# Context Library — reusable doctrine slices, composed into personas

> Installs to `~/.claude/context/`. A shared library of doctrine that agents load at
> spawn time, split into small reusable **slices** and grouped into **personas** —
> named, versioned bundles an agent or a session can pull in with one line instead of
> restating the same doctrine in every agent file.

## Purpose

Agent prompts and rules files tend to accumulate copy-pasted doctrine — the same
testing philosophy, the same review checklist, the same tone guide — repeated across
a dozen agent definitions. This library gives that doctrine one home. Write a concern
once as a slice, group the slices a role actually needs into a persona manifest, and
point agents/sessions at the persona instead of inlining the text.

## Structure

```
context/
  skills/
    <category>/
      <slice>.md
  personas/
    <group>/
      <persona>.md
```

- **`skills/<category>/<slice>.md`** — a leaf context slice. One doctrine concern per
  file. **Slices are always leaves: a slice never `@import`s or otherwise references
  another slice.** If a concern depends on another, that dependency belongs in the
  persona manifest (list both slices, in order), not inside the slice file.
- **`personas/<group>/<persona>.md`** — a thin manifest that groups slices for one
  role or one style of work. A persona references slices; it does not contain
  doctrine of its own beyond a short role summary.
- Max **3 nesting levels** below `context/` (e.g. `context/skills/<category>/<slice>.md`
  is 3 levels: `skills`, `<category>`, the file). Don't add a fourth.

## Manifest format

Every persona manifest follows this shape exactly:

```markdown
---
persona: <name>
group: <group>
description: <one line>
slices:
  - skills/<category>/<slice>.md   # paths relative to context/ root, order = load order
---
# Persona: <group>/<persona>
<1-paragraph role summary>

@../../skills/<category>/<slice>.md   # one @ line per slice, same order
```

The frontmatter `slices:` list and the body's `@` lines must stay in sync — same
files, same order. The frontmatter is the machine-readable manifest (read by the
generator); the `@` lines are what make the persona work as a session-level import.

## Dual consumption

A persona is written once and consumed two different ways:

**(a) Session-level, via `@import`.** A `CLAUDE.md` or rules file can `@import` a
persona manifest directly; the manifest's `@` lines then pull in each slice in turn.
This relies on an empirical platform fact: **`@import` expands only inside the
CLAUDE.md/rules-file import chain — it never expands inside an agent definition
body.** Session-level consumption is therefore for CLAUDE.md/rules files only.
Import chain depth is capped at 5 hops, so a persona → slice chain that sits ≤3
levels below the importing entry point stays well inside that budget.

**(b) Agent-level, via a generated loader skill.** Agent definitions can't `@import`
a manifest directly (see above), so `tools/gen-persona-skills.sh` reads each
manifest's frontmatter `slices:` list and generates a loader skill named
`persona-<group>-<persona>` under `claude-config/skills/`. The generated skill's body
`!cat`s the slice files live from `~/.claude/context/` at invocation time — the same
proven pattern already used by the `roster-sdm` / `roster-sde` / `liveliness` loader
skills. An agent lists that generated skill name in its own frontmatter `skills:`
list to pick up the persona.

## Regeneration workflow

1. Edit slice files and/or persona manifests under `context/`.
2. Run `tools/gen-persona-skills.sh` from the repo root.
3. Commit both the edited source and the regenerated skill(s) together.

Generated skills are marked `AUTO-GENERATED` in their own header — never hand-edit a
generated skill file; edit the source manifest/slices and regenerate instead.

## Local overlay: `~/.claude/context-local/`

The library convention supports a private overlay that mirrors this layout —
`~/.claude/context-local/skills/<category>/<slice>.md` and
`~/.claude/context-local/personas/<group>/<persona>.md` — for slices and personas
that are private or site-specific and must never ship in this public repo. The
installer creates the empty directory; this repo ships the convention only, never
any content under it. If you keep `~/.claude` itself in a personal git repo, add
`context-local/` to that repo's `.gitignore` so private slices never get committed
there either.

## Naming

- Slice, category, group, and persona names are **kebab-case**.
- Each slice file holds **one** doctrine concern — split rather than combine.
- A slice **references** canonical rules/roster files where one already exists
  (e.g. `claude-config/rules/testable-business-logic.md`) instead of duplicating
  their content verbatim. Slices add composition and framing on top of canonical
  sources; they are not a second copy of them.
