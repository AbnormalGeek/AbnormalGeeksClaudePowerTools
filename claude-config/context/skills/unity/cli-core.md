# Unity CLI Working Contract

> Doctrine for the standalone Unity CLI (`unity` binary) — an experimental-beta tool
> as of this writing. Re-verify command/flag/exit-code specifics against
> `unity --help` and the CLI release notes after any `unity upgrade`; this is a
> living surface, not a frozen spec.

## Invocation defaults

Always run with `--no-banner --non-interactive --format json` (or the env
equivalents `UNITY_NO_BANNER=1 UNITY_NON_INTERACTIVE=1 UNITY_FORMAT=json`).
Format auto-selects `human` on a TTY and `tsv` when piped, so pin `json`
explicitly for any scripted/agent caller. JSON responses use one envelope:
`{success, command, data, errors, warnings}` on stdout; diagnostics go to
stderr. `ndjson` emits typed progress frames for long operations.

## Command surface, by group

- **Live editor control** (needs the project's editor package installed + a
  running Editor): `unity status` (who's connected), `unity list` (tool
  catalog), `unity command <name> [args]` (invoke a tool), `unity mcp`
  (stdio MCP server for the connected Editor).
- **Batchmode wrappers** (headless, spawn a NEW editor, do **not** touch a
  running one): `unity build --target <t> --execute-method <M>` (both
  required — there is no built-in CLI build, you must supply a static C#
  entry point), `unity test [--mode EditMode|PlayMode] [--output <xml>]`
  (writes an NUnit XML report), `unity run`, `unity open` (GUI launch).
- **Editor & module management** (Hub replacement): `unity install`,
  `unity uninstall`, `unity editors list|add|default|upgrade`, `unity releases`.
- **Projects & templates**: `unity projects list|add|create|clone|open|...`,
  `unity templates ...`.
- **Account, cloud, licensing**: `unity auth login|status`, `unity license
  activate|status|return`.
- **Diagnostics/config/session**: `unity doctor`, `unity logs`, `unity cache
  info|clean`, `unity shell` (warm REPL — avoids per-call cold-start cost;
  worth using for any agent issuing many commands in a session).

## Exit codes — do not trust them alone

`0` success, `1` general error, `2` usage error (and no JSON envelope at all,
even with `--format json`), `3` auth failure, `4` config required, `6`
**overloaded** — covers "no Editor running", "project not found", "tests
failed", and "install failed" alike, `130`/`143` signal exits.

Underneath the new CLI, the classic batchmode lie survives: a build/test can
exit `0` with no artifact produced, or fail without setting a nonzero code.

**Design rule:** never map exit code → meaning directly. Branch on
`success` + `errors[].code` + `errors[].message`, and independently verify
artifact existence (NUnit XML present? build output present?) and grep the
log. For anything routed through a custom `-executeMethod`, call
`EditorApplication.Exit(code)` explicitly from your own C# rather than
relying on `-quit`.

## Concurrency and locking

**Hard boundary: one Editor process per project directory.** Unity enforces
this via `<project>/Temp/UnityLockfile` — a batchmode command (`test`,
`build`, `run`) cannot run while an interactive Editor holds the same
project, and it is a hard exclusion, not a queue. Two batchmode commands
against the same project also cannot run concurrently. Stale locks from a
crashed process are real and block everything after them.

**What IS concurrent:** many clients against one running Editor. The Editor
runs a local HTTP server (a fixed port range, a git-ignored port-descriptor
file with a bearer token that **rotates on every domain reload**); any
number of processes can connect with no seat/connection gate. But execution
still serializes on the Editor's main thread — commands marked
main-thread-required queue behind one another. A handful of read-only/status
commands opt out of that and run on a background thread; poll those instead
of blocking on a slow main-thread call, and raise the command timeout for
known-slow operations (bakes, recompiles) rather than assuming the default
is enough.

**Practical rules:**
1. One writer per Editor — treat scene/asset mutation as a critical section
   even though multiple clients can connect; reads fan out freely.
2. Never run a batchmode command against a project whose Editor is open.
   Either close the Editor, use a live in-Editor test/run tool instead, or
   run batch work against a separate clone of the project tree.
3. Preflight every session with a live status check and require a ready
   state before any call — turns a confusing timeout into a clear signal.
4. Re-read the port/token descriptor after any recompile or domain reload.
5. Give batch work its own clone/worktree when it must run alongside an
   open interactive Editor. Costs a second local build cache; the standard
   trade for letting automated tests and a human editor coexist.

## Failure modes worth designing around

| Symptom | Likely cause | First action |
|---|---|---|
| rc 2, no JSON | bad flag/typo | fix invocation |
| rc 3 | stale/rejected auth session | re-authenticate |
| rc 6 + "no instances" | no live Editor reachable | fall back to batchmode or start one |
| rc 6 + "not a project" | wrong path | resolve via the project-list command |
| rc 6 + NUnit XML present, failures>0 | genuine test failures | report them |
| rc 6 + no XML | infrastructure failure | read the log, re-run preflight |
| rc 143 | your own timeout/SIGTERM fired | report as timeout, raise it |
| rc 0, no artifact | the batchmode lie | treat as FAILURE, grep the log |
| hang, no output growth | shader/import hang or a stale lock | check the project lockfile, kill, report |

Additional classes to keep in the harness: license/seat exhaustion in
headless license flows (always pair activation with a trapped release-on-exit
so a killed agent doesn't burn a seat); Editor-version drift (pin and pass
the editor version explicitly on every batchmode call — a version-mismatch
upgrade dialog blocks batchmode forever); modal dialogs and unsaved-scene
prompts stopping an unattended session dead (launch with an automated/
unattended flag where the CLI supports it); first-run/cold-Library import
cost being an order of magnitude slower than a warm run (never delete the
local build cache as a troubleshooting reflex — clear specific stale
sub-caches instead); and general beta churn (pin the CLI version, upgrade
deliberately, re-verify the exit-code/flag contract after every bump).
