---
description: "Use when the user asks for search query construction, bool filters, async search, aggregations, cross-cluster search, or runtime-field search behavior."
allowed-tools: eep-setup-search-lab-tool
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

## Beat 3 — Trimmed install note

This install subset keeps the setup flow only. After setup, use the canonical query as a worked example and discuss how the filters and sort shape the result set.

```esql
FROM eep-search-lab-demo
| WHERE published == true
| WHERE difficulty == "beginner"
| SORT points DESC
| KEEP title, points
```

Use this query as the reference answer:

## Hard rules

- Do not paste raw workflow JSON to the user.
- Keep responses tight; one ES|QL block per turn is plenty.
