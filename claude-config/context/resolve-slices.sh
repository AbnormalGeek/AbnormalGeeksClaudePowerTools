#!/usr/bin/env bash
# claude-config/context/resolve-slices.sh — installs to ~/.claude/context/.
#
# Resolves each argument (a context-library-relative path, e.g.
# "skills/code/atomic-leaf.md") against the local-overlay-wins convention and
# prints its content to stdout: a file at the same relative path under
# ~/.claude/context-local/ always wins over the shared copy under
# ~/.claude/context/. If neither copy exists, a warning goes to stderr
# (`resolve-slices: missing <path>`) and that one slice is skipped — the run
# always continues and always exits 0, so one missing/renamed slice never
# breaks the whole persona load.
#
# Why this exists: every generated/hand-maintained loader skill needs a
# per-slice "local overlay wins, else shared, else warn" resolution at
# INVOCATION time. Doing that inline as a `for`/`if` shell-expansion inside a
# skill's `` !`...` `` preamble line defeats Claude Code's Bash permission
# allowlist matcher — an arbitrary shell loop/conditional is not something the
# matcher can safely auto-approve under default permission mode — so persona
# content silently failed to inject. A single script invocation,
# `bash ~/.claude/context/resolve-slices.sh <path1> <path2> ...`, is one
# simple, allowlistable command instead.
#
# Called by BOTH:
#   - repo-generated persona loader skills (tools/gen-persona-skills.sh output,
#     claude-config/skills/persona-<group>-<persona>/SKILL.md)
#   - hand-maintained loader skills (roster-sdm, roster-sde, liveliness, and
#     the unity-cli-core / unity-cli-editor-tools / unity-cli-testing /
#     unity-seat / unity-project-profile skills)
#
# Usage: resolve-slices.sh <path1> [path2 ...]
#   Prints each resolved slice's content to stdout, in argument order.
#   Always exits 0.
set -u

for path in "$@"; do
  local_path="$HOME/.claude/context-local/$path"
  shared_path="$HOME/.claude/context/$path"
  if [ -f "$local_path" ]; then
    cat "$local_path"
  elif [ -f "$shared_path" ]; then
    cat "$shared_path"
  else
    printf 'resolve-slices: missing %s\n' "$path" >&2
  fi
done

exit 0
