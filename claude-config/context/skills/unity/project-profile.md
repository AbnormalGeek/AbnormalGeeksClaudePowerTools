# Unity Project Profile — TEMPLATE

> Fill this in per-project. The other slices in this doctrine set
> (`cli-core.md`, `editor-tools.md`, `testing.md`, `seat.md`) are generic
> across any Unity project; this file is the one piece that is genuinely
> project-specific. Either edit this copy directly, or — if you want the
> generic slices to stay untouched and shareable — drop your filled-in
> version at `~/.claude/context-local/skills/unity/project-profile.md`, which
> the `unity-project-profile` loader skill prefers automatically.

## Project identity

- **Name:** `<project display name>`
- **Root path:** `<absolute path to the project root, e.g. ~/projects/my-game>`
- **Unity Editor version:** `<exact version, e.g. 6000.6.0bN — pin this, don't rely on a CLI default>`
- **Render pipeline:** `<Built-in | URP | HDRP, plus any custom setup>`

## Version control

- **VCS:** `<git | Plastic SCM | Perforce | other, and any dual-VCS quirks>`
- **Large-file handling:** `<Git LFS config, or N/A>`
- **Ignore/merge conventions:** `<e.g. how .meta/.unity/.prefab merge conflicts are handled, any generated dirs excluded from VCS>`

## Code contract & conventions

- **Assembly definition layout:** `<asmdef boundaries, or "none — single default assembly">`
- **Namespace/folder conventions:** `<pattern for where new scripts live>`
- **Style/lint tooling:** `<analyzers, formatters, editorconfig, if any>`
- **DI / architecture pattern in use:** `<e.g. manager singletons, a DI container, ScriptableObject-based events, ECS>`

## Test landscape

- **EditMode test assemblies:** `<paths/names>`
- **PlayMode test assemblies:** `<paths/names>`
- **Coverage/CI expectations:** `<what a green gate requires, current baseline pass count if known>`
- **Known-flaky or excluded tests:** `<list, with why>`

## UI kit, fonts, canvas conventions

- **UI system:** `<uGUI | UI Toolkit | both>`
- **Canvas setup:** `<scaler mode, reference resolution, sort-order conventions>`
- **Font assets:** `<TMP font assets in use, fallback chain>`
- **Component/prefab kit:** `<where reusable UI prefabs/styles live>`

## Vendored asset pack inventory

- **Third-party packs in use:** `<name, source, license, where imported under Assets/>`
- **First-party art/audio conventions:** `<naming, folder layout, import-setting defaults>`

## Editor & seat specifics

- **Editor-automation package (if any):** `<package id + version, e.g. a Pipeline/CLI-bridge package>`
- **Seat/connection model:** `<CLI-first multi-client | single-connection relay | none>`
- **Known per-project seat hazards:** `<e.g. specific dialogs, huge-prefab wedges, anything from live experience>`

## Planning

- **Planning-dir slug:** `<the slug this project uses under your planning-doc convention>`
- **Knowledge-dir path:** `<where project-local Unity research/knowledge lives, if separate from this profile>`
