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

> Data processing is the _transform layer_: reshape raw docs at index time (ingest pipeline), at copy time (reindex), or at query time (runtime field). Multi-fields let one source field be analyzed in multiple ways — `title` as full-text `text` and also as a sortable `keyword` — without duplicating storage. Painless is the scripting language for both ingest processors and runtime fields. The exam pattern: build a pipeline, attach it to a reindex, then verify the target index carries the derived fields.

Close with: _"Want me to set up a source-and-target lab so we can run a pipeline and reindex together in Dev Tools?"_

## Beat 2 — Setup

Call **`eep-setup-data-processing-lab-tool`** with no parameters.

It creates: `eep-dp-source-demo` with 4 raw docs, ingest pipeline `eep-enrich-demo` (uppercase processor: `author` → `author_upper`), `eep-dp-target-demo` with the enriched mapping, and runs a `_reindex` from source to target through the pipeline.

After setup, ask the learner to run this canonical in **Dev Tools Console**:

```
GET eep-dp-target-demo/_search
{
  "query":   { "exists": { "field": "author_upper" } },
  "_source": [ "author", "author_upper" ],
  "size":    10
}
```

Expected: **4 hits**, all with `author_upper` populated (uppercase of `author`). Ask them to paste the response.

When they paste it, verify `hits.total.value == 4` and that every hit has a non-null `author_upper`.

## Beat 3 — Challenge

Give the learner this challenge:

> Write a query against `eep-dp-target-demo` that uses a **bucket aggregation** to group docs by `author_upper` and return the count per author. Paste your query and the result.

Expected: **4 buckets**, one per unique author. Each bucket should show `key` (the uppercase author name) and `doc_count: 1`.

```
GET eep-dp-target-demo/_search
{
  "size": 0,
  "aggs": {
    "by_author": {
      "terms": { "field": "author_upper" }
    }
  }
}
```

When they paste it, verify `aggregations.by_author.buckets.length == 4`.

If wrong, hint at using `"field": "author_upper"` (keyword type) not `"author"` (text type, not aggregatable by default).

## Concept reinforcement — Console reference

```
GET /_ingest/pipeline/eep-enrich-demo

POST /_ingest/pipeline/eep-enrich-demo/_simulate
{ "docs": [{ "_source": { "title": "x", "author": "new", "score": 1 } }] }

POST /eep-dp-target-demo/_update_by_query
{ "script": { "source": "ctx._source.score += 10" } }
```

For runtime fields with Painless, point them to the Searching Data skill's `runtime_mappings` worked example.

## Hard rules

- All queries go in **Dev Tools Console**, not Discover or ES|QL.
- Do not paste raw workflow JSON to the user.
- Reinforce the pipeline → reindex → query verification loop as one coherent flow.
