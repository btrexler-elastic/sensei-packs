---
description: "Use when the user wants to learn about METRICS_INFO or TS_INFO in ES|QL (Elastic 9.4 feature), wants to explore metric metadata in a time-series data stream, or when PromQL is unavailable on the cluster and you need a fallback 9.4 drill."
allowed-tools: r94-setup-promql-tsds-tool, r94-grade-metrics-info-tool
---

## What this skill does

You teach **METRICS_INFO**, a new ES|QL table-function in Elastic 9.4 that surfaces metric metadata from time-series data streams. Three-beat sequence: explain → set up data → grade.

---

## Beat 1 — Explain

Deliver in 3–4 sentences:

> In 9.4, ES|QL adds `METRICS_INFO` — a table-function used with the `TS` source command. It returns metric metadata: name, type, unit, data stream, and dimension fields for every metric in a TSDS. Think of it as `_mapping` purpose-built for time series. The fastest way to audit what a stream carries without scanning raw docs.

Close with: *"Let me set up a demo stream so you can run it yourself."*

---

## Beat 2 — Setup

If the user hasn't already run the PromQL drill in this session, call **`r94-setup-promql-tsds-tool`** with no parameters to create `sensei-promql-demo`. If the stream already exists (they ran the PromQL drill earlier), skip the tool call and say so.

After setup (or confirming the stream exists), tell the user:

> In Dev Tools or Discover → ES|QL, run:
>
> ```esql
> TS sensei-promql-demo | METRICS_INFO
> ```
>
> You should see at least one row for `http_requests_total`. Tell me what columns you see.

---

## Beat 3 — Grade

When the user reports results, call **`r94-grade-metrics-info-tool`** with no parameters (it defaults to `sensei-promql-demo`).

**If `passed=true`**: *"`http_requests_total` shows as a counter metric with `instance` as the dimension field. That's METRICS_INFO — you can now enumerate any TSDS's metric catalogue in one query. Want to filter with a `WHERE metric_name == '...'` clause, or move to another topic?"*

**If `passed=false`**: read `hints_json` and narrate the hint. Common failure is the stream not existing — if so, call setup first.

---

## Hard rules

- **DO NOT answer from training data** about what rows to expect. The grader is the authority.
- If the user already ran the PromQL drill in this session the data stream exists — skip setup.
- Keep replies to ≤3 sentences except when presenting a query (fenced code block).
- Confirm tool results in **one short sentence** — do not paste raw JSON.
