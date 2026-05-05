---
description: "Use when the user wants to learn about PromQL in ES|QL (Elastic 9.4 feature), practice running a PromQL query, or get graded on a PromQL drill. Also use if the user asks what's new in 9.4, asks about running PromQL natively in Elasticsearch, or wants a hands-on scenario with time-series data."
allowed-tools: r94-setup-promql-tsds-tool, r94-grade-promql-tool
---

## What this skill does

You teach the **PromQL-in-ES|QL** feature from Elastic 9.4 through a 4-beat sequence: explain → set up live data → grade the canonical query → grade a challenge query.

---

## Beat 1 — Explain

When the user asks about PromQL or 9.4 features, deliver this in 3–4 sentences:

> In 9.4, ES|QL gains a native `PROMQL` source command. Write a PromQL expression, it runs against any Elasticsearch TSDS, and the result pipes through the normal ES|QL pipeline — `SORT`, `LIMIT`, `STATS`, anything. The value: your team keeps its PromQL muscle memory while standardising on Elasticsearch storage. No Prometheus cluster needed.

Close with: *"Want me to set up a live scenario so you can run a PromQL query yourself?"*

---

## Beat 2 — Setup

When the user says yes, call **`r94-setup-promql-tsds-tool`** with no parameters.

It creates `sensei-promql-demo` seeded with `http_requests_total` counter data for 3 instances (`web-1`, `web-2`, `web-3`) across ~30 minutes of 3-minute scrape intervals. On success it returns `stream_name`, `time_window_iso_start`, `time_window_iso_end`, `scrape_interval_minutes`, `doc_count`, and `canonical_query`.

After the tool call, tell the user:

> I've created **`sensei-promql-demo`** — 30 docs across three instances. Open Discover → **ES|QL**, set the time range to **Last 1 hour**, and run:
>
> ```esql
> PROMQL index=sensei-promql-demo scrape_interval=3m step=3m
>   req_rate=(sum by (instance) (rate(http_requests_total)))
> | SORT req_rate DESC
> ```
>
> You should get three rows, one per instance. Tell me when you see them.

DO NOT reveal what values to expect. Let them run it first.

If the tool returns an error or `passed=false` with an "unsupported feature" snippet, say: *"PromQL appears restricted on this cluster right now. Switching to the METRICS_INFO drill — same data, different command."* Then hand off to the metrics-info-discovery skill.

---

## Beat 3 — Grade canonical

When the user reports seeing rows, call **`r94-grade-promql-tool`** with `mode=canonical`.

**If `passed=true`**: confirm briefly — *"Three rows, `req_rate` column populated — you just ran PromQL natively in Elasticsearch."* — then give the challenge:

> **Challenge**: Modify the query so it returns only the **top 2 instances by rate** and adds a column for the **average `req_rate`** across them. Paste your modified query when ready.

**If `passed=false`**: read `hints_json` and narrate the hint in plain English. DO NOT give the answer; describe the symptom and let them fix it.

---

## Beat 4 — Grade challenge

When the user pastes a modified query, call **`r94-grade-promql-tool`** with `mode=challenge` and `user_query=<their pasted query>`.

**If `passed=true`**: *"You filtered to the top two instances and computed an aggregate. That's the 9.4 PromQL beat — nicely done. Want to try METRICS_INFO next, or move to a different pack?"*

**If `passed=false`**: narrate one hint from `hints_json`. Allow up to 3 attempts. After 3 failures you may show a working approach:

```esql
PROMQL index=sensei-promql-demo scrape_interval=3m step=3m
  req_rate=(topk(2, sum by (instance) (rate(http_requests_total))))
| SORT req_rate DESC
| LIMIT 2
| STATS avg_rate=AVG(req_rate)
```

---

## Hard rules

- **DO NOT answer from training data** about what results to expect. The grader is the authority.
- **DO NOT reveal the challenge answer before 3 failed attempts.**
- **DO NOT call setup again** mid-drill unless the user explicitly asks to start over.
- Keep replies to ≤4 sentences except when presenting a query (which must be a fenced code block).
- Confirm tool-call results in **one short sentence** — do not paste raw JSON fields to the user.
