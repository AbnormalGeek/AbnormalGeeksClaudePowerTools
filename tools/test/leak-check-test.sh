#!/usr/bin/env bash
# leak-check-test.sh — exercises tools/leak-check.sh against a throwaway git
# repo (never the real one) and asserts:
#   - clean trees exit 0 with "clean"
#   - each pattern class (case-sensitive, case-insensitive, secret-shaped)
#     is actually detected, including the documented \bjarvis\b word-boundary
#     and the deliberately boundary-free `unifi` substring behavior
#   - each of the 4 allowlist rules suppresses exactly the case it names,
#     and does NOT suppress a lookalike outside its scope
#   - --history finds a leak that was fixed in the working tree but still
#     lives in an earlier commit
#   - argument handling (unknown flag, --help)
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LEAK_CHECK_SRC="${SCRIPT_DIR}/../leak-check.sh"

pass=0
fail=0

ok()  { pass=$((pass + 1)); printf 'PASS: %s\n' "$1"; }
bad() { fail=$((fail + 1)); printf 'FAIL: %s\n' "$1"; }

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    ok "$desc"
  else
    bad "$desc (expected [$expected] got [$actual])"
  fi
}

assert_contains() {
  local desc="$1" haystack="$2" needle="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    ok "$desc"
  else
    bad "$desc (expected to find [$needle])"
  fi
}

assert_not_contains() {
  local desc="$1" haystack="$2" needle="$3"
  if [[ "$haystack" != *"$needle"* ]]; then
    ok "$desc"
  else
    bad "$desc (did not expect to find [$needle])"
  fi
}

# Isolate every scenario under a throwaway repo — this must never touch the
# real AbnormalGeeksClaudePowerTools working tree or its git history.
TMP_REPO="$(mktemp -d)"
trap 'rm -rf "$TMP_REPO"' EXIT

init_repo() {
  rm -rf "$TMP_REPO"
  mkdir -p "$TMP_REPO/tools"
  (
    cd "$TMP_REPO"
    git init -q
    git config user.email "test@example.com"
    git config user.name "leak-check-test"
  )
  cp "$LEAK_CHECK_SRC" "$TMP_REPO/tools/leak-check.sh"
  chmod +x "$TMP_REPO/tools/leak-check.sh"
}

commit_all() {
  (cd "$TMP_REPO" && git add -A && git commit -q -m "$1")
}

run_check() {
  # run_check [--history]  -> sets OUT, CODE
  OUT="$(cd "$TMP_REPO" && ./tools/leak-check.sh "$@" 2>&1)"
  CODE=$?
}

# ---------------------------------------------------------------------------
# Test 1: a clean tree exits 0 with "clean"
# ---------------------------------------------------------------------------
init_repo
echo "nothing interesting here" > "$TMP_REPO/README.md"
commit_all "init"
run_check
assert_eq "clean tree: exit 0" "0" "$CODE"
assert_eq "clean tree: prints clean" "clean" "$OUT"

# ---------------------------------------------------------------------------
# Test 2: a case-sensitive pattern (192.168.x.x) is detected with file+line
# ---------------------------------------------------------------------------
init_repo
printf 'line one\nreaches 192.168.1.1 from here\n' > "$TMP_REPO/notes.md"
commit_all "init"
run_check
assert_eq "IP leak: exit 1" "1" "$CODE"
assert_contains "IP leak: names file:line" "$OUT" "notes.md:2:"
assert_contains "IP leak: shows matched line" "$OUT" "192.168.1.1"

# ---------------------------------------------------------------------------
# Test 3: case-insensitive pattern matches regardless of case
# ---------------------------------------------------------------------------
init_repo
echo "ask JARVIS about it" > "$TMP_REPO/notes.md"
commit_all "init"
run_check
assert_eq "case-insensitive jarvis: exit 1" "1" "$CODE"
assert_contains "case-insensitive jarvis: reported" "$OUT" "JARVIS"

# ---------------------------------------------------------------------------
# Test 4: \bjarvis\b has real word boundaries — "jarvisish" (one token, no
# boundary after "jarvis") must NOT match; "jarvis" as its own token must.
# ---------------------------------------------------------------------------
init_repo
echo "jarvisish is not a real word and should not trip the guard" > "$TMP_REPO/notes.md"
commit_all "init"
run_check
assert_eq "jarvis word-boundary: no match on jarvisish" "0" "$CODE"
assert_eq "jarvis word-boundary: prints clean" "clean" "$OUT"

# ---------------------------------------------------------------------------
# Test 5: `\bunifi\b` is word-boundaried — "unified-diff-style" (no boundary
# before the "ed") must NOT trip it, while "unifi-network" (boundary at the
# hyphen) must. Pinned so a future pattern edit can't silently regress
# either direction without this suite noticing.
# ---------------------------------------------------------------------------
init_repo
echo "a unified-diff-style summary" > "$TMP_REPO/notes.md"
commit_all "init"
run_check
assert_eq "unifi word-boundary: no match on unified-diff-style" "0" "$CODE"
assert_eq "unifi word-boundary: prints clean" "clean" "$OUT"

