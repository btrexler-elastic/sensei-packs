---
description: "Use when the user asks about index design, dynamic templates, ILM for time-series data, index templates, or data streams."
allowed-tools: eep-setup-data-management-lab-tool,eep-check-data-management-lab-tool
---

# Data Management

Syllabus objectives this skill covers:
- Define an index that satisfies a given set of requirements
- Define and use a dynamic template that satisfies a given set of requirements
- Define an Index Lifecycle Management policy for a time-series index
- Define an index template that creates a new data stream

## Beat 1 — Explain

In 3-4 sentences:

> Data Management is about deciding how data lives over time. Index templates declare structure for matching index patterns. Data streams give you append-only logs with automatic backing-index rollover. ILM policies say when an index rolls, freezes, or deletes. A dynamic template lets you describe the shape of fields you don't know about yet.

Close with: *"Want me to set up a working ILM + data-stream lab so we can verify the moving parts together?"*

## Beat 2 — Setup

When they say yes, call **`eep-setup-data-management-lab-tool`** with no parameters.

It creates: ILM policy `eep-tsds-demo` (rollover at 20gb or 7d, delete at 30d), index template `eep-logs-template-demo` with `data_stream:{}` and a `string → text+keyword` dynamic template, the data stream `eep-logs-demo`, and 3 seed docs. The output returns the names back to you.

After the tool call, say:

> The lab is up: ILM `eep-tsds-demo`, template `eep-logs-template-demo`, data stream `eep-logs-demo` with 3 docs. Run this in Console to inspect the structure:
>
> ```
> GET /_index_template/eep-logs-template-demo
> GET /_data_stream/eep-logs-demo
> GET /_ilm/policy/eep-tsds-demo
> ```
>
> Tell me when you've reviewed each — I'll run a structural check next.

## Beat 3 — Check canonical setup

Call **`eep-check-data-management-lab-tool`**. It verifies all three resources exist.

If `passed=true`: confirm in one sentence and offer the challenge.

If `passed=false`: read `hints_json` and narrate the missing piece.

## Beat 4 — Challenge

Give the learner this prompt verbatim:

> In Console, add a second dynamic template to `eep-logs-template-demo` that maps any field whose name ends in `_count` to type `long`. Apply it with PUT, then re-run the check tool.

Hint pattern (only after a failed first attempt): "Use `match_pattern: regex` or the `match: '*_count'` shortcut and `mapping: { type: long }`."

After they update the template, call `eep-check-data-management-lab-tool` again. The check tool only verifies the resource still exists — encourage the learner to also run `GET /_index_template/eep-logs-template-demo` and inspect that their dynamic template is present.

## Hard rules

- Do not paste raw workflow JSON to the user.
- Do not reveal the working dynamic template before two failed attempts.
- Keep replies under 4 sentences except when presenting Console snippets.
