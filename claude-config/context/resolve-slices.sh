#!/usr/bin/env bash
# claude-config/context/resolve-slices.sh — installs to ~/.claude/context/.
#
# Resolves each argument (a context-library-relative path, e.g.
# "skills/code/atomic-leaf.md") against a three-tier, most-specific-wins
# convention and prints its content to stdout:
#
#   1. PROJECT tier — a per-repo doctrine-slice overlay. If $CLAUDE_PROJECT_DIR
#      is set and non-empty, checked at
#      "$CLAUDE_PROJECT_DIR/.claude/context-local/<path>". Otherwise, walked
#      up from $PWD toward / (checking "<dir>/.claude/context-local/<path>" at
#      every ancestor), stopping BEFORE (not checking) $HOME and / themselves
#      — so $HOME/.claude/context-local is never mistaken for a project root,
#      it is tier 2 below. First ancestor with a hit wins.
#   2. MACHINE-LOCAL tier — ~/.claude/context-local/<path>, the whole-machine
#      overlay.
#   3. SHARED tier — ~/.claude/context/<path>, the checked-in default.
#
# If none of the three exist, a warning goes to stderr
# (`resolve-slices: missing <path>`) and that one slice is skipped — the run
# always continues and always exits 0, so one missing/renamed slice never
# breaks the whole persona load.
#
# Why the project tier exists: a doctrine slice can be genuinely specific to
# ONE repo (e.g. skills/unity/project-profile.md, which fills in one Unity
# project's VCS/conventions/test landscape) rather than to the whole machine.
# Before this tier, such a file had to live under the machine-local overlay
# and silently shadowed the generic template for every OTHER project's
# sessions/agents. A project tier that wins over machine-local (but loses to
# nothing broader) lets a repo carry its own overlay without polluting every
# other project's resolution.
#
# Why this exists at all: every generated/hand-maintained loader skill needs a
# per-slice "most-specific overlay wins, else fall through, else warn"
# resolution at INVOCATION time. Doing that inline as a `for`/`if` shell-
# expansion inside a skill's `` !`...` `` preamble line defeats Claude Code's
# Bash permission allowlist matcher — an arbitrary shell loop/conditional is
# not something the matcher can safely auto-approve under default permission
# mode — so persona content silently failed to inject. A single script
# invocation, `bash ~/.claude/context/resolve-slices.sh <path1> <path2> ...`,
# is one simple, allowlistable command instead.
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

# Prints (to stdout) the path to the nearest project-tier override of
# "<ancestor>/.claude/context-local/$1", or returns 1 if none exists.
find_project_local() {
  local relpath="$1"
  local dir candidate

  if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
    candidate="$CLAUDE_PROJECT_DIR/.claude/context-local/$relpath"
    if [ -f "$candidate" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
    return 1
  fi

  dir="$PWD"
  while [ "$dir" != "/" ] && [ "$dir" != "$HOME" ]; do
    candidate="$dir/.claude/context-local/$relpath"
    if [ -f "$candidate" ]; then
      printf '%s\n' "$candidate"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

for path in "$@"; do
  project_path=""
  local_path="$HOME/.claude/context-local/$path"
  shared_path="$HOME/.claude/context/$path"
  if project_path="$(find_project_local "$path")"; then
    cat "$project_path"
  elif [ -f "$local_path" ]; then
    cat "$local_path"
  elif [ -f "$shared_path" ]; then
    cat "$shared_path"
  else
    printf 'resolve-slices: missing %s\n' "$path" >&2
  fi
done

exit 0
