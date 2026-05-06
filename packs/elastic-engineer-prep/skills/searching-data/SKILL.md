---
description: "Use when the user asks about search queries, bool filters, aggregations, async search, runtime fields, or cross-cluster search."
allowed-tools: eep-setup-search-lab-tool, eep-grade-search-query-tool
---

# Searching Data

Exam objectives this skill covers:

- Write and execute a search query for terms and/or phrases in one or more fields
- Boolean combinations of queries and filters
- Asynchronous search
- Metric and bucket aggregations, with sub-aggregations
- Cross-cluster search
- Search using runtime fields

---

## Beat 1 — Explain

Give a 2-sentence summary of each cluster, then ask if they want to set up a lab:

**Query DSL and bool logic**
> All searches are JSON sent to `_search`. The `bool` query composes four clauses: `must` (scored full-text), `filter` (exact, cached, no scoring), `should` (boost), `must_not` (exclude). Prefer `filter` over `must` for exact values — it's faster and uses the bitset cache.

**Aggregations**
> Aggs run in parallel with the query on the same shard data. `terms` buckets by value, `date_histogram` buckets by time, `avg`/`sum`/`max` are metrics. Nest a metric agg inside a bucket agg to get "average score per category".

**Async search**
> Submit long queries with `POST index/_async_search`. You get an `id` immediately. Poll with `GET /_async_search/<id>` — the response has `is_partial` and `is_running` flags. Delete with `DELETE /_async_search/<id>` when done.

**Runtime fields**
> Add `"runtime_mappings"` to any search request to define a Painless-computed field that never touches the index. Emit with `emit(value)`. Reference it in `fields`, `sort`, or `aggs` just like a real mapped field.

**Cross-cluster search**
> Prefix the index with `cluster_alias:` — e.g., `GET cluster_two:logs-*,local-logs-*/_search`. The remote cluster must be registered in `cluster.remote` settings first.

Close with: _"Want me to set up a search lab index so you can practice these in Dev Tools Console?"_

---

## Beat 2 — Setup and canonical exercise

Call **`eep-setup-search-lab-tool`** with no parameters.

It creates `eep-search-lab-demo` with:
- A custom `title_english` analyzer (standard tokenizer + lowercase + porter_stem)
- Strict mappings: `title` (text, analyzed), `category` (keyword), `difficulty` (keyword), `points` (integer), `published` (boolean)
- 5 seed docs across search/ingest/mappings categories, beginner/intermediate/advanced difficulty

After the tool returns, tell the learner:

> Lab is ready. Open **Dev Tools Console** and run the canonical query:
>
> ```
> GET eep-search-lab-demo/_search
> {
>   "query": {
>     "bool": {
>       "must":   [ { "match": { "title": "query" } } ],
>       "filter": [
>         { "term": { "published": true } },
>         { "term": { "category": "search" } }
>       ]
>     }
>   },
>   "sort":    [ { "points": "desc" } ],
>   "_source": [ "title", "points" ]
> }
> ```
>
> Paste the full response when you have it.

When they paste it, call **`eep-grade-search-query-tool`** with `mode: canonical`.

- If `passed: true`: confirm — "1 hit: 'Optimize bool query relevance tuning', 35 pts. The `match` on an English-analyzed field matched 'query' via porter stemming ('querying' → 'queri'). `filter` clauses don't affect the score — they just restrict."
- If `passed: false`: check `hints_json` and report the hint. Most likely the index wasn't set up — ask them to re-run setup.

---

## Beat 3 — Challenge

Say:

> Now write your own query. Return **only the beginner-difficulty docs**, sorted by `points` descending, keeping just `title` and `points`. Run it in Console and paste the result.

The correct answer uses a `term` filter on `difficulty`, not `must`:

```
GET eep-search-lab-demo/_search
{
  "query": {
    "bool": {
      "filter": [
        { "term": { "difficulty": "beginner" } },
        { "term": { "published": true } }
      ]
    }
  },
  "sort":    [ { "points": "desc" } ],
  "_source": [ "title", "points" ]
}
```

Expected: 2 hits — "Configure text analysis for product search" (20 pts), then "Compare term versus match behavior" (15 pts).

When they share their result, call **`eep-grade-search-query-tool`** with `mode: challenge`.

- `passed: true, hits_count: 2, first_points: 20` → they got it. Explain: using `filter` instead of `must` means no relevance score is computed — correct for exact-value matching on a keyword field.
- `passed: false, hits_count != 2` → use the hint. Likely using `must` with a `match` on a keyword field, or filtering on the wrong field name.
- `passed: false, first_points != 20` → sort is wrong. They have the right docs but ascending order.

---

## Beat 4 — Reference exercises (inline, no grade tool)

Work through these one at a time based on what the learner asks about next. Ask them to run each in Console and paste the response; verify the key fields inline.

### Aggregations

```
GET eep-search-lab-demo/_search
{
  "size": 0,
  "aggs": {
    "by_category": {
      "terms": { "field": "category" },
      "aggs": {
        "avg_points": { "avg": { "field": "points" } }
      }
    }
  }
}
```

Verify: `aggregations.by_category.buckets` has 3 entries (search, ingest, mappings). Each bucket has `avg_points.value`. Explain: `size: 0` skips hits since we only want agg results.

### Async search

```
POST eep-search-lab-demo/_async_search
{
  "query": { "match_all": {} }
}
```

Then poll: `GET /_async_search/<id from response>`

Verify the initial response has an `id` field. The poll response has `is_running: false` and `response.hits.total.value: 5` when complete.

### Runtime field

```
GET eep-search-lab-demo/_search
{
  "runtime_mappings": {
    "points_tier": {
      "type":   "keyword",
      "script": "emit(doc['points'].value >= 30 ? 'high' : 'low')"
    }
  },
  "query":   { "term": { "points_tier": "high" } },
  "fields":  [ "title", "points_tier" ],
  "_source": false
}
```

Verify: hits have `fields.points_tier: ["high"]` and `points >= 30`. Explain: the runtime field exists only for this request — nothing is written to the index.

### Cross-cluster search (reference only — requires a registered remote)

```
GET cluster_two:eep-search-lab-demo,eep-search-lab-demo/_search
{
  "query": { "match_all": {} }
}
```

No live lab for CCS. Walk through what each part means: `cluster_two:` is the remote alias registered via `PUT /_cluster/settings`. The local index comes after the comma with no prefix.

---

## Hard rules

- All queries go in **Dev Tools Console** — never Discover or ES|QL.
- Call the grade tool after **every** exercise that has a graded mode; don't skip it.
- Do not paste raw workflow JSON to the user.
- One query block per turn is enough — don't front-load all patterns.
