# MCP Servers

Which MCP servers this setup uses, why, and the exact registration commands.
Official docs: <https://code.claude.com/docs/en/mcp>

Both core servers are registered at **user scope** (`--scope user`) so they're available in
every project, not just one repo. SETUP.md runs these commands during install; this page is the
reference if you need to re-register or audit.

## Core servers

### context7 — live library documentation

Fetches current docs for any library/framework/API. The workflow rule is: **consult it before
writing code against any external API**, so the agent never codes from stale training data.
Registered as a remote HTTP server (no local process, nothing to install):

```bash
claude mcp add --scope user --transport http context7 https://mcp.context7.com/mcp
```

- Homepage: <https://github.com/upstash/context7>

### playwright — real-browser automation

Drives a real browser for E2E verification of web work (click through the flow you just built,
take screenshots, inspect network requests). Registered as a stdio server run via `npx`
(requires Node.js; the package is fetched on first use):

```bash
claude mcp add --scope user playwright -- npx @playwright/mcp@latest
```

- Homepage: <https://github.com/microsoft/playwright-mcp>

Cost note: use the MCP server for *interactive* driving and debugging. Keep committed E2E
coverage as ordinary Playwright test files run via Bash — that's roughly 4× cheaper than
driving the browser tool-call by tool-call.

## Verify

```bash
claude mcp list
```

Both servers should show as Connected. Registrations live in `~/.claude.json` under
`.mcpServers` (inspect with `jq '.mcpServers' ~/.claude.json`).

## Optional / worth considering

None of these are installed by this repo — add them when the need appears.

| Server | When it earns its place | Notes |
|--------|------------------------|-------|
| **postgres** ([crystaldba/postgres-mcp](https://github.com/crystaldba/postgres-mcp)) | You have a production Postgres you want the agent to query safely | Create a **read-only role** first and run with `--access-mode=restricted`. Never point it at prod with a write-capable role. |
| **GitHub official** ([github/github-mcp-server](https://github.com/github/github-mcp-server)) | Usually skip it | The `gh` CLI already covers PRs, issues, releases, and the API from Bash. Revisit only if you need structured Actions-log or security-alert reads. |
| **filesystem / fetch / search / memory / sequential-thinking** | Skip | They duplicate Claude Code's native tools. |

## Giving MCP tools to subagents

Grant a whole server to an agent via its `tools:` allowlist with `mcp__<server>` (e.g.
`mcp__context7`). Keep project-specific servers **project-scoped** (registered in that repo's
`.mcp.json`) so they never load in unrelated sessions.
