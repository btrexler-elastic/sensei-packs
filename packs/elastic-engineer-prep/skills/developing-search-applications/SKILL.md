---
description: "Use when the user asks about sorting, pagination patterns, or index aliases in search applications."
allowed-tools: eep-setup-search-app-lab-tool
---

# Developing Search Applications

Syllabus objectives this skill covers:
- Sort the results of a query by a given set of requirements
- Implement pagination of the results of a search query
- Define and use index aliases

## Beat 1 — Explain

In 3-4 sentences:

> Search apps query *aliases*, never raw indices, so you can swap the underlying index without app changes. Sort needs deterministic tie-breakers — usually a unique field like `_id` or a timestamp. Pagination on small data uses `from/size`; deep pagination uses `search_after` plus a Point in Time (PIT). ES|QL exposes the same shape via `SORT … LIMIT N`, but search_after itself is a DSL feature.

Close with: *"Want me to set up a small versioned-index lab with an alias so you can practice sort + limit?"*

## Beat 2 — Setup

Call **`eep-setup-search-app-lab-tool`** with no parameters.

It creates index `eep-app-demo-v1`, alias `eep-app-demo` pointing to it as a write index, and 6 seed docs (Alpha…Foxtrot, scores 90 down to 40).

After setup, ask the learner to run this canonical in Discover ES|QL:

```esql
FROM eep-app-demo
| SORT score DESC, title ASC
| LIMIT 3
| KEEP title, score
```

Returns 3 rows: Alpha, Bravo, Charlie.

## Beat 3 — Trimmed install note

This install subset keeps the setup flow only. After setup, discuss sort stability, pagination, and alias swapping as a manual exercise.

```esql
FROM eep-app-demo
| SORT score ASC, title DESC
| LIMIT 2
| KEEP title, score
```

## Concept reinforcement

After the exercise, walk the learner through a blue/green index swap pattern in Console:

```
POST /_aliases
{
  "actions": [
    { "remove": { "index": "eep-app-demo-v1", "alias": "eep-app-demo" } },
    { "add":    { "index": "eep-app-demo-v2", "alias": "eep-app-demo", "is_write_index": true } }
  ]
}
```

Mention `search_after` + PIT for deep pagination — the DSL pattern, not ES|QL.

## Hard rules

- Do not paste raw workflow JSON to the user.
- Use `eep-app-demo` (the alias), not the underlying versioned index, in examples.
