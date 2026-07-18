#!/usr/bin/env bash
# tools/leak-check.sh — standing guard against personal/homelab content or
# credential material shipping in this repo (a generalized, shareable
# agentic-dev setup — nothing homelab-specific belongs in it).
#
# Default mode scans the working tree: every git-tracked file (git ls-files)
# plus every untracked-but-not-gitignored file (git ls-files --others
# --exclude-standard), excluding .git itself (git never lists into it).
#
# --history additionally sweeps every blob reachable from every commit on
# every ref (git rev-list --all, then git grep per commit) — catches a leak
# that was fixed in the working tree but still lives in history.
#
# --history is a diagnostic AUDIT, not a push gate (only tree mode gates
# .githooks/pre-push): it can legitimately report superseded blobs — e.g. an
# old commit's generic template example that was later genericized further
# out of the working tree. A history-mode hit needs a human to judge whether
# it was ever a real leak; it is deliberately NOT auto-silenced by the
# allowlist below (see is_allowlisted) the way a tree-mode false positive is.
#
# Output: one line per hit —
#   tree mode:    file:line: matched-line
#   history mode: commit:file:line: matched-line   (git grep's own format,
#                 prefixed with the commit — a superset of the requested
#                 "commit:file: line" shape, kept for exact reproducibility)
#
# A small allowlist (see is_allowlisted below) filters out known-benign
# matches: this repo's own README self-references, a documented placeholder
# secret shape, `~/.env.<domain>`-style credential-location instructions, and
# this script + its test suite (both necessarily contain the literal strings
# they search for / test against).
#
# Exit 0 ("clean") when no non-allowlisted hit remains; exit 1 (hit list +
# a count summary) otherwise.
#
# Usage:
#   tools/leak-check.sh             scan the working tree
#   tools/leak-check.sh --history   working tree + every commit in history
set -euo pipefail

usage() {
  sed -n '2,38p' "$0"
}

HISTORY=0
for arg in "$@"; do
  case "$arg" in
    --history) HISTORY=1 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown argument: %s\n' "$arg" >&2; usage >&2; exit 2 ;;
  esac
done

REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"

# Case-sensitive patterns: homelab hostnames/nodes, brand/name strings, and
# credential shapes. Extended regex (grep -E / git grep -E).
CASE_SENSITIVE_PATTERNS=(
  '192\.168\.'
  '10\.0\.[0-9]'
  'BattlesDesktop'
  'pve-(cpu|gpu|game)'
  '\bUDM\b|\bUNAS\b'
  'housegoodvibes'
  'goodvibegames'
  'GoodVibe'
  'Tomasetti'
  'battletomasetti'
  'Hexbound'
  '/home/battle'
  'sk-[A-Za-z0-9]{8,}'
  'AKIA[A-Z0-9]{8,}'
  'ghp_[A-Za-z0-9]{8,}'
  '-----BEGIN [A-Z ]*PRIVATE KEY'
)

# Case-insensitive patterns: generic-enough words/handles that also show up
# lowercase, mid-word, or in casual references. Word-boundaried (\b...\b)
# where the bare substring would false-positive on ordinary English words —
# \bunifi\b still matches "unifi-network", "UniFi", "unifi.example.com" (the
# boundary sits at the hyphen/dot) but no longer matches "unified" (no
# boundary before the "ed").
CASE_INSENSITIVE_PATTERNS=(
  '\bjarvis\b'
  '\bunifi\b'
  'seedbox'
  'gvgllc'
)

# join_by <sep> <items...> — joins with a single-character separator via IFS.
join_by() {
  local sep="$1"
  shift
  local IFS="$sep"
  printf '%s' "$*"
}

CS_COMBINED="$(join_by '|' "${CASE_SENSITIVE_PATTERNS[@]}")"
CI_COMBINED="$(join_by '|' "${CASE_INSENSITIVE_PATTERNS[@]}")"

