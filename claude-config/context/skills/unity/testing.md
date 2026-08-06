# Unity Test Gates — CLI Doctrine

> Supersedes any hand-rolled `Unity -runTests -batchmode ...` invocation.
> Re-verify against your installed CLI version — flags and exit-code
> semantics are still moving on an experimental-beta CLI.

## Gate split (non-negotiable)

- **Targeted / leaf gate → LIVE run.** Trigger the async run-tests tool
  against the already-open Editor, then poll its status tool (a
  non-main-thread command, safe while the Editor is busy) until terminal.
  Filter to the changed assemblies/fixtures. Reason: batchmode test commands
  **cannot** run while an Editor holds the project open — the project lock
  is a hard exclusion, not a queue.
- **Full / milestone gate → BATCH on a clone.** Run the CLI's batchmode test
  wrapper (`--mode EditMode`, then `--mode PlayMode`, writing an NUnit XML
  report each) against a **clone** of the project tree, never a directory a
  live Editor holds. A clone costs a second local build cache (first import
  can be minutes; warm reruns are fast).

## Truth is the NUnit XML, never the exit code

The overloaded exit code (see the core CLI contract slice) means "tests
failed", "project not found", "no Editor", and "install failed" can all
share one code. Discriminate:

| Observation | Verdict |
|---|---|
| XML present, failures > 0 | genuine test failures — report them |
| XML present, failures = 0, success exit | PASS |
| XML absent + failure exit | INFRASTRUCTURE failure — read the log, re-run preflight; NOT a test result |
| your own timeout fired | report as timeout, raise it |
| success exit + XML absent | the batchmode lie — treat as FAILURE, grep the log |

Parse the standard NUnit fields (`test-run/@total|@passed|@failed|@skipped`;
per failed case: full name, failure message, first few stack frames). Report
counts plus a capped failure list — never dump raw XML/logs into an
expensive context; hand large output to a log/output-summarizing agent
instead.

## Invariants

- ALWAYS pass an explicit timeout — batchmode test runs have no timeout by
  default, so a hung Editor otherwise blocks the caller forever.
- Pass the editor version explicitly (read it from the project's own version
  file), not a CLI default — a version-mismatch upgrade dialog blocks
  batchmode forever.
- Pin non-interactive/JSON-output env defaults for any scripted invocation.
- Never run two batchmode commands against one project concurrently.
- If your project has (or builds) a harness wrapper around this contract —
  e.g. something like `~/ai_workspace/unity-harness/bin/uw test` — prefer it
  over raw CLI calls; treat the raw contract above as the fallback when no
  harness exists yet.
