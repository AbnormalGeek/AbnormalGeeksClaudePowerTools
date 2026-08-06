# Bulk-Input Routing

Never read oversized or unknown-size input inline — route it to a utility
agent instead. If a command's output, a file, or a page is likely more than
100 lines, or its size is unknown, delegate the read rather than `cat`ing,
`tail`ing, or fetching it "to check quickly." Reading bulk input inline burns
the context budget your leaf needs for the actual work; it is a defect, not a
shortcut.

- **Verbose test/build/log output** → a log-analysis utility agent. Hand it
  the command to run (or the log to read); ask for errors, root causes, and
  timings, not the raw stream.
- **Web pages** → a web-fetching utility agent. Give it the URL(s) or the
  question and let it return only the extracted facts with sources.
- **Library/API docs** → a docs-fetching utility agent, before you write any
  code against a signature or parameter you're not 100% current on.
- **Call-site or pattern hunts across more than a handful of files** → a
  repo-scouting utility agent instead of grepping or reading the whole tree
  yourself.
- **Any other oversized content** — a huge file, a giant diff, a long
  transcript — → a distilling utility agent.

Prompt every utility agent with a precise extraction contract: the exact
question(s) you need answered, plus a cap on sources or output (a page limit,
a word limit, a file count). They return only the asked-for facts, never a
raw dump — so the source gets digested before it reaches your context, not
after.
