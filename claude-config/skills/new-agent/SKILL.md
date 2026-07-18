---
name: new-agent
description: Design and install a new fleet agent via agent-smith. Use when the user asks for a new specialized agent, or when a recurring task shape suggests the roster needs one.
argument-hint: <the gap — what keeps recurring, or what the new agent should do>
---

Spawn **agent-smith** (Agent tool, `subagent_type: agent-smith`) with this gap report as its prompt:

> $ARGUMENTS

While it runs, narrate its progress per the liveliness protocol. When it reports back:
1. Relay its design decisions (tier, model, tools, roster placement) and what agent-forge installed.
2. Remind: the new agent is available **next session**.
3. Offer to commit the `~/.claude` changes via `/sync-config`.
