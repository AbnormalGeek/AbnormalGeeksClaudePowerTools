# Testable Business Logic — Pure Functional Core + DI at the Edges

> Durable global engineering standard. The enforceable summary lives in
> `~/.claude/CLAUDE.md` (Engineering Standards → "Testable business logic"); this
> file is the full reference. Applies to every project.

**The rule, in one sentence:** all business logic must be built so its _real_
computation is unit-testable **without mocking infrastructure** — achieved by a
pure functional core that takes plain data in and returns plain data out, with
every effect (DB, network, clock, randomness, ids) confined to a thin imperative
shell at the edge.

If you find yourself wanting to mock a database, HTTP client, or `Date.now()`
_just to test a decision_, that is the smell: a decision has leaked into the
shell, or I/O has leaked into the core. Fix the structure, don't add the mock.

## 1. Functional core, imperative shell

Split every operation into two parts ([Bernhardt, _Boundaries_](https://www.destroyallsoftware.com/talks/boundaries);
[Martin, _Clean Architecture_](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)):

- **Core** (`src/features/**`): pure functions — all branching, validation,
  math, state transitions. Many code paths, **zero dependencies**. Imports no
  `supabase`, no `fetch`, no `Date`, no `react`/`react-native`, no `node:*`.
- **Shell** (hooks, repositories, Edge Function handlers, components): all
  effects. Many dependencies, **almost no branching**.

The dependency rule is one-directional: the shell calls the core; **the core
never calls the shell and is unaware it exists**. Enforce it with lint, not
vigilance:

```jsonc
// eslint no-restricted-imports for src/features/**
{
  "patterns": [
    {
      "group": ["@/lib/supabase", "node:*", "react", "react-native"],
      "message": "src/features must stay pure — no I/O imports in the core",
    },
  ],
}
```

### The impureim sandwich (impure → pure → impure)

Shape each use-case as: gather **all** inputs via I/O, call **one** pure function
that makes every decision, then perform the writes from its return value
([Seemann, _Impureim Sandwich_](https://blog.ploeh.dk/2020/03/02/impureim-sandwich/)).
Front-loading the reads means the core needs **no injected collaborators at
all** — "dependency rejection" beats dependency injection for testability,
because there is nothing to fake.

```typescript
// Example domain: a group expense-splitting app
async function settleUp(groupId: string, repo: Repo): Promise<void> {
  const balances = await repo.loadBalances(groupId); // IMPURE: gather
  const transfers = simplifyDebts(balances); // PURE: every decision
  await repo.recordTransfers(groupId, transfers); // IMPURE: act
}
// simplifyDebts is tested with literal balance maps — the DB never enters the test.
```

### Pass plain data by value across the boundary

Never hand the core a repository, ORM entity, Supabase handle, or `req`/`res` —
hand it the already-fetched scalars/structs it uses, and let it return the
values to be written. Map DB rows into plain domain types at the edge. When a
signature is `(plain in) => (plain out)`, a unit test is literally
`expect(fn(input)).toEqual(output)`.

```typescript
// Bad — needs a DB to test a comparison:
async function isOverdue(db: Db, invoiceId: string): Promise<boolean> {
  /*...*/
}
// Good — edge fetches, core decides:
function isOverdue(dueDate: Date, now: Date): boolean {
  return now > dueDate;
}
```

### Model effects as returned data when orchestration is the hard part

When "what to do next" is itself the complex branching (which notifications to
send, which rows to write), have the core **return a list of commands** and let
a humble interpreter in the shell execute them. You then assert on the command
list with plain equality — zero mocks per effect.

```typescript
type Command =
  | { type: "notify"; userId: string; text: string }
  | { type: "recordPayment"; from: string; to: string; cents: number };
function onSettlement(state: GroupState): Command[] {
  /* branching → commands */
}
expect(onSettlement(state)).toContainEqual({
  type: "recordPayment",
  from: "a",
  to: "b",
  cents: 500,
});
```

## 2. Dependency injection — only in the shell, only when unavoidable

Order of preference: **(1) make it pure** (no collaborator) → **(2) inject the
effect** → never **(3) construct/import it inside logic**.

- **Constructor injection** is the default for stateful services/repositories
  ([Fowler, _DI_](https://martinfowler.com/articles/injection.html)). Store
  collaborators on `readonly` fields; never `new SupabaseClient()` inside a
  feature. An 8-arg constructor is the class telling you it does too much.
- **Function / parameter injection** for free functions — a trailing `deps`
  object once you have 2+ collaborators, or partial application (factory closing
  over deps).
- **Default-parameter client idiom** for a single thin seam: production stays
  terse, tests override.

```typescript
import { supabase } from "@/lib/supabase";
export async function loadGroup(id: string, client: SupabaseLike = supabase) {
  const { data } = await client.from("groups").select().eq("id", id).single();
  return data;
} // prod: loadGroup('g1') · test: loadGroup('g1', fakeClient)
```

- **Composition root**: centralize _all_ concrete wiring (real client, real
  clock) in one factory per entry point — Pure DI, no container needed. Business
  modules receive built collaborators and import no infrastructure.

### Inject time, randomness, and id generation — always

These are the most common hidden non-determinism. Reading them inside logic
makes the result change every run.

```typescript
type Clock = () => Date;
type Rng = () => number;
type IdGen = () => string;
export const systemClock: Clock = () => new Date();
function isOverdue(due: Date, clock: Clock): boolean {
  return clock() > due;
}
// isOverdue(due, () => new Date('2026-06-17')) is exact & repeatable.
```

**Anti-pattern (review trigger):** a top-level `import { supabase }`,
`new Database()`, `Date.now()`, `Math.random()`, or `crypto.randomUUID()`
_inside_ business code. The signature then lies about what the unit needs and the
only way to test is monkey-patching. Grep for these in `src/features/`.

### Prefer fakes over interaction mocks

When a seam must be injected, substitute a real-behavior **fake** (in-memory
repo, frozen clock) and assert the resulting _state/output_ — not "insert was
called once" ([Shore, _Testing Without Mocks_](https://www.jamesshore.com/v2/projects/nullables/testing-without-mocks)).
Mocks that assert call sequences couple tests to implementation and pass even
when the logic is wrong.

## 3. Money & rounding correctness

- **Integer minor units, never floats.** `0.1 + 0.2 === 0.30000000000000004`;
  errors compound. Store money as integer cents, use a branded type, format to a
  decimal string only at the UI edge ([Fowler, _Money_](https://martinfowler.com/eaaCatalog/money.html)).
  (When a codebase already stores decimal dollars, centralize rounding in ONE
  pure function and consolidate every call site through it.)

- **Pick a rounding mode deliberately; make it one pure function.** `Math.round`
  rounds halves toward +∞, so `Math.round(2.5)===3` but `Math.round(-2.5)===-2` —
  a charge and its reversal won't cancel. Use **half-away-from-zero** when a
  value and its negation must mirror (debts/refunds), or **banker's/half-even**
  to kill cumulative upward bias over many rows.

- **Split with the largest-remainder method** so parts sum _exactly_ to the
  whole. Floor each share, then hand out the leftover cents one at a time to the
  largest fractional remainders ([Betterment](https://www.betterment.com/engineering/penny-precise-allocation-functions);
  [dinero.js `allocate`](https://www.dinerojs.com/docs/api/mutations/allocate)).
  Pure function of `(total, weights)` → exhaustively property-testable.

```typescript
function allocate(total: number, weights: number[]): number[] {
  const sum = weights.reduce((a, b) => a + b, 0);
  if (sum <= 0) throw new Error("weights must sum > 0");
  const exact = weights.map((w) => (total * w) / sum);
  const floors = exact.map(Math.floor);
  const leftover = total - floors.reduce((a, b) => a + b, 0);
  const order = exact
    .map((v, i) => ({ i, frac: v - Math.floor(v) }))
    .sort((a, b) => b.frac - a.frac || a.i - b.i); // stable → deterministic
  const out = [...floors];
  for (let k = 0; k < leftover; k++) out[order[k].i]++;
  return out;
}
allocate(100, [1, 1, 1]); // [34, 33, 33] — sums to 100 exactly
```

## 4. Testing strategy

The pure core unlocks a four-layer strategy — none of it needs infra mocks.

**a) Pure-core unit tests, no mocks.** Feed literals, assert with exact equality
(`toBe`/`toEqual`, never `toBeCloseTo` for money).

**b) Property-based invariants with fast-check** — assert the _laws_, not
examples ([Wlaschin](https://fsharpforfunandprofit.com/posts/property-based-testing-2/);
[fast-check](https://fast-check.dev/)). For a money/ledger core, the laws are:

- **Conservation** — sum of balances before == after; a closed group nets to 0.
  _Money is neither created nor destroyed._
- **Sum-to-total & no-negative** — split shares reconstitute the whole, none negative.
- **Order-independence** — `compute(shuffle(xs))` equals `compute(xs)`.
- **Idempotence** — `simplify(simplify(x)) === simplify(x)`.
- **Round-trip** — `parse(format(c)) === c`; `domain ↔ DB row`.
- **Test oracle / metamorphic** — when you can't state the answer: assert the
  optimized engine agrees with a brute-force reference on net positions, or that
  scaling all inputs by _k_ scales all balances by _k_.

```typescript
fc.assert(
  fc.property(
    fc.nat({ max: 1_000_000 }),
    fc.array(fc.integer({ min: 1, max: 1000 }), {
      minLength: 1,
      maxLength: 12,
    }),
    (total, weights) => {
      const parts = allocate(total, weights);
      expect(parts.reduce((a, b) => a + b, 0)).toBe(total); // conservation
      expect(parts.every((p) => p >= 0)).toBe(true); // no-negative
      expect(allocate(total, weights)).toEqual(parts); // deterministic
    },
  ),
);
```

Design arbitraries bottom-up with `fc.record`/`fc.array`/`fc.constantFrom`,
prefer `.map()` over `.filter()`/`fc.pre` (filtering wrecks generation and
shrinking). On failure, replay the printed `{ seed, path }`; **pin every
production money bug as an `examples: [...]` regression case**. For stateful
ledgers (add/edit/delete/settle), use model-based testing (`fc.commands` +
`fc.modelRun`) asserting conservation after every step.

**c) Table-driven realistic scenarios** alongside the properties — `test.each`
with hand-curated cases and exact expected outputs, as executable spec and
human-readable regression net. Add a row for every scenario a product owner
would describe in words and every bug you fix. For ledger/who-owes-what logic,
the strongest assertion is: _the simplified transfers reconstruct the exact net
balances_ (the right people owe the right people).

**d) Mutation testing as the real coverage check.** 100% line/branch coverage is
necessary-but-not-sufficient — you can hit it with assertions deleted ("coverage
theater"). Use coverage to find _untested_ code; gate quality on **StrykerJS**
mutation score, which perturbs the code (`*0.8 → *0.5`, `> → >=`, drop a
statement) and asks whether a test goes red. Every surviving mutant is a missing
assertion or dead code. Genuinely-unreachable defensive guards (a type-only
`?? 0`, an infinite-loop safety net) are the _only_ acceptable use of
`/* v8 ignore next */`, and each needs a one-line justification.

**Test placement.** Tests are written in the **same task** as the code they
cover — never deferred, never optional. Unit + property tests for the core; a
few integration tests for the thin shell; E2E in the release gate only.
