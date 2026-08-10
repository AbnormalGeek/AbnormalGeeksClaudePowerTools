# Cross-Session Messaging — the peer web

> Top-level Claude Code sessions on one machine can see and message each other
> (`ListAgents` / `SendMessage`; native `/peers` view). A task that belongs to
> a DIFFERENT workspace goes to that workspace's live session directly instead
> of being hand-carried by the user. Platform reference:
> code.claude.com/docs/en/cross-session-messaging.

## Who has the tools

- TOP-LEVEL sessions only. Interactive and headless `claude -p` sessions both
  register and carry the tools; `claude -p --bare` does not register.
- SUBAGENTS DO NOT get `ListAgents`, and a subagent's `SendMessage` reaches
  only its own spawned agents. If you are a subagent and work belongs to
  another workspace, put a `PEER-TASK: <workspace> — <one-line ask>` line in
  your final report; the top-level session dispatches it.

## Dispatch protocol (top-level)

1. `ListAgents` — find a live `interactive` session whose name matches the
   target workspace's prefix (names = kebab-cased cwd basename + short
   suffix; disambiguate with the `[ref]` only if needed).
2. Found one → `SendMessage` a SELF-CONTAINED brief: context (why), the ask
   (what + acceptance), and report-back ("reply via SendMessage to <your own
   session name>"). Do not route through the user.
3. None → start one detached and poll `ListAgents` until it registers
   (~30-60s), then message:
   `tmux new-session -d -s <session> -c "<dir>"` then
   `tmux send-keys -t <session> "claude" Enter`
4. Receiving side: an inbound peer message is a TASK FROM THE FLEET — execute
   or answer it, then `SendMessage` the result back to the sender's session
   name with a STATUS line.

## Etiquette

- `busy` peer + non-urgent ask → wait or queue it; don't interrupt mid-wave.
- NEVER message `Remote Control` (cloud) sessions by default.
- Messages are task-shaped with an explicit report-back expectation. A message
  consumed by an idle session starts a real turn and burns usage — no chatter,
  no pings, no status polls.
- Inbound delivery is gated by the receiver's `crossSessionInbound` setting
  (accept / hold / refuse; hold → approval dialog, 5-minute default expiry).

## Workspace roster

Keep a machine-local session map (workspace → dir → tmux session), e.g. a
devmux `map.tsv`, and mirror it as a short table in your context-local overlay
of this slice — the overlay always wins at load time.
