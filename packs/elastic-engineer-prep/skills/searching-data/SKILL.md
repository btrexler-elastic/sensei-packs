---
description: "Use when the user asks for search query construction, bool filters, async search, aggregations, cross-cluster search, or runtime-field search behavior."
allowed-tools: eep-setup-search-lab-tool,eep-grade-search-query-tool,eep-run-search-exercises-tool
---

# Searching Data

Syllabus objectives this skill covers:
- Write and execute a search query for terms and/or phrases in one or more fields
- Boolean combinations of multiple queries and filters
- Asynchronous search
- Metric and bucket aggregations, with sub-aggregations
- Cross-cluster search
- Search using runtime fields

## Beat 1 — Explain

In 3-4 sentences:

> ES|QL is the primary search interface in modern Elasticsearch — pipelines of `WHERE`, `STATS`, `SORT`, `MATCH`. Underneath it still translates to the classic search/aggs/filters model, so understanding both surfaces matters for the exam. Aggregations let you bucket and roll up data without returning hits. Runtime fields let you derive a field at query time without reindexing.

Close with: *"Want me to set up a small search lab so we can grade some queries?"*

## Beat 2 — Setup

Call **`eep-setup-search-lab-tool`** with no parameters. It creates `eep-search-lab-demo` with strict mappings, a custom english analyzer on `title`, and 5 seed docs.

After setup, ask the learner to run this canonical in Discover ES|QL and report back:

```esql
FROM eep-search-lab-demo
| WHERE published == true
| WHERE category == "search"
| MATCH(title, "query")
| SORT points DESC
| KEEP title, points
```

This returns 1 row.

## Beat 3 — Grade canonical

When they confirm seeing the row, call **`eep-grade-search-query-tool`** with `mode=canonical`.

If `passed=true`: confirm in one sentence and give the challenge.
If `passed=false`: narrate the hint from `hints_json`.

## Beat 4 — Grade challenge

Give the challenge verbatim:

> Drop the MATCH and category filters from the canonical. Add a WHERE clause that returns ALL published documents at `beginner` difficulty, sorted by points DESC, KEEPing only title and points. You should see 2 rows.

When they paste their query, call `eep-grade-search-query-tool` with `mode=challenge` and `user_query=<their query>`.

The grader checks: 2 rows returned, columns are `title` then `points`. Hints will name the specific failure.

After three failed attempts you may share the working answer:

```esql
FROM eep-search-lab-demo
| WHERE published == true
| WHERE difficulty == "beginner"
| SORT points DESC
| KEEP title, points
```

## Optional: aggregations / runtime / async

Once the canonical/challenge is passed, offer a worked example via **`eep-run-search-exercises-tool`**:

- `mode=aggregations` runs a `terms by category` bucket with `avg(points)` sub-metric and verifies buckets came back.
- `mode=runtime_field` runs a `runtime_mappings` query that emits a `point_band` keyword and verifies hits.
- `mode=async_search` submits an async search and verifies an id was returned.

Frame these as worked examples to study, not graded drills — they prove the API patterns work against the lab.

## Hard rules

- Do not paste raw workflow JSON to the user.
- Do not reveal the challenge answer before two failed attempts.
- Keep responses tight; one ES|QL block per turn is plenty.
