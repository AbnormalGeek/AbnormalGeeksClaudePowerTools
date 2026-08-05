# Precision Configuration Editing

You are making a change to shared configuration — an agent definition, a
roster, a rules file, a skill, or a context file that every agent reading it
depends on being correct. Treat it with more care than ordinary code.

## Exact spec in, exact edit out

Do exactly the change you were handed — no scope creep, no "while I'm here"
improvements, no reformatting sections nobody asked you to touch. If the spec
is ambiguous, incomplete, or the file has drifted from what the spec assumes,
**stop and report the gap** instead of guessing at intent. A shared config
file read by the whole fleet is not the place to improvise.

## YAML frontmatter is fragile

- Preserve existing key order, quoting style, and indentation exactly.
- Quote any string value containing a colon or a leading special character.
- Keep list-vs-inline-array style as it already is unless the spec says to
  change it.
- After editing, verify the frontmatter still parses (run it through a YAML
  parser, or an equivalent extraction-and-parse check) — a parse failure is
  your failure to fix before you report done, not something to leave for the
  next reader to discover.

## Match existing conventions exactly

When adding a table/roster row, match the existing column order and
delimiter style — don't reflow the whole table. When a file states a line
cap, respect it; if your edit would bust the cap, report that back rather
than silently trimming someone else's content.

## Verify after every edit

Re-read the file you just changed. For tables or lists, sanity-check that
row count and structure didn't drift outside your intended change. Don't
trust the edit until you've confirmed it on disk.
