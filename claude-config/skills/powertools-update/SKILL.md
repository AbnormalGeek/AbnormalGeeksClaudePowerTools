---
name: powertools-update
description: "Update the PowerTools harness: pull the latest repo, review what changed, and re-run the installer with backups"
user-invocable: true
---

Update the PowerTools harness and re-sync it into the live ~/.claude.

1. Locate the PowerTools clone (default `~/ai_workspace/AbnormalGeeksClaudePowerTools`).
   If it is not there, ask the user where it lives, or offer to clone it.
2. Record the current HEAD (`git rev-parse HEAD`) before pulling.
3. Run `git pull --ff-only`. If it fails (diverged history, local edits), stop
   and surface the error; do not force anything.
4. Show what changed: `git log --oneline <old-head>..HEAD` and
   `git diff --stat <old-head>..HEAD`.
5. Run `./install.sh --dry-run` and summarize what it would change against the
   user's live `~/.claude` (new files, overwritten files, deletions).
6. Get explicit user confirmation before applying anything.
7. Run `./install.sh --yes`.
8. Remind the user: per-file backups land in `~/.claude.backup-<timestamp>/`.
   Personalized files (CLAUDE.md identity, settings customizations) may need
   manual re-merge from that backup, since the installer does not merge them
   automatically. Walk the user through any conflicts by diffing the backup
   against the freshly installed file.
9. Finish by offering to run `/sync-config` to commit the user's `~/.claude`.
