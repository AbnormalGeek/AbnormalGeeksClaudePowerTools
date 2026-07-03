#!/usr/bin/env bash
# install.sh — mechanical installer for AbnormalGeeksClaudePowerTools.
#
# What it does (idempotent, no sudo):
#   1. Copies claude-config/          -> ~/.claude/        (backs up any file it would change)
#   2. Copies ai-workspace-template/  -> ~/ai_workspace/   (never overwrites existing files)
#   3. Replaces the __HOME__ placeholder in the installed ~/.claude/settings.json
#   4. Makes ~/.claude/statusline.sh executable
#
# It NEVER touches ~/.claude/settings.local.json, credentials, sessions, or projects.
# Backups of anything overwritten go to ~/.claude.backup-<UTC timestamp>/ (mirrored paths).
#
# Usage:
#   ./install.sh            perform the install
#   ./install.sh --dry-run  print every action without executing anything
set -euo pipefail

usage() {
  sed -n '2,15p' "$0"
}

DRY_RUN=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help) usage; exit 0 ;;
    *) printf 'Unknown argument: %s\n' "$arg" >&2; usage >&2; exit 2 ;;
  esac
done

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_SRC="$REPO_DIR/claude-config"
WORKSPACE_SRC="$REPO_DIR/ai-workspace-template"
CLAUDE_DEST="$HOME/.claude"
WORKSPACE_DEST="$HOME/ai_workspace"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
BACKUP_DIR="$HOME/.claude.backup-$STAMP"

installed=0
unchanged=0
skipped=0
backed_up=0

say() { printf '%s\n' "$*"; }

fail() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

[ -d "$CLAUDE_SRC" ] || fail "missing $CLAUDE_SRC — run from a full checkout of the repo"
[ -d "$WORKSPACE_SRC" ] || fail "missing $WORKSPACE_SRC — run from a full checkout of the repo"

# backup_file <existing-dest-file> <repo-relative-path>
# Mirrors the file into $BACKUP_DIR before it gets overwritten.
backup_file() {
  local dest="$1" rel="$2"
  if [ "$DRY_RUN" -eq 1 ]; then
    say "[dry-run] backup:   $dest -> $BACKUP_DIR/$rel"
  else
    mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
    cp -p "$dest" "$BACKUP_DIR/$rel"
    say "backup:   $dest -> $BACKUP_DIR/$rel"
  fi
  backed_up=$((backed_up + 1))
}

# install_claude_config: claude-config/ -> ~/.claude/, overwrite-with-backup.
# settings.json is rendered (__HOME__ -> $HOME) before comparison/install, so
# re-running on an already-installed machine reports "unchanged" (idempotent).
install_claude_config() {
  local f rel dest tmp
  while IFS= read -r -d '' f; do
    rel="${f#"$CLAUDE_SRC"/}"
    case "$rel" in
      settings.local.json|.credentials*|sessions/*|projects/*)
        say "skip (protected, never installed): $rel"
        skipped=$((skipped + 1))
        continue
        ;;
    esac
    dest="$CLAUDE_DEST/$rel"

    tmp="$(mktemp)"
    if [ "$rel" = "settings.json" ]; then
      # Portable across GNU and BSD/macOS sed: plain sed to a temp file, no -i.
      sed "s|__HOME__|$HOME|g" "$f" > "$tmp"
    else
      cp "$f" "$tmp"
    fi

    if [ -e "$dest" ] && cmp -s "$tmp" "$dest"; then
      unchanged=$((unchanged + 1))
      rm -f "$tmp"
      continue
    fi

    [ -e "$dest" ] && backup_file "$dest" "$rel"

    if [ "$DRY_RUN" -eq 1 ]; then
      say "[dry-run] install:  $rel -> $dest"
      rm -f "$tmp"
    else
      mkdir -p "$(dirname "$dest")"
      mv "$tmp" "$dest"
      say "install:  $rel -> $dest"
    fi
    installed=$((installed + 1))
  done < <(find "$CLAUDE_SRC" -type f -print0)
}

# install_workspace_template: ai-workspace-template/ -> ~/ai_workspace/,
# never overwrites — an existing file is skipped with a notice.
install_workspace_template() {
  local f rel dest
  while IFS= read -r -d '' f; do
    rel="${f#"$WORKSPACE_SRC"/}"
    dest="$WORKSPACE_DEST/$rel"
    if [ -e "$dest" ]; then
      say "skip (exists, not overwritten): $dest"
      skipped=$((skipped + 1))
      continue
    fi
    if [ "$DRY_RUN" -eq 1 ]; then
      say "[dry-run] install:  $rel -> $dest"
    else
      mkdir -p "$(dirname "$dest")"
      cp "$f" "$dest"
      say "install:  $rel -> $dest"
    fi
    installed=$((installed + 1))
  done < <(find "$WORKSPACE_SRC" -type f -print0)
}

say "== AbnormalGeeksClaudePowerTools installer =="
[ "$DRY_RUN" -eq 1 ] && say "(dry run — nothing will be written)"
say ""

say "-- claude-config/ -> $CLAUDE_DEST"
install_claude_config
say ""
say "-- ai-workspace-template/ -> $WORKSPACE_DEST"
install_workspace_template
say ""

if [ "$DRY_RUN" -eq 1 ]; then
  say "[dry-run] chmod +x $CLAUDE_DEST/statusline.sh"
elif [ -f "$CLAUDE_DEST/statusline.sh" ]; then
  chmod +x "$CLAUDE_DEST/statusline.sh"
  say "chmod +x $CLAUDE_DEST/statusline.sh"
fi

say ""
say "== Summary =="
say "installed: $installed   unchanged: $unchanged   skipped: $skipped   backed up: $backed_up"
if [ "$backed_up" -gt 0 ] && [ "$DRY_RUN" -eq 0 ]; then
  say "Your previous files are in: $BACKUP_DIR"
  say "IMPORTANT: diff that directory against ~/.claude and merge back anything you customized."
fi

say ""
say "== Next steps (SETUP.md has the full checklist) =="
say "1. Fill in the Identity section of ~/.claude/CLAUDE.md (SETUP.md step 2 interviews you)."
say "2. Register MCP servers (exact commands in docs/mcp-servers.md), for example:"
say "     claude mcp add --scope user --transport http context7 https://mcp.context7.com/mcp"
say "     claude mcp add --scope user playwright -- npx @playwright/mcp@latest"
say "3. Make ~/.claude a git repo (SETUP.md step 4) so /sync-config can version your setup."
say "4. Verify: jq . ~/.claude/settings.json && claude mcp list"
