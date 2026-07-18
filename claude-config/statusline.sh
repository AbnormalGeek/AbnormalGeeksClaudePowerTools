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

live=""
live_state_file="${HOME}/.claude/state/subagents-live.json"
if [ -s "$live_state_file" ]; then
  live=$(jq -r '
    if (type == "array") and (length > 0) then
      (length) as $n
      | ([.[].agent_type] | reduce .[] as $x ([]; if any(.[]; . == $x) then . else . + [$x] end)) as $types
      | ($types[0:3] | join(",")) as $shown
      | (if ($types|length) > 3 then "(+\(($types|length)-3))" else "" end) as $more
      | " | 🕸 \($n) \($shown)\($more)"
    else empty end
  ' "$live_state_file" 2>/dev/null)
fi

printf "\033[36m%s\033[0m \033[90m|\033[0m \033[32m%s\033[0m%b%s" "$model" "$dir" "$branch" "$live"
