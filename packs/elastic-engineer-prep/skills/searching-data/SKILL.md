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

> Lab is ready. Open **Dev Tools Console** and start with this base query — it runs but it's incomplete:
>
> ```
> GET eep-search-lab-demo/_search
> {
>   "query": {
>     "bool": {
>       "must": [ { "match": { "title": "query" } } ]
>     }
>   }
> }
> ```
>
> Three changes before you run it:
> 1. Add a `filter` array with two `term` clauses: `published: true` and `category: "search"`.
> 2. Add `sort` by `points` descending.
> 3. Add `_source` projecting only `title` and `points`.
>
> Run **your modified query** in Console, then paste it back here in the agent console (not the response).

When they paste their query, check:

- `filter` is a sibling of `must` inside `bool`, with both term clauses (not stuffed into `must`).
- `sort` is `[ { "points": "desc" } ]`.
- `_source` is `[ "title", "points" ]`.

Call out any missing pieces. Then call **`eep-grade-search-query-tool`** with `mode: canonical` to verify the lab is healthy and the reference search returns the expected hit.

- If `passed: true`: confirm — "1 hit: 'Optimize bool query relevance tuning', 35 pts. The `match` on an English-analyzed field matched 'query' via porter stemming ('querying' → 'queri'). `filter` clauses don't affect the score — they just restrict."
- If `passed: false`: check `hints_json` and report the hint. Most likely the index wasn't set up — ask them to re-run setup.

---

## Beat 3 — Challenge

Say:

> Goal: return **only published, beginner-difficulty docs**, sorted by `points` descending, keeping just `title` and `points`.
>
> Start with this base — it's wrong on purpose. Find the issues and fix it before running:
>
> ```
> GET eep-search-lab-demo/_search
> {
>   "query": {
>     "bool": {
>       "must": [
>         { "match": { "difficulty": "beginner" } }
>       ]
>     }
>   },
>   "sort":    [ { "points": "asc" } ],
>   "_source": [ "title" ]
> }
> ```
>
> Run **your fixed query** in Console, then paste it back here in the agent console.

The correct answer uses a `term` filter on `difficulty`, not a `match` in `must`:

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

When they paste their query, inspect it against the base:

- `difficulty` clause should be moved into `filter` and switched from `match` to `term` — `difficulty` is a keyword, exact-match, no scoring needed.
- `published: true` clause should be added (also as a `term` in `filter`).
- `sort` should be flipped from `asc` to `desc`.
- `_source` should be expanded from `[ "title" ]` to `[ "title", "points" ]`.

Call out anything they missed before grading. Then call **`eep-grade-search-query-tool`** with `mode: challenge` — this runs the reference challenge query against the index to confirm the lab is set up correctly.

- `passed: true, hits_count: 2, first_points: 20` → the lab is healthy. If their query also matched the canonical shape, they got it. Explain: using `filter` instead of `must` means no relevance score is computed — correct for exact-value matching on a keyword field.
- `passed: false, hits_count != 2` → lab issue, ask them to re-run setup. Separately, if their query used `must` with `match` on a keyword field or filtered on the wrong field, point that out.
- `passed: false, first_points != 20` → lab issue. Re-run setup.

---

## Beat 4 — Reference exercises (inline, no grade tool)

Work through these one at a time based on what the learner asks about next. Each one gives them a **base query that needs editing** before it'll do the right thing — no copy-paste-and-run. Ask them to make the listed changes in Console, run it, then paste **their modified query** back here. Review it against the reference shape and call out any deviations.

### Aggregations

Base query (buckets only, no metric):

```
GET eep-search-lab-demo/_search
{
  "size": 0,
  "aggs": {
    "by_category": {
      "terms": { "field": "category" }
    }
  }
}
```

Tell them: add a sub-aggregation called `avg_points` that computes the average of the `points` field, nested inside the `by_category` bucket.

Their fixed query should add an `aggs` block under `by_category` with `"avg_points": { "avg": { "field": "points" } }`. Their Console response should then show `aggregations.by_category.buckets` with 3 entries (search, ingest, mappings), each with an `avg_points.value`. Explain: `size: 0` skips hits since we only want agg results; the sub-agg runs once per bucket.

### Async search

Base query (synchronous):

```
GET eep-search-lab-demo/_search
{
  "query": { "match_all": {} }
}
```

Tell them: convert this to an **async** search and then poll the result.
- Change the method/path from `GET …/_search` to `POST …/_async_search`.
- Run it. The response has an `id`.
- Then run `GET /_async_search/<id>` to poll.

Their fixed initial request should target `_async_search`. The poll response should have `is_running: false` and `response.hits.total.value: 5` when complete.

### Runtime field

Base query — the script always emits `'low'`, so no docs match:

```
GET eep-search-lab-demo/_search
{
  "runtime_mappings": {
    "points_tier": {
      "type":   "keyword",
      "script": "emit('low')"
    }
  },
  "query":   { "term": { "points_tier": "high" } },
  "fields":  [ "title", "points_tier" ],
  "_source": false
}
```

Tell them: replace the `script` body so it emits `'high'` when `doc['points'].value >= 30`, otherwise `'low'`.

The reference fix:

```
"script": "emit(doc['points'].value >= 30 ? 'high' : 'low')"
```

Their Console response should then show hits with `fields.points_tier: ["high"]` and `points >= 30`. Explain: the runtime field exists only for this request — nothing is written to the index.

### Cross-cluster search (reference only — requires a registered remote)

Base query (single local cluster):

```
GET eep-search-lab-demo/_search
{
  "query": { "match_all": {} }
}
```

Tell them: rewrite the index path so it searches the same index on a remote cluster aliased `cluster_two` **and** the local copy in one request. They don't need to actually run it — there's no registered remote in the lab — just write what the path would look like.

Reference fix:

```
GET cluster_two:eep-search-lab-demo,eep-search-lab-demo/_search
```

Walk through what each part means: `cluster_two:` is the remote alias registered via `PUT /_cluster/settings`. The local index comes after the comma with no prefix.

---

## Hard rules

- All queries go in **Dev Tools Console** — never Discover or ES|QL.
- Always present a **base query that requires modification** — never a finished query the learner can copy-paste-and-run. The point is to force them to read, edit, and reason about each clause.
- The learner pastes **their modified query** (not the response) back into the agent console. Review the diff between base and what they pasted; call out anything they missed.
- Call the grade tool after **every** exercise that has a graded mode; don't skip it.
- Do not paste raw workflow JSON to the user.
- One query block per turn is enough — don't front-load all patterns.
