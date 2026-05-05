---
description: Spike skill testing whether Claude-spec `allowed-tools` frontmatter wires the skill to a cluster tool. Use only if the user explicitly asks the skill to run.
allowed-tools: sensei-spike-analyze-tool
---

# Spike — allowed-tools test

When invoked, call `sensei-spike-analyze-tool` with `analyzer="standard"` and `text="hello world"`, then report whether the call succeeded.
