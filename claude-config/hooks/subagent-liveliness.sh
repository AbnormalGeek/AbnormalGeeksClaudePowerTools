#!/usr/bin/env bash
# subagent-liveliness.sh — SubagentStart/SubagentStop hook.
#
# Maintains a live roster of running subagents at
# ~/.claude/state/subagents-live.json and emits a systemMessage ping on each
# start/stop transition, so the terminal shows something even while the
# fleet's work happens off-screen in subagent context windows.
#
# Contract: this hook must NEVER block a spawn. It always exits 0. Anything
# unexpected (bad/missing JSON, unknown event, IO failure) is a silent no-op.
set -euo pipefail

STATE_DIR="${HOME}/.claude/state"
STATE_FILE="${STATE_DIR}/subagents-live.json"
LOCK_FILE="${STATE_FILE}.lock"
STALE_SECONDS=$((4 * 60 * 60)) # 4h

# Belt-and-suspenders: whatever happens above, always leave with 0 so a
# hook failure/bug can never block a subagent spawn.
trap 'exit 0' EXIT

input="$(cat 2>/dev/null || true)"

# Degrade silently: empty stdin or not valid JSON at all.
if [[ -z "$input" ]] || ! jq -e . >/dev/null 2>&1 <<<"$input"; then
  exit 0
fi

event="$(jq -r 'if has("hook_event_name") and (.hook_event_name != null) then .hook_event_name else empty end' <<<"$input" 2>/dev/null || true)"
agent_id="$(jq -r 'if has("agent_id") and (.agent_id != null) then .agent_id else empty end' <<<"$input" 2>/dev/null || true)"
agent_type="$(jq -r 'if has("agent_type") and (.agent_type != null) then .agent_type else empty end' <<<"$input" 2>/dev/null || true)"
session_id="$(jq -r 'if has("session_id") and (.session_id != null) then .session_id else empty end' <<<"$input" 2>/dev/null || true)"

# Degrade silently: missing fields we need to act on this event.
if [[ -z "${event:-}" || -z "${agent_id:-}" || -z "${agent_type:-}" ]]; then
  exit 0
fi

case "$event" in
  SubagentStart|SubagentStop) ;;
  *) exit 0 ;;
esac

mkdir -p "$STATE_DIR" 2>/dev/null || exit 0

now="$(date +%s)"

# Serialize the read-modify-write across parallel wave spawns (many
# SubagentStart/Stop events can fire concurrently).
exec 200>"$LOCK_FILE" || exit 0
flock -w 5 200 || exit 0

current="[]"
if [[ -s "$STATE_FILE" ]]; then
  existing="$(cat "$STATE_FILE" 2>/dev/null || true)"
  if [[ -n "$existing" ]] && jq -e . >/dev/null 2>&1 <<<"$existing"; then
    current="$existing"
  fi
fi

if [[ "$event" == "SubagentStart" ]]; then
  # Upsert by agent_id, then prune stale entries.
  filter='
    (map(select(.agent_id != $agent_id))
      + [{agent_id: $agent_id, agent_type: $agent_type, session_id: $session_id, started_at: $now}])
    | map(select(($now - (.started_at // 0)) < $stale))
  '
else
  # Remove by agent_id, then prune stale entries.
  filter='
    map(select(.agent_id != $agent_id))
    | map(select(($now - (.started_at // 0)) < $stale))
  '
fi

updated="$(jq --arg agent_id "$agent_id" \
              --arg agent_type "$agent_type" \
              --arg session_id "${session_id:-}" \
              --argjson now "$now" \
              --argjson stale "$STALE_SECONDS" \
              "$filter" <<<"$current" 2>/dev/null)" || exit 0

tmp_file="$(mktemp "${STATE_FILE}.XXXXXX" 2>/dev/null)" || exit 0
if ! printf '%s\n' "$updated" > "$tmp_file" 2>/dev/null || ! mv -f "$tmp_file" "$STATE_FILE" 2>/dev/null; then
  rm -f "$tmp_file" 2>/dev/null || true
  exit 0
fi

if [[ "$event" == "SubagentStart" ]]; then
  jq -nc --arg t "$agent_type" '{systemMessage: ("▶ " + $t + " started")}'
else
  jq -nc --arg t "$agent_type" '{systemMessage: ("✔ " + $t + " done")}'
fi

exit 0
