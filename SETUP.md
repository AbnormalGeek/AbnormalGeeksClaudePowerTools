# SETUP.md — machine setup instructions (for Claude)

You are Claude Code, running on a new user's machine, and you have just cloned this repo
(probably to `~/ai_workspace/AbnormalGeeksClaudePowerTools`). Follow these steps **in order**.
Each step ends with a verification command — run it and confirm the expected result before
moving on. Do not skip verifications. Work from the repo root.

Two rules that govern everything you do here:

1. **Merge, don't clobber.** If this machine already has `~/.claude` content, `install.sh`
   backs up anything it overwrites to `~/.claude.backup-<timestamp>/`. You must diff that
   backup against the installed files and merge back anything meaningful the user had
   (custom permissions, hooks, CLAUDE.md content, agents). Ask the user when unsure.
2. **No attribution trailers, ever.** The installed config's Golden Rule 0 applies to *you,
   right now*: commits you make during this setup contain only the change description — no
   `Co-Authored-By`, no "Generated with Claude", no session URLs.

---

## Step 0 — Preconditions

Run each check. If one fails, fix it (with the user's help where needed) before continuing.

```bash
claude --version        # Claude Code installed (you are proof, but capture the version)
gh auth status          # GitHub CLI authenticated — required (this repo is private)
git --version           # git present
jq --version            # jq present — REQUIRED: statusline.sh, the Notification hook, and
                        #   the SubagentStart/Stop liveliness hook all use it
flock --version         # part of util-linux — REQUIRED by the liveliness hook's state-file lock
node --version          # Node.js present — required for the playwright MCP server (npx) in Step 3
uname -s                # OS: Linux or Darwin — note which, some steps mention differences
```

- If `jq` is missing, install it via the system package manager (may need the user for sudo).
- If `flock` is missing (rare — it ships with `util-linux` on virtually every Linux distro;
  on macOS `brew install util-linux`), the liveliness hook still degrades gracefully (it exits
  silently rather than blocking a spawn), but agent activity won't show in the statusline.
- If `node` (and with it `npx`) is missing, install it via the system package manager or nvm —
  or, if the user doesn't want Node, skip the playwright registration in Step 3 and tell them
  it can be added later.
- On Linux, check `command -v notify-send` — the Notification hook uses it for desktop
  notifications. It is optional: the hook is written to no-op silently where `notify-send`
  is absent, so a miss here is fine (just tell the user).
- Note whether `~/.claude` already exists and is non-trivial (`ls -la ~/.claude`). If it
  does, the merge rule above is in force for the rest of setup.

## Step 1 — Run the installer

`install.sh` is a mechanical, idempotent, no-sudo copier. Exactly what it does:

1. Copies `claude-config/` → `~/.claude/`, backing up any existing file that would change
   into `~/.claude.backup-<UTC timestamp>/` (mirrored paths).
2. Copies `ai-workspace-template/` → `~/ai_workspace/`, **never** overwriting an existing
   file (skips with a notice).
3. Renders the `__HOME__` placeholder in the installed `~/.claude/settings.json` to the
   real `$HOME`.
4. `chmod +x ~/.claude/statusline.sh`.
5. It never touches `~/.claude/settings.local.json`, credentials, sessions, or projects.

Run it — dry-run first, review the plan, then for real:

```bash
./install.sh --dry-run   # review: every action it would take, nothing written
./install.sh             # perform the install
```

The real run now prints the resolved target (e.g. `Installing to: ~/.claude`) and asks
for a y/N confirmation before writing anything — answer `y`, or use `./install.sh --yes`
if your Bash tool isn't attached to a TTY (a non-interactive run without `--yes` aborts
instead of hanging).

**Verify:**

```bash
jq . ~/.claude/settings.json > /dev/null && echo settings-valid
grep -c __HOME__ ~/.claude/settings.json   # expect: 0 (placeholder fully replaced)
test -x ~/.claude/statusline.sh && echo statusline-executable
find ~/.claude/hooks -maxdepth 1 -name '*.sh' -perm -u+x   # expect: subagent-liveliness.sh listed
ls ~/.claude/agents ~/.claude/commands ~/.claude/skills ~/.claude/rules \
   ~/.claude/rosters ~/.claude/templates/agents
```

**If a backup directory was created** (installer summary says so): for each file in
`~/.claude.backup-<timestamp>/`, `diff` it against the installed counterpart. Merge back
user customizations that matter — especially extra `permissions.allow` entries, hooks, MCP
config, and any personal content in `CLAUDE.md`. Do **not** merge back attribution/trailer
settings or anything that contradicts the installed Golden Rules without asking the user.

## Step 2 — Interview the user, personalize CLAUDE.md

The installed `~/.claude/CLAUDE.md` has a placeholder **Identity & Communication** section.
Interview the user (use AskUserQuestion or plain questions) for:

- Name, and GitHub username
- Shell (`echo $SHELL` as a default guess) and any framework (oh-my-zsh, starship, …)
- OS/distro (you detected it in Step 0 — confirm)
- Communication preferences (the default is: direct, concise, technical — confirm it fits)
- Primary machine description they'd like recorded (hostname, role)

Then edit `~/.claude/CLAUDE.md`: fill every placeholder in the Identity section with their
answers. Also personalize `~/ai_workspace/.claude/CLAUDE.md` (installed in Step 1) with the
same facts where its placeholders call for them.

