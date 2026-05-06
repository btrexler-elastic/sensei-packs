---
description: "Use when the user asks about mappings, multi-fields, reindex/update-by-query, ingest pipelines, or runtime fields with Painless."
allowed-tools: eep-setup-data-processing-lab-tool,eep-grade-data-processing-tool
---

# Data Processing

Syllabus objectives this skill covers:
- Define a mapping that satisfies a given set of requirements
- Multi-fields with different data types and/or analyzers
- Reindex API and Update By Query API
- Ingest pipelines
- Runtime fields with Painless

## Beat 1 — Explain

In 3-4 sentences:

> Data processing is the *transform layer*: take raw incoming docs and reshape them at index time (ingest pipeline), at copy time (reindex), or at query time (runtime field). Multi-fields let one source field be analyzed multiple ways without duplicating storage. Painless is the safe scripting language used in ingest pipelines and runtime fields. The exam-relevant pattern: build a pipeline, attach it to a reindex, verify the target carries the derived fields.

Close with: *"Want me to set up a source-and-target lab so we can run a pipeline + reindex together?"*

## Beat 2 — Setup

Call **`eep-setup-data-processing-lab-tool`** with no parameters.

It creates: `eep-dp-source-demo` with 4 raw docs, ingest pipeline `eep-enrich-demo` (uppercase processor on `author` → `author_upper`), `eep-dp-target-demo` with the enriched mapping, and runs a `_reindex` from source to target through the pipeline.

After setup, ask the learner to run this canonical in Discover ES|QL:

```esql
FROM eep-dp-target-demo
| WHERE author_upper IS NOT NULL
| STATS c = COUNT(*)
```

Returns 1 row with c = 4.

## Beat 3 — Grade canonical

Call **`eep-grade-data-processing-tool`** with `mode=canonical`.

If `passed=true`: confirm and give the challenge.
If `passed=false`: narrate `hints_json`.

## Beat 4 — Grade challenge

Give the challenge verbatim:

> Modify the canonical to GROUP BY author_upper. Use STATS c = COUNT(*) BY author_upper, KEEP author_upper, c. You should see 4 rows (one per author).

When they paste, call `eep-grade-data-processing-tool` with `mode=challenge` and `user_query=<their query>`.

Grader checks: 4 rows, columns `author_upper` then `c`.

After three failed attempts, share the working answer:

```esql
FROM eep-dp-target-demo
| STATS c = COUNT(*) BY author_upper
| KEEP author_upper, c
```

## Concept reinforcement

After the challenge, walk through related patterns in Console:

```
GET /_ingest/pipeline/eep-enrich-demo
POST /_ingest/pipeline/eep-enrich-demo/_simulate
{ "docs": [{ "_source": { "title":"x", "author":"new", "score":1 } }] }

POST /eep-dp-target-demo/_update_by_query
{ "script": { "source": "ctx._source.score += 10" } }
```

For runtime fields with Painless, point them to the Searching Data skill's `runtime_field` worked example.

## Hard rules

- Do not paste raw workflow JSON to the user.
- Do not reveal the working answer before two failed attempts.
- Reinforce the pipeline → reindex → query loop as one coherent flow.
