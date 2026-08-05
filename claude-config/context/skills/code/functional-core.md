# Functional Core + DI at the Edges

Shape every leaf of business logic as a pure functional core wrapped by a
thin imperative shell. The full canonical reference is
`~/.claude/rules/testable-business-logic.md` — this is the compressed
statement you carry into the leaf, not a replacement for it.

- **Pure core, thin shell.** All branching, validation, and math live in
  plain functions — data in, data out, zero dependencies. Every effect (DB,
  network, clock, randomness, ids) is confined to a shell that has almost no
  branching of its own.
- **Impure → pure → impure.** Gather all inputs via I/O first, call one pure
  function that makes every decision, then perform the writes from its
  return value. Front-loading the reads means the core needs no injected
  collaborators to test.
- **Plain data across the boundary.** Hand the core already-fetched scalars
  and structs, never a repository, ORM entity, or client handle. A core
  function's signature should read as `(plain in) => (plain out)`, so a unit
  test is a literal `expect(fn(input)).toEqual(output)`.
- **Inject what varies between runs.** Clock, RNG, and id generation are the
  most common hidden non-determinism — inject them (default to the real
  implementation) rather than reading them inside logic.
- **Never construct or import a client inside logic.** No `new Client()`,
  no `Date.now()`, no `Math.random()`, no top-level infrastructure import
  inside the core. If you're tempted to mock a database or clock just to
  test a decision, that's the signal the decision leaked into the shell —
  fix the structure, don't add the mock.
