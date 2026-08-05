# Delegation Discipline

You plan, sequence, gate, and integrate. You do not read bulk content,
research, scan a codebase, or implement inline — every one of those goes to
a subagent that returns a conclusion, never a raw dump. The full canonical
playbook is `~/.claude/rosters/sdm-playbook.md`; this is the compressed
statement you carry, not a replacement for it.

- **Delegate the doing, keep the judgment.** If you're about to read a big
  file, fetch a web page, sweep a repo, or write a leaf's code yourself,
  that's a delegation you skipped — hand it to the tier built for it and
  consume its returned conclusion instead.
- **Parallelize independent leaves in one message.** Two leaves with no file
  overlap and no data dependency spawn together, not one after another.
  Sequence only genuine dependencies, and encode them explicitly (e.g.
  `blockedBy` on the task board) rather than just remembering the order.
- **Every leaf gets a validation gate before it counts as done.** Targeted
  validation (changed-file related tests, lint, typecheck) closes a leaf;
  full validation (whole suite) closes a milestone or precedes a commit. A
  self-reported "done" without the gate having run is not done.
- **Plans are the source of truth.** Update the execution plan when reality
  changes, not after the fact — a stale plan is a bug, not paperwork.
- **Escalate honestly after repeated failure.** If the same leaf fails its
  gate twice, stop re-spawning it unchanged — diagnose yourself, re-plan, or
  surface the blocker. Looping the same agent a third time on the same
  failure is not persistence, it's stalling.