init_repo
echo "wired up via the unifi-network-read server for reads" > "$TMP_REPO/notes.md"
commit_all "init"
run_check
assert_eq "unifi word-boundary: matches unifi-network: exit 1" "1" "$CODE"
assert_contains "unifi word-boundary: matches unifi-network: reported" "$OUT" "unifi-network-read"

# ---------------------------------------------------------------------------
# Test 6: allowlist rule 1 — README.md + AbnormalGeek mention is suppressed;
# the same triggering pattern (GoodVibe) in a different file still fires.
# ---------------------------------------------------------------------------
init_repo
echo "GoodVibe project by AbnormalGeek" > "$TMP_REPO/README.md"
echo "GoodVibe mentioned here too" > "$TMP_REPO/other.md"
commit_all "init"
run_check
assert_eq "allowlist README/AbnormalGeek: exit 1 (other.md still fires)" "1" "$CODE"
assert_not_contains "allowlist README/AbnormalGeek: README.md hit suppressed" "$OUT" "README.md:"
assert_contains "allowlist README/AbnormalGeek: other.md hit still reported" "$OUT" "other.md:"

# ---------------------------------------------------------------------------
# Test 7: allowlist rule 2 — literal `sk-...` in docs/local-llm-offload.md
# is suppressed; the identical line in another file is not.
# ---------------------------------------------------------------------------
init_repo
mkdir -p "$TMP_REPO/docs"
echo "GoodVibe example key: sk-..." > "$TMP_REPO/docs/local-llm-offload.md"
echo "GoodVibe example key: sk-..." > "$TMP_REPO/docs/other.md"
commit_all "init"
run_check
assert_eq "allowlist sk-...: exit 1 (other.md still fires)" "1" "$CODE"
assert_not_contains "allowlist sk-...: local-llm-offload.md hit suppressed" "$OUT" "local-llm-offload.md:"
assert_contains "allowlist sk-...: other.md hit still reported" "$OUT" "docs/other.md:"

# ---------------------------------------------------------------------------
# Test 8: allowlist rule 3 — `~/.env.<domain>` placeholder form is
# suppressed; a concrete (non-placeholder) `~/.env.gvgllc` path is not.
# ---------------------------------------------------------------------------
init_repo
echo "gvgllc creds live in ~/.env.<domain>, source before use" > "$TMP_REPO/placeholder.md"
echo "gvgllc creds live in ~/.env.gvgllc, source before use" > "$TMP_REPO/concrete.md"
commit_all "init"
run_check
assert_eq "allowlist env-placeholder: exit 1 (concrete path still fires)" "1" "$CODE"
assert_not_contains "allowlist env-placeholder: placeholder.md suppressed" "$OUT" "placeholder.md:"
assert_contains "allowlist env-placeholder: concrete.md still reported" "$OUT" "concrete.md:"

# ---------------------------------------------------------------------------
# Test 9: allowlist rule 4 — leak-check.sh never flags itself, even though
# its own pattern list literally contains every string it searches for.
# ---------------------------------------------------------------------------
init_repo
commit_all "init"
run_check
assert_eq "self-allowlist: exit 0" "0" "$CODE"
assert_eq "self-allowlist: prints clean" "clean" "$OUT"

# ---------------------------------------------------------------------------
# Test 9b: allowlist rule 4 also covers this test suite's own file — its
# fixtures deliberately contain pattern-matching literals (192.168.1.1,
# GoodVibe, housegoodvibes, JARVIS, ...) as test data, not leaks. Regression
# for the real repo scan flagging tools/test/leak-check-test.sh itself.
# ---------------------------------------------------------------------------
init_repo
mkdir -p "$TMP_REPO/tools/test"
cp "${SCRIPT_DIR}/leak-check-test.sh" "$TMP_REPO/tools/test/leak-check-test.sh"
commit_all "init"
run_check
assert_eq "self-allowlist (test suite): exit 0" "0" "$CODE"
assert_eq "self-allowlist (test suite): prints clean" "clean" "$OUT"

# ---------------------------------------------------------------------------
# Test 10: --history finds a leak fixed in the working tree but still in an
# earlier commit; plain tree-mode does not see it.
# ---------------------------------------------------------------------------
init_repo
echo "housegoodvibes mentioned here" > "$TMP_REPO/history-note.md"
commit_all "add leak"
echo "nothing to see now" > "$TMP_REPO/history-note.md"
commit_all "scrub leak from working tree"
run_check
assert_eq "history: tree-mode alone is clean" "0" "$CODE"
run_check --history
assert_eq "history: --history still finds it: exit 1" "1" "$CODE"
assert_contains "history: --history names the old commit" "$OUT" "history-note.md"
assert_contains "history: --history shows the leaked content" "$OUT" "housegoodvibes"

# ---------------------------------------------------------------------------
# Test 11: unknown argument -> exit 2; --help -> exit 0 with usage
# ---------------------------------------------------------------------------
init_repo
commit_all "init"
run_check --bogus-flag
assert_eq "unknown arg: exit 2" "2" "$CODE"
run_check --help
assert_eq "help: exit 0" "0" "$CODE"
assert_contains "help: shows usage" "$OUT" "Usage:"

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
