#!/usr/bin/env bash
# PostToolUse hook: format the file Claude just edited, if a formatter is available.
# Receives the tool-call JSON on stdin. No-op when no formatter is installed, so
# it is safe to ship in every project.
input=$(cat)
file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
[ -z "$file" ] && exit 0
[ -f "$file" ] || exit 0

case "$file" in
  *.ts|*.tsx|*.js|*.jsx|*.json|*.css|*.scss|*.html|*.md|*.yaml|*.yml)
    if [ -x node_modules/.bin/prettier ]; then
      node_modules/.bin/prettier --write "$file" >/dev/null 2>&1 || true
    fi
    ;;
  *.py)
    if command -v ruff >/dev/null 2>&1; then
      ruff format "$file" >/dev/null 2>&1 || true
    fi
    ;;
  *.go)
    command -v gofmt >/dev/null 2>&1 && gofmt -w "$file" >/dev/null 2>&1 || true
    ;;
  *.rs)
    command -v rustfmt >/dev/null 2>&1 && rustfmt "$file" >/dev/null 2>&1 || true
    ;;
esac
exit 0
