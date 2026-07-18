#!/usr/bin/env bash
# subagent-liveliness-test.sh — exercises subagent-liveliness.sh against
# crafted SubagentStart/SubagentStop/garbage input and asserts:
#   - the state file contents (via jq)
#   - the emitted systemMessage
#   - the exit code (must always be 0)
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK="${SCRIPT_DIR}/../subagent-liveliness.sh"

pass=0
fail=0

note() { printf '  %s\n' "$1"; }
ok()   { pass=$((pass + 1)); printf 'PASS: %s\n' "$1"; }
bad()  { fail=$((fail + 1)); printf 'FAIL: %s\n' "$1"; }

# Isolate state under a throwaway HOME so this never touches the real
# ~/.claude/state/subagents-live.json.
TMP_HOME="$(mktemp -d)"
trap 'rm -rf "$TMP_HOME"' EXIT
STATE_FILE="${TMP_HOME}/.claude/state/subagents-live.json"

run_hook() {
  # run_hook <json-input>  -> sets OUT, ERR, CODE
  local json="$1"
  OUT="$(HOME="$TMP_HOME" "$HOOK" <<<"$json" 2>/tmp/subagent-liveliness-test.stderr)"
  CODE=$?
  ERR="$(cat /tmp/subagent-liveliness-test.stderr)"
  rm -f /tmp/subagent-liveliness-test.stderr
}

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    ok "$desc"
  else
    bad "$desc (expected [$expected] got [$actual])"
  fi
}

# ---------------------------------------------------------------------------
# Test 1: SubagentStart for agent-1 (coder)
# ---------------------------------------------------------------------------
run_hook '{"hook_event_name":"SubagentStart","session_id":"sess-1","agent_id":"agent-1","agent_type":"coder"}'
assert_eq "start agent-1: exit code 0" "0" "$CODE"
assert_eq "start agent-1: systemMessage" '{"systemMessage":"▶ coder started"}' "$OUT"
count="$(jq 'length' "$STATE_FILE" 2>/dev/null)"
assert_eq "start agent-1: state file has 1 entry" "1" "$count"
entry="$(jq -c '.[0] | {agent_id, agent_type, session_id}' "$STATE_FILE" 2>/dev/null)"
assert_eq "start agent-1: entry fields" '{"agent_id":"agent-1","agent_type":"coder","session_id":"sess-1"}' "$entry"
has_started_at="$(jq '.[0] | has("started_at")' "$STATE_FILE" 2>/dev/null)"
assert_eq "start agent-1: has started_at" "true" "$has_started_at"

# ---------------------------------------------------------------------------
# Test 2: SubagentStart for agent-2 (researcher) — second concurrent entry
# ---------------------------------------------------------------------------
run_hook '{"hook_event_name":"SubagentStart","session_id":"sess-1","agent_id":"agent-2","agent_type":"researcher"}'
assert_eq "start agent-2: exit code 0" "0" "$CODE"
assert_eq "start agent-2: systemMessage" '{"systemMessage":"▶ researcher started"}' "$OUT"
count="$(jq 'length' "$STATE_FILE" 2>/dev/null)"
assert_eq "start agent-2: state file has 2 entries" "2" "$count"

# ---------------------------------------------------------------------------
# Test 2b: SubagentStart for agent-1 again — must upsert, not duplicate
# ---------------------------------------------------------------------------
run_hook '{"hook_event_name":"SubagentStart","session_id":"sess-1","agent_id":"agent-1","agent_type":"coder"}'
assert_eq "restart agent-1: exit code 0" "0" "$CODE"
count="$(jq 'length' "$STATE_FILE" 2>/dev/null)"
assert_eq "restart agent-1: still 2 entries (upsert not append)" "2" "$count"

