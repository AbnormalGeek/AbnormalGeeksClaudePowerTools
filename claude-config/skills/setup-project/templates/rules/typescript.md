---
paths:
  - "**/*.{ts,tsx}"
---

# TypeScript Rules

Loaded only when Claude works with `.ts`/`.tsx` files (path-scoped — saves context elsewhere).

- `strict: true` in tsconfig; no `any` (use generics / `unknown` + guards).
- Prefer `type` for unions, `interface` for object shapes that may be extended.
- No non-null assertions (`!`) — narrow the type instead.
- Required scripts (reference): `lint` (eslint), `typecheck` (`tsc --noEmit`), `test` (vitest), `test:coverage`, `build`.

<!-- Delete this file (or replace with your stack's rules) if the project isn't TypeScript. -->
