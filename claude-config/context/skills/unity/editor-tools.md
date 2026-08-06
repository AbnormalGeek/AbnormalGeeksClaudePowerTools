# Unity Live Editor Tool Catalog — Warm-Path Contract

> Doctrine for the tool surface a running Editor exposes over its live
> command/MCP transport (an "editor automation package" in generic terms —
> whatever plugin your project uses to expose scripted Editor control). Tool
> names below are illustrative `snake_case` conventions from a real probed
> catalog (~140 tools); re-enumerate your own project's live tool list rather
> than trusting an exact count, since this surface moves between package
> versions.

## Invocation contract (read this before calling anything)

- Invoke via `unity command <tool> [params] --project-path "<root>" --timeout
  <seconds>`. Default timeout is short (order of 30s) — raise it for slow
  operations or use the fire-and-poll pattern below instead of waiting.
- Preflight with a live status check and require a ready state before any
  tool call.
- Connect over loopback explicitly (`127.0.0.1`, not `localhost` — some
  Editor HTTP listeners don't reliably serve IPv6 loopback).
- The port and auth token are read from a per-project descriptor file and
  **rotate on every domain reload** (including entering Play mode). Never
  cache a token across a recompile — re-read the descriptor.
- Long-running operations (builds, bakes, recompiles, test runs) return
  immediately and expose a matching `*_status` poll command. Poll those, not
  the triggering call.
- `dry_run` is a stated convention, **not a verified guarantee** on every
  tool — a preview flag has been observed to still perform the real mutation
  on at least one tool in a live probe of one such package. Treat `dry_run`
  as unverified per-tool until you've confirmed it live for the specific
  tool you're relying on, and plan cleanup accordingly.

## Categories (representative, not exhaustive)

Group tools by concern; the exact set and count is package/version-specific.
Typical categories in an Editor-automation surface:

- **Editor lifecycle & tests** — enter/exit/pause play mode, force a
  recompile (+ poll its status), list/run/cancel tests, execute a menu item
  by path (the escape hatch for anything not covered by a dedicated tool),
  screenshot the Scene/Game view.
- **Animation** — animator controllers/layers/parameters/states/transitions,
  animation clips and curves, Timeline tracks/clips.
- **Assets & files** — copy/move/rename/delete an asset, import an external
  file, read/write project text files, read/set import settings.
- **Baking** — lighting/NavMesh/occlusion bakes, each async with its own
  status-poll and cancel command, plus read/set of the underlying settings.
- **Build & build settings** — trigger an async player build and poll its
  report, read/set build settings, list build targets/profiles, switch the
  active build target (destructive + long-running).
- **Capture** — render the Scene or Game view (or a runtime UI element) to a
  PNG.
- **GameObjects & components** — create/find/delete/rename GameObjects
  (single or batch), add/remove/inspect components, set transform/parent/
  layer/tag/active-state.
- **Materials & shaders** — read/set material properties, introspect shader
  properties, list available shaders.
- **Package Manager** — add/remove/resolve/list/search packages, each async
  with a status-poll (adding or removing triggers a recompile — poll that
  too).
- **Prefabs** — create/instantiate a prefab, create a variant, apply/revert
  overrides, unpack an instance.
- **Project settings** — read/set audio, graphics, physics, player, quality,
  tags & layers, time, and input settings.
- **Scenes** — create/open/save scenes, list open scenes, manage the build
  scene list, read the GameObject hierarchy of an open scene.
- **Scripts** — create a C# script from a template (its type does not exist
  until the next recompile completes), attach a script/component, read/set
  serialized fields.
- **Observability** — read/clear captured console output, read
  performance/frame-timing stats, read/set the current Editor selection, run
  a search query.
- **Shared runtime surface** — a small set of commands (console read,
  arbitrary C# eval via a Roslyn-style command, hot-reload apply) that work
  against both an Editor and a running Player build.

Runtime-only surface (only reachable against a Player build, not an Editor):
application status/quit, target framerate/timescale, log-to-console,
simulated input, runtime UI-element capture, hot-reload cleanup.

## Safety-flag conventions

Two independent boolean flags, both default `false`:

- **`confirm`** — the tool refuses to run without it. Applied to genuinely
  destructive or high-impact operations (delete an asset, most settings
  writes, switching the build target).
- **`dry_run`** — validates and reports what would happen without changing
  anything (see the caveat above — verify per tool before trusting it).

Not every destructive-sounding tool is gated this way — GameObject/component
removal, prefab unpack/revert, and raw serialized-field writes often rely on
the Editor's own Undo system instead of a confirm flag. Treat anything that
mutates scene or asset state as live-fire unless you've confirmed otherwise,
and any "evaluate arbitrary code against the Editor" tool as the single most
dangerous one in the catalog — gated only by transport auth, not by
confirm/dry_run.

## Poll-safe (non-main-thread) commands

A small subset of commands are safe to call while the Editor's main thread is
busy with something else — typically the `*_status` pollers (test, build,
recompile, and each bake type), a console/log reader, and package-manager
commands (which internally hand off to the main thread). Everything else
defaults to running on the main thread and will queue behind other
main-thread work from any connected client. Design polling loops around the
non-main-thread set; don't spin a main-thread command in a tight loop.