# ---------------------------------------------------------------------------
# Test 3: SubagentStop for agent-1 — removed, agent-2 remains
# ---------------------------------------------------------------------------
run_hook '{"hook_event_name":"SubagentStop","session_id":"sess-1","agent_id":"agent-1","agent_type":"coder","last_assistant_message":"done"}'
assert_eq "stop agent-1: exit code 0" "0" "$CODE"
assert_eq "stop agent-1: systemMessage" '{"systemMessage":"✔ coder done"}' "$OUT"
count="$(jq 'length' "$STATE_FILE" 2>/dev/null)"
assert_eq "stop agent-1: state file has 1 entry left" "1" "$count"
remaining_id="$(jq -r '.[0].agent_id' "$STATE_FILE" 2>/dev/null)"
assert_eq "stop agent-1: agent-2 is the survivor" "agent-2" "$remaining_id"

# ---------------------------------------------------------------------------
# Test 4: garbage (not JSON at all) — silent no-op, state untouched
# ---------------------------------------------------------------------------
before="$(cat "$STATE_FILE")"
run_hook 'not json at all, just garbage input {{{'
assert_eq "garbage input: exit code 0" "0" "$CODE"
assert_eq "garbage input: no stdout" "" "$OUT"
after="$(cat "$STATE_FILE")"
assert_eq "garbage input: state file unchanged" "$before" "$after"

# ---------------------------------------------------------------------------
# Test 5: valid JSON, missing required fields — silent no-op
# ---------------------------------------------------------------------------
before="$(cat "$STATE_FILE")"
run_hook '{"hook_event_name":"SubagentStart","session_id":"sess-1"}'
assert_eq "missing agent_id: exit code 0" "0" "$CODE"
assert_eq "missing agent_id: no stdout" "" "$OUT"
after="$(cat "$STATE_FILE")"
assert_eq "missing agent_id: state file unchanged" "$before" "$after"

# ---------------------------------------------------------------------------
# Test 6: unknown/unhandled event name — silent no-op
# ---------------------------------------------------------------------------
before="$(cat "$STATE_FILE")"
run_hook '{"hook_event_name":"PreToolUse","session_id":"sess-1","agent_id":"agent-9","agent_type":"coder"}'
assert_eq "unknown event: exit code 0" "0" "$CODE"
assert_eq "unknown event: no stdout" "" "$OUT"
after="$(cat "$STATE_FILE")"
assert_eq "unknown event: state file unchanged" "$before" "$after"

# ---------------------------------------------------------------------------
# Test 7: empty stdin — silent no-op
# ---------------------------------------------------------------------------
before="$(cat "$STATE_FILE")"
run_hook ''
assert_eq "empty stdin: exit code 0" "0" "$CODE"
assert_eq "empty stdin: no stdout" "" "$OUT"
after="$(cat "$STATE_FILE")"
assert_eq "empty stdin: state file unchanged" "$before" "$after"

# ---------------------------------------------------------------------------
# Test 8: stale entry (older than 4h) gets pruned on the next event
# ---------------------------------------------------------------------------
stale_epoch=$(( $(date +%s) - (5 * 60 * 60) )) # 5h ago
jq --argjson t "$stale_epoch" \
  '. + [{agent_id:"agent-stale", agent_type:"ghost", session_id:"sess-1", started_at: $t}]' \
  "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
count_before_prune="$(jq 'length' "$STATE_FILE" 2>/dev/null)"
assert_eq "stale seed: 2 entries before prune" "2" "$count_before_prune"

run_hook '{"hook_event_name":"SubagentStart","session_id":"sess-1","agent_id":"agent-3","agent_type":"validator"}'
assert_eq "prune: exit code 0" "0" "$CODE"
ids="$(jq -c '[.[].agent_id] | sort' "$STATE_FILE" 2>/dev/null)"
assert_eq "prune: stale agent-stale removed, survivors + new entry present" '["agent-2","agent-3"]' "$ids"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo
echo "----------------------------------------"
echo "pass=$pass fail=$fail"
if [[ "$fail" -eq 0 ]]; then
  echo "ALL TESTS PASSED"
  exit 0
else
  echo "TESTS FAILED"
  exit 1
fi
