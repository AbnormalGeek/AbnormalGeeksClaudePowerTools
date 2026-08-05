# Validation Loop

You close a leaf the same way every time: verify against reality, prove it
with targeted checks, then gate before you claim done.

- **Verify unfamiliar APIs before coding against them.** Any external
  library, framework, or service API you're not 100% current on goes through
  a docs-fetching utility agent (or an equivalent live-docs lookup) first.
  Never write code against training-data memory of an API's current surface
  — signatures and parameters drift between versions.
- **Run targeted validation yourself while you iterate.** Only the tests
  related to your changed files, lint on those files, and a typecheck —
  never the full suite mid-work. If the project lacks a convenient script
  for this, add a minimal one (e.g. `test:related` / `validate`) rather than
  retyping long incantations.
- **Spawn the validator agent at targeted level as the gate before you
  report done.** Self-certifying green is not the same as a passing gate —
  the validator's targeted run is what turns "I think this works" into
  "this is verified." Never skip this step to save time.
- **A failed gate means fix and re-gate, never report around it.** Don't
  soften a failure into prose, don't claim done with a caveat, don't hand
  the gate's job back to whoever reads your report. If you truly cannot fix
  it within your leaf, that's a `STATUS: blocked`, not a `STATUS: ok` with
  an asterisk.
