---
name: gh-env-secrets
description: Securely add or update GitHub Actions secrets (environment-scoped or repo-level) without secret values ever entering the chat transcript or shell history. Writes a gitignored .env template the user fills in locally, then pipes values into gh via stdin, verifies, and shreds the file. Use whenever a task needs secrets set on a GitHub repo or environment.
---

# gh-env-secrets — secure GitHub secret upload

Secret VALUES must never appear in: the conversation transcript, command argv
(`--body 'x'` is forbidden for real secrets), tool descriptions, logs, or any
git-tracked file. The user types values only into a local, gitignored,
mode-600 file; the agent moves them file → gh stdin → GitHub, then destroys
the file. Never ask the user to paste a secret into chat. Never Read/cat/echo
the filled file.

## 1. Resolve target

- Repo: `gh repo view --json nameWithOwner -q .nameWithOwner` (or the repo the
  task names).
- Environment: default `production` unless the task says otherwise. List what
  exists: `gh api repos/<owner>/<repo>/environments -q '.environments[].name'`.
  If the needed environment is missing, create it:
  `gh api -X PUT repos/<owner>/<repo>/environments/<name>`.
- Repo-level secrets (no environment): same flow, drop every `--env` flag.

## 2. Decide which keys are needed

From the task context, plus a gap check when useful:

```bash
grep -rhoE 'secrets\.[A-Z0-9_]+' .github/workflows/ | sort -u   # referenced
gh secret list --env <env>                                       # already set
```

## 3. Write the template file

Path: `<repo-root>/.env.github.<env>.local` (e.g. `.env.github.production.local`).

- One entry per key: a `#` comment line saying what it is and exactly where the
  user finds the value, then `KEY=` left blank.
- Prefill values you legitimately know that are NOT secrets (URLs, hostnames,
  flags) so the user only fills the sensitive ones.
- For a multi-line secret (private key, JSON blob), instruct the user to save
  it to its own file and put `KEY=@/absolute/path/to/that/file` in the entry.
- `chmod 600` the file.
- Ensure git ignores it (use `.git/info/exclude`, never a tracked .gitignore
  edit, so the convention needs no commit):

```bash
git check-ignore -q .env.github.<env>.local || echo '.env.github.*.local' >> .git/info/exclude
```

## 4. Hand off to the user — and STOP

Tell the user the file path and which keys to fill, then end the turn. Do not
poll, do not read the file to "check progress". Wait for them to say it's
filled.

## 5. Upload — pipe, never argv

Write this uploader to the scratchpad (not the repo), run it, then delete it.
It reads each `KEY=value` line and feeds the value to `gh` via stdin, so values
never hit argv, transcript, or history. Only key NAMES are printed.

```bash
#!/usr/bin/env bash
set -euo pipefail
FILE="$1" ENVN="$2" REPO="$3"
while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in ''|\#*) continue ;; esac
  key="${line%%=*}" value="${line#*=}"
  [ -n "$value" ] || { echo "SKIP (empty): $key"; continue; }
  if [ "${value#@}" != "$value" ]; then
    gh secret set "$key" --env "$ENVN" --repo "$REPO" < "${value#@}"
  else
    printf '%s' "$value" | gh secret set "$key" --env "$ENVN" --repo "$REPO"
  fi
  echo "SET: $key"
done < "$FILE"
```

Repo-level: drop `--env "$ENVN"`. Actions *variables* (non-secret): same
pattern with `gh variable set`.

## 6. Verify

`gh secret list --env <env>` — confirm every uploaded key is present with a
fresh timestamp. Report SET / SKIP counts by name only.

## 7. Destroy the material

```bash
shred -u <file>        # fallback: rm -f if shred is unavailable
```

Also shred any `@file` side-files the user created for multi-line secrets (ask
first if the user might want to keep them, e.g. an SSH key that lives in
~/.ssh anyway).

## 8. Close the loop

Secrets reach the running system only when whatever consumes them runs (a
deploy regenerating a VM .env, the next workflow run). Say what has to happen
for the new values to take effect, and offer to trigger it if that's in scope.
