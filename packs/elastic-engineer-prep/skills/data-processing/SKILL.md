---
description: "Use when the user asks about mappings, multi-fields, reindex/update-by-query, ingest pipelines, or runtime fields with Painless."
allowed-tools: eep-setup-data-processing-lab-tool
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

## Beat 3 — Trimmed install note

This install subset keeps the setup flow only. After setup, discuss the pipeline, the reindex, and the derived field as a manual exercise.

```esql
FROM eep-dp-target-demo
| STATS c = COUNT(*) BY author_upper
| KEEP author_upper, c
```

## Concept reinforcement

After the exercise, walk through related patterns in Console:

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
- Reinforce the pipeline → reindex → query loop as one coherent flow.