# is_allowlisted <path> <content> — true (0) if this specific hit is a known
# benign match, not a real leak. Each rule documents WHY it's safe.
is_allowlisted() {
  local path="$1" content="$2"

  # 1. This repo's own GitHub URL / @AbnormalGeek mentions in README.md —
  #    the repo's author/host handle, not a leaked personal detail.
  if [[ "$path" == "README.md" && "$content" == *"AbnormalGeek"* ]]; then
    return 0
  fi

  # 2. The literal `sk-...` placeholder in docs/local-llm-offload.md — shows
  #    the SHAPE of a key for documentation purposes, never a real secret.
  if [[ "$path" == "docs/local-llm-offload.md" && "$content" == *"sk-..."* ]]; then
    return 0
  fi

  # 3. `~/.env.<domain>`-style instructions for where a domain specialist's
  #    credentials live — a naming CONVENTION (placeholder token or glob),
  #    never a concrete domain/service name.
  if [[ "$content" == *'~/.env.'* ]] \
    && { [[ "$content" == *'<'*'>'* ]] || [[ "$content" == *'.env.*'* ]]; }; then
    return 0
  fi

  # 4. tools/leak-check.sh itself (its own pattern list) and its regression
  #    suite (tools/test/leak-check-test.sh, whose fixtures deliberately
  #    contain every pattern on purpose, as literal test data) — neither may
  #    ever flag itself.
  if [[ "$path" == "tools/leak-check.sh" || "$path" == "tools/test/leak-check-test.sh" ]]; then
    return 0
  fi

  return 1
}

# filter_hits <mode: tree|history> — reads raw grep/git-grep lines on stdin,
# drops allowlisted hits, prints survivors in the documented output shape.
filter_hits() {
  local mode="$1" line path lineno content commit rest
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    if [[ "$mode" == "history" ]]; then
      commit="${line%%:*}"; rest="${line#*:}"
      path="${rest%%:*}"; rest="${rest#*:}"
      lineno="${rest%%:*}"; content="${rest#*:}"
    else
      path="${line%%:*}"; rest="${line#*:}"
      lineno="${rest%%:*}"; content="${rest#*:}"
    fi

    is_allowlisted "$path" "$content" && continue

    if [[ "$mode" == "history" ]]; then
      printf '%s:%s:%s: %s\n' "$commit" "$path" "$lineno" "$content"
    else
      printf '%s:%s: %s\n' "$path" "$lineno" "$content"
    fi
  done
}

# scan_tree — every tracked + untracked-but-not-ignored file, NUL-delimited
# throughout so unusual filenames can't break the split.
scan_tree() {
  local existing=()
  local f
  while IFS= read -r -d '' f; do
    [[ -f "$f" ]] && existing+=("$f")
  done < <({ git ls-files -z; git ls-files -z --others --exclude-standard; } | sort -z -u)

  [[ ${#existing[@]} -eq 0 ]] && return 0

  # -I: skip binary files instead of dumping binary match noise.
  grep -nHEI -- "$CS_COMBINED" "${existing[@]}" 2>/dev/null || true
  grep -nHEIi -- "$CI_COMBINED" "${existing[@]}" 2>/dev/null || true
}

# scan_history — every commit reachable from every ref; git grep against
# each commit's full tree (so deleted-but-once-committed files are covered).
scan_history() {
  local commit
  git rev-list --all | while IFS= read -r commit; do
    git grep -nEI -e "$CS_COMBINED" "$commit" -- 2>/dev/null || true
    git grep -nEIi -e "$CI_COMBINED" "$commit" -- 2>/dev/null || true
  done
}

OUT_FILE="$(mktemp)"
trap 'rm -f "$OUT_FILE"' EXIT

scan_tree | filter_hits tree >> "$OUT_FILE"

if [[ "$HISTORY" -eq 1 ]]; then
  scan_history | filter_hits history >> "$OUT_FILE"
fi

HIT_COUNT="$(wc -l < "$OUT_FILE" | tr -d ' ')"

if [[ "$HIT_COUNT" -gt 0 ]]; then
  cat "$OUT_FILE"
  printf '\n%d leak-pattern hit(s) found (not allowlisted).\n' "$HIT_COUNT" >&2
  exit 1
fi

echo "clean"
exit 0
