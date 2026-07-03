# Local LLM Offload — the `askllm` Seam (Optional)

**Entirely optional.** If you run a local LLM behind an OpenAI-compatible gateway (LiteLLM,
Ollama, vLLM, LM Studio — anything that serves `/v1/chat/completions`), this pattern gives your
agents a **zero-token-cost seam for bulk text work**: distilling giant logs, summarizing huge
files, mechanical text transforms. The `distiller` agent uses it when present and simply falls
back to doing the work itself (on haiku) when it isn't.

If you don't have local inference hardware, skip this page — nothing else in the setup depends
on it.

## The contract

Three environment variables (put them in `~/.env`, which the script sources):

| Variable | Meaning | Example |
|----------|---------|---------|
| `LLM_API_URL` | OpenAI-compatible base URL | `http://<your-llm-host>:4000/v1` |
| `LLM_API_KEY` | Gateway API key | `sk-...` (never hard-code it) |
| `LLM_MODEL` | Model alias at the gateway | `local-model` |

Tip: if you use a gateway like LiteLLM in front of your inference server, point everything at
the **gateway's stable alias**, not the raw model name — then you can swap the underlying model
without touching any config.

## The script

Install as `~/.local/bin/askllm` and `chmod +x` it:

```bash
#!/usr/bin/env bash
# Pipe stdin + an instruction to a local OpenAI-compatible LLM gateway — zero API cost.
# Usage: cat big.log | askllm "extract every ERROR and give a root-cause summary"
set -euo pipefail

if [[ -z "${LLM_API_KEY:-}" && -f "$HOME/.env" ]]; then
  set -a; source "$HOME/.env"; set +a
fi

: "${LLM_API_URL:=http://<your-llm-host>:4000/v1}"
: "${LLM_MODEL:=local-model}"
: "${LLM_API_KEY:?LLM_API_KEY not set (expected in ~/.env)}"

instruction="${1:?usage: askllm \"instruction\" < input}"
body="$(cat)"

jq -n --arg m "$LLM_MODEL" --arg s "$instruction" --arg u "$body" \
  '{model:$m,messages:[{role:"system",content:$s},{role:"user",content:$u}],temperature:0.2,stream:false}' \
| curl -sS --max-time 300 "$LLM_API_URL/chat/completions" \
    -H "Authorization: Bearer $LLM_API_KEY" \
    -H 'Content-Type: application/json' -d @- \
| jq -r 'if .choices then .choices[0].message.content else "askllm error: " + (.|tojson) end'
```

Requires `jq` and `curl`. Replace the `LLM_API_URL` default with your gateway's address (or
just set the env var and leave the default as documentation).

## Usage

```bash
cat huge-build.log | askllm "extract every ERROR with a one-line root cause each"
cat api-response.json | askllm "list all endpoints that returned non-200, with counts"
cat scraped-page.html | askllm "extract the changelog entries as a markdown list"
```

## What it's for — and not for

**Use it for:** bulk research distillation, giant-file/log summarization, mechanical text
transforms — anything where a mid-tier local model reading 100k tokens for free beats a
frontier model reading them for money.

**Never use it for:** decisions, writing code, or anything needing current knowledge. The local
model is a text-compressor in this system, not a reasoner. Agents delegate *reading*, never
*judgment*.

**Failure mode:** if the gateway is down the call just fails — the calling agent falls back to
the `distiller` subagent (haiku). No retry logic needed; it's a best-effort cost optimization.
