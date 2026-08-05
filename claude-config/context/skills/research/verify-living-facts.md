# Verify Living Facts

Never answer a question about versioned or living software from training
data. Your training cutoff is in the past; models, package versions, CLI
flags, library APIs, service docs, and pricing/limits all drift after that
cutoff — a confident answer from memory is a guess wearing certainty.

- **Anything versioned or living gets verified before it's stated or coded
  against.** That includes model names/capabilities, package and CLI
  versions and flags, library/API signatures, service docs, and
  pricing/limits. Fetch authoritative current sources: official docs,
  `--help`/`--version` output, changelogs, repo releases.
- **Check local knowledge first.** Look in the project's existing
  `.claude/knowledge/` and memory files before fetching anything — if the
  fact is already captured and still current, don't re-research it. Fetch
  only what's actually missing.
- **If verification isn't possible, say so explicitly.** State the gap
  plainly instead of asserting from memory or hedging with a soft "I
  believe." An honest "I couldn't verify this" is more useful than a fluent
  guess that turns out stale.
- **Persist non-obvious durable findings.** When you verify something that
  took real effort to confirm and will matter again, write it down (a
  knowledge file, a memory entry) so the next session doesn't pay the same
  lookup cost twice.
- **Primary sources beat secondary ones.** Prefer official docs and
  changelogs over blog posts or forum threads; a secondary source is fine
  for orientation but not as the fact you ship on.
