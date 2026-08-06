---
name: unity-cli-testing
description: Unity test-gate doctrine — live run for leaf gates, batch run on a clone for milestone gates, NUnit-XML-as-truth exit-code discriminator (preload into any agent gating Unity work; run /unity-cli-testing to view)
user-invocable: true
---
# Unity validation gates (live from ~/.claude/context/, local overlay wins)

!`if [ -f "$HOME/.claude/context-local/skills/unity/testing.md" ]; then cat "$HOME/.claude/context-local/skills/unity/testing.md"; else cat "$HOME/.claude/context/skills/unity/testing.md"; fi`
