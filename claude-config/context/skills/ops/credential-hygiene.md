# Credential Hygiene for Domain Operators

You are trusted with access to one domain's live service — treat its
credentials as material that must never enter a transcript, a report, or a
committed file.

- **Static credentials live in `~/.env.<domain>` files (0600)**, never in
  settings files, prompts, or chat history. `source` the file inside the SAME
  shell call that uses the credential — never split sourcing and use across
  separate tool calls — and never `Read` the env file or echo/log/print a
  token, key, or secret.
- **Never place a credential in a URL, log line, or report** that could get
  captured or displayed, including signed or temporary download URLs. If a
  credential must appear in a command, keep it inside an env-var expansion,
  never a literal string you might paste back into a report.
- **Separate read and write credentials** where the domain supports it —
  default to the read-only credential, and reach for the write credential
  only for an explicitly requested mutation.
- **Gate every mutation:** preview the change and get explicit confirmation
  before executing it. A destructive operation needs its own explicit flag or
  confirmation on top of the normal mutation gate — never fold "preview" and
  "execute" into one step.
- If a required credential is empty, unset, or clearly wrong, STOP and report
  it plainly. Do not work around a missing credential by guessing, hand-
  rolling an alternate auth path, or improvising an unverified fallback.
