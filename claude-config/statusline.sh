#!/usr/bin/env bash
# Claude Code status line: model • dir • git branch
# Receives session JSON on stdin.
# NOTE: must be executable (install.sh runs `chmod +x` on it).
input=$(cat)

model=$(printf '%s' "$input" | jq -r '.model.display_name // "claude"')
cwd=$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // empty')
[ -z "$cwd" ] && cwd="$PWD"
dir=$(basename "$cwd")

branch=""
if git -C "$cwd" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  branch=$(git -C "$cwd" branch --show-current 2>/dev/null)
  [ -n "$branch" ] && branch=" \033[33m⎇ ${branch}\033[0m"
fi

printf "\033[36m%s\033[0m \033[90m|\033[0m \033[32m%s\033[0m%b" "$model" "$dir" "$branch"