**Verify:** `grep -n '<your-' ~/.claude/CLAUDE.md ~/ai_workspace/.claude/CLAUDE.md` returns
nothing (no unfilled placeholders remain).

## Step 3 — Register MCP servers

Exact commands and rationale live in [docs/mcp-servers.md](docs/mcp-servers.md). Read it,
run the registration commands for the two standard servers (context7 for live library docs,
playwright for real-browser E2E), and offer the optional ones to the user.

**Verify:**

```bash
claude mcp list   # expect: context7 and playwright listed, status connected/available
```

## Step 4 — Make ~/.claude a git repo

The installed `~/.claude/.gitignore` is allowlist-style: it ignores everything, then
un-ignores just the durable config it lists explicitly. Sessions, credentials, caches
stay untracked. **Before running `git add -A` below, diff `~/.claude/.gitignore` against
what actually landed in Step 1** (`ls ~/.claude`) — if `rosters/`, `templates/`, or `hooks/`
exist but aren't un-ignored, add `!/rosters`, `!/templates`, `!/hooks` lines before staging,
or those directories silently won't be tracked.

```bash
cd ~/.claude
git init -b main
git add -A
git status          # review: only config files staged, no credentials/sessions
git commit -m "chore: initial Claude Code power-tools config"
```

Explain to the user: from now on, after any change to global config, running `/sync-config`
in a Claude session commits (and pushes, if they later add a private remote) the `~/.claude`
repo. Offer to create a **private** GitHub repo for it now (`gh repo create`) — their call.

**Verify:** `git -C ~/.claude log --oneline` shows the initial commit;
`git -C ~/.claude status --porcelain` is clean.

## Step 5 — Set up ~/ai_workspace

`install.sh` already copied `ai-workspace-template/` to `~/ai_workspace/`. This is the
user's primary general-purpose workspace — the default place to launch Claude for anything
that isn't a specific project repo. Now:

1. Confirm `~/ai_workspace/.claude/CLAUDE.md` was personalized in Step 2.
2. Read `~/ai_workspace/README.md` and walk the user through what the workspace is for.
3. Optionally `git init` the workspace if the user wants it versioned.

**Verify:** `ls -la ~/ai_workspace/.claude/` shows `CLAUDE.md`; launching `claude` from
`~/ai_workspace` picks up both the global and workspace context.

## Step 6 — Final verification checklist

Run all of these; every line must pass:

```bash
jq . ~/.claude/settings.json > /dev/null && echo OK-settings
jq -r '.model' ~/.claude/settings.json                       # expect: claude-fable-5[1m]
ls ~/.claude/agents/*.md | wc -l                             # expect: 18 files (17 runnable agents +
                                                              #   domain-agent-template.md, which has no
                                                              #   frontmatter by design — it's a template,
                                                              #   not something Claude Code loads as an agent)
ls ~/.claude/skills/    # expect 8: liveliness new-agent roster-sdm roster-sde
                        #   setup-project spec-new spec-run spec-status
ls ~/.claude/rosters/   # expect 4: fleet-map.md liveliness.md sdm-playbook.md sde-support.md
ls ~/.claude/templates/agents/   # expect 4: orchestrator.md dev.md utility.md ops-specialist.md
find ~/.claude/hooks -name '*.sh' -perm -u+x | wc -l   # expect: 1+ (subagent-liveliness.sh executable)
ls ~/.claude/commands/                                       # expect: ci-check.md sync-config.md
echo '{"model":{"display_name":"Test"},"workspace":{"current_dir":"'"$HOME"'"}}' \
  | ~/.claude/statusline.sh; echo                            # expect: "Test | <dir>" with colors
claude mcp list                                              # expect: context7, playwright — doc-fetcher
                                                              #   (agents/doc-fetcher.md) expects context7 too
git -C ~/.claude status --porcelain                          # expect: empty (clean)
```

Then have the user start a fresh `claude` session in `~/ai_workspace` and check:

- `/status` shows the expected model
- `/agents` lists all 17 runnable agents (`project-manager`, `agent-smith`, `researcher`,
  `agent-forge`, `coder`, `java-dev`, `python-dev`, `ts-dev`, `git-ops`, `config-editor`,
  `context-keeper`, `validator`, `distiller`, `web-fetcher`, `log-analyzer`, `repo-scout`,
  `doc-fetcher`) — `domain-agent-template.md` deliberately has no frontmatter, so it won't
  appear here; copy it to create your own domain specialist (see how-it-works.md)
- The statusline renders at the bottom of the terminal, and shows live agent activity once
  you spawn a subagent (the `SubagentStart`/`SubagentStop` hook + statusline liveliness channel)

## What to try first

Suggest these to the user, in order:

1. **In any existing project repo:** run `/setup-project` — it drops the per-project rules
   and wires the repo into the planning layout.
2. **Small end-to-end feature:** in a project, ask the top-level session to hand a small,
   well-defined feature to the **project-manager** agent and watch the pipeline run:
   research fan-out → central plan in `~/.claude/planning/<slug>/` → parallel coders →
   validator gate.
3. **Escalation habits:** for substantive sessions, run as Fable 5 with `/effort ultracode`;
   use `ultrathink` in a single prompt for one-off deep reasoning. The subagents carry
   cheaper pinned models, so delegation keeps cost sane.
4. Read [docs/how-it-works.md](docs/how-it-works.md) together for the full system picture.

When everything above passes, tell the user setup is complete and summarize: what was
installed, what was backed up (if anything), what was merged, and the three "try first"
actions.
