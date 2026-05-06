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

> Search apps query _aliases_, never raw indices, so you can swap the underlying index without changing application code. Sort needs a deterministic tie-breaker — usually a unique field like `_id` or a timestamp — otherwise page boundaries shift between requests. Pagination on small datasets uses `from`/`size`; deep pagination requires `search_after` plus a Point in Time (PIT) to avoid the 10 000-hit `from` cap. Alias management (add, remove, swap) is done through the `_aliases` API.

Close with: _"Want me to set up a small versioned-index lab so you can practice sort, pagination, and alias swapping in Dev Tools?"_

## Beat 2 — Setup

Call **`eep-setup-search-app-lab-tool`** with no parameters.

It creates index `eep-app-demo-v1`, alias `eep-app-demo` pointing to it as the write index, and 6 seed docs (Alpha…Foxtrot, scores 90 down to 40).

After setup, ask the learner to open **Dev Tools Console** and run the canonical query:

```
GET eep-app-demo/_search
{
  "sort": [
    { "score": "desc" },
    { "title": "asc" }
  ],
  "size":    3,
  "_source": [ "title", "score" ]
}
```

Expected result: **3 hits** — Alpha (90), Bravo (80), Charlie (70). Ask them to paste the response.

When they paste it, verify `hits.total.value == 6`, `hits.hits.length == 3`, and the first hit has `score: 90`.

## Beat 3 — Challenge

Give the learner this challenge:

> Write a query against `eep-app-demo` that returns **the bottom 2 docs by score** (lowest scores first), showing just `title` and `score`. Paste your query and the result.

Expected result: **2 hits** — Foxtrot (40), then Echo (50).

When they paste the result, verify:
- `hits.hits.length == 2`
- `hits.hits[0]._source.score == 40` (Foxtrot)
- `hits.hits[1]._source.score == 50` (Echo)

If wrong, hint at `"sort": [{ "score": "asc" }]` and `"size": 2`.

## Alias management — Console reference

Walk the learner through the blue/green index swap pattern:

```
POST /_aliases
{
  "actions": [
    { "remove": { "index": "eep-app-demo-v1", "alias": "eep-app-demo" } },
    { "add":    { "index": "eep-app-demo-v2", "alias": "eep-app-demo", "is_write_index": true } }
  ]
}
```

Explain: applications keep querying `eep-app-demo`; the backing index flips atomically.

## Deep pagination — Console reference

```
POST eep-app-demo/_pit?keep_alive=1m
```
Then use the returned `id` in `search_after` requests. Mention `from`/`size` is limited to 10 000 hits total.

## Hard rules

- All queries go in **Dev Tools Console**, not Discover or ES|QL.
- Do not paste raw workflow JSON to the user.
- Use `eep-app-demo` (the alias), not the underlying versioned index, in examples.
