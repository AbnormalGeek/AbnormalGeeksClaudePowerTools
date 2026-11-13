#!/usr/bin/env bash
# pre-push-test.sh: proves .githooks/pre-push fails closed. Builds a scratch
# repo with a local bare repo as the remote (never a real remote), installs
# the hook, swaps in stub leak-check scripts and asserts push outcomes.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_SRC="${SCRIPT_DIR}/../../.githooks/pre-push"

pass=0
fail=0
ok()  { pass=$((pass + 1)); printf 'PASS: %s\n' "$1"; }
bad() { fail=$((fail + 1)); printf 'FAIL: %s\n' "$1"; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_SYSTEM=/dev/null

BARE="$TMP/remote.git"
WORK="$TMP/work"
git init -q --bare "$BARE"
git init -q "$WORK"
mkdir -p "$WORK/tools" "$WORK/.githooks"
cp "$HOOK_SRC" "$WORK/.githooks/pre-push"
chmod +x "$WORK/.githooks/pre-push"
(
  cd "$WORK" || exit 1
  git config user.email t@example.invalid
  git config user.name tester
  git config core.hooksPath .githooks
  git remote add origin "$BARE"
  echo x > file.txt
  git add file.txt
  git commit -q -m init
)

# scenario <name> <stub-body|__MISSING__> <chmod-mode> <expect: allowed|refused> <needle>
scenario() {
  local name="$1" body="$2" mode="$3" expect="$4" needle="$5" out rc
  rm -f "$WORK/tools/leak-check.sh"
  if [[ "$body" != "__MISSING__" ]]; then
    printf '#!/usr/bin/env bash\n%s\n' "$body" > "$WORK/tools/leak-check.sh"
    chmod "$mode" "$WORK/tools/leak-check.sh"
  fi
  out="$(cd "$WORK" && git push -q origin HEAD:refs/heads/test 2>&1)"
  rc=$?
  if [[ "$expect" == allowed && $rc -eq 0 ]] || [[ "$expect" == refused && $rc -ne 0 ]]; then
    ok "$name: push $expect"
  else
    bad "$name: expected $expect, got rc=$rc"
  fi
  if [[ -n "$needle" ]]; then
    if [[ "$out" == *"$needle"* ]]; then ok "$name: message names [$needle]"; else bad "$name: missing [$needle] in [$out]"; fi
  fi
  (cd "$WORK" && git push -q origin --delete test >/dev/null 2>&1 || true)
}

scenario "clean"            'exit 0'                 755 allowed ""
scenario "finding"          'echo hit >&2; exit 1'   755 refused "leak-check found"
scenario "missing"          __MISSING__              755 refused "leak-check missing (tools/leak-check.sh)"
scenario "not executable"   'exit 0'                 644 refused "leak-check not runnable"
scenario "unexpected code 2"   'exit 2'              755 refused "failed to run (exit 2"
scenario "unexpected code 127" 'exit 127'            755 refused "failed to run (exit 127"
scenario "killed by signal"    'kill -9 $$'          755 refused "failed to run"

# A skip-style env variable must not bypass the gate.
SKIP_LEAK_CHECK=1 LEAK_CHECK_SKIP=1 scenario "env skip ignored" __MISSING__ 755 refused "leak-check missing"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[[ $fail -eq 0 ]]
