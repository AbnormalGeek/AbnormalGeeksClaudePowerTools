# Unity Editor Access Protocol (Multi-Client, CLI-First)

> If your Unity workflow uses a standalone CLI with a multi-client live
> transport, the old "one exclusive connection" relay model no longer
> applies — read this before assuming you need to wait for a seat. If your
> setup instead uses a single-connection relay/plugin, skip to the legacy
> section below; that model still applies there.

## CLI-first facts (generalize to your installed tooling)

- A standalone CLI binary talks to a running Editor's live command surface
  over HTTP; any number of processes can point at the same project and each
  gets its own live connection — no plan/approval gate, no single-seat
  limit.
- Prerequisite: the project has the editor-automation package installed and
  a running Editor.
- Tool surface is a flat set of commands (illustrative naming:
  `get_scene_hierarchy`, `run_tests`, `screenshot`, `eval`, `find_assets`,
  `create_prefab`, ...). If your project also has an older relay-style
  integration, don't mix tool-naming conventions across the two paths in one
  call — they are different surfaces.
- Preflight with a live status check; require the Editor to report
  discoverable and ready before any call. This replaces any older
  seat-preflight script as the primary check.
- Default access path is direct CLI invocation of a named command; an MCP
  server (if your CLI offers one) is only needed for clients that specifically
  want typed MCP tools rather than shelling out.

## Concurrency etiquette (load-bearing)

Connections are parallel, but the Editor is still one shared brain —
concurrency rules live at "who mutates what," not "who holds the
connection":

- **Reads fan out freely.** Queries, captures, console reads, hierarchy/asset
  lookups — any agent, any time, no coordination needed.
- **Mutations stay single-writer per asset.** Scene/prefab/asset files are
  still non-mergeable serialized data and Editor state is still global —
  assign exactly one mutating agent per scene/prefab per work window. This
  is a planning discipline, not a connection limit.
- **Domain reloads are global barriers.** Script edits, package operations,
  and entering Play mode trigger a domain reload that hits every connected
  client simultaneously, whether they asked for it or not. Schedule these
  explicitly between work windows — never trigger one mid-window while other
  callers have in-flight reads/mutations.
- **Test runs still serialize.** The Editor's test-runner is one queue
  regardless of how many clients are connected — gate concurrent test
  requests with your own lock (e.g. an `flock`'d wrapper) exactly as you
  would for the legacy path.
- **On any error:** report it plainly. Don't ladder-recover or retry-hammer,
  and don't chase a "seat" that doesn't exist as a concept on the CLI path —
  that laddering belongs to the legacy relay model only.

## Preflight — mandatory before any editor-facing work

1. Run a live status check and confirm the Editor is discoverable and ready.
2. Smoke one cheap read tool (e.g. read the scene hierarchy) before planning
   any mutation work.
3. Not discoverable / not ready → confirm the Editor process is actually
   running and the CLI/package install is intact; report blocked with the
   exact status output if it doesn't resolve. Don't silently fall back to a
   legacy relay path unless directed to.

## Routing for multi-agent setups

If you run multiple agents against Unity, keep nontrivial CLI operations
(editor lifecycle, batch test/build runs, package/project registry
operations) behind one designated operator role so they don't collide.
Agents that only need their own read/capture/mutation loop against an
already-open Editor can keep direct access to the live command surface.

## LEGACY — single-connection relay fallback

Use only if your CLI-first path is broken or unavailable for your setup. An
older single-connection relay/plugin model (e.g. a first-party AI-assistant
relay predating a standalone CLI) may still be plan-gated at exactly one
connection — a second client gets an explicit "plan doesn't include this"
error. If you're on that path:

- Binding happens at agent-session spawn; a resumed toolless session needs a
  fresh spawn, not a resume. Editor restarts change the underlying
  PID/socket — preflight, then spawn fresh.
- "Connection revoked" is usually an orphaned client or relay entry still
  holding the single slot — kill the orphan process rather than restarting
  the Editor. Genuine approval loss in the Editor's own settings is a human
  gate; report blocked rather than trying to click through it
  automatically.
- If your setup uses a persistent-connection daemon to survive Play-mode
  domain reloads, hold ONE persistent client open across any Play/reload
  span — a one-shot client disconnecting mid-Play can destabilize the
  Editor on some plugin versions.
- Seat discipline: one relay holder per work phase; orchestrators delegate
  holding/recovering it to a designated agent rather than doing it inline.
