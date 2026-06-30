---
description: "Use when the user asks about answering questions from a dataset, finding anomalies, Machine Learning jobs (single metric, multi-metric, population), scripted fields, or Kibana Spaces."
allowed-tools: eap-setup-analyst-lab-tool, eap-grade-analyzing-lab-tool
---

# Analyzing Data

Exam objectives this skill covers:

- Answer questions about a given dataset using search and visualizations
- Use visualizations to find anomalies in a dataset
- Define a single metric, multi-metric, or population Machine Learning job
- Define and use a scripted field for an index
- Define and use a Space in Kibana

---

## Beat 1 — Explain

Give a 2-sentence summary of each concept, then ask if they want to set up a lab:

**Answering questions from data**
> This objective isn't a separate tool — it's combining Discover, KQL, and visualizations you already know to answer a specific question like "which host sent the most traffic in the last hour." The exam will phrase tasks as questions; expect to build a quick visualization or run a query rather than being told exactly what panel type to make.

**Finding anomalies visually**
> Before reaching for Machine Learning, a line/bar chart with a fine-enough date histogram interval often reveals spikes or drops by eye. This is the cheap first pass; ML is for systematic, ongoing, or subtle detection.

**ML job types**
> **Single metric**: one function (mean, sum, count...) on one field, optionally split is not available — it's the simplest job. **Multi-metric**: same idea but with a `split field`, producing one model per partition value (e.g., per host). **Population**: detects which *members* of a population (e.g., which host) behave differently from their peers, rather than each member against its own history — the right choice when "is this host weird compared to the others" matters more than "is this host weird compared to itself yesterday."

**Scripted fields**
> Defined per data view in **Stack Management → Data Views → [view] → Scripted Fields**, written in Painless, computed at query time (not stored). Useful for unit conversions or derived flags without reindexing.

**Spaces**
> Spaces partition saved objects (dashboards, visualizations, data views) into separate working areas within one Kibana — useful for separating teams or environments. Created in **Stack Management → Spaces**; you switch spaces from the top-left space picker.

Close with: _"Want me to set up a lab so you can build a real ML job and a scripted field?"_

---

## Beat 2 — Setup and canonical exercise (single metric ML job)

If the lab isn't already set up, call **`eap-setup-analyst-lab-tool`**. Otherwise reuse `eap-analyst-lab-demo`.

> Go to **Machine Learning → Anomaly Detection Jobs → Create job**, select the `eap-analyst-lab-demo*` data view, use the **full time range** of the data, and create a **single metric** job:
> - Function: **Mean**
> - Field: `bytes`
> - Bucket span: **1m**
> - Job ID: anything starting with `eap-` (e.g. `eap-bytes-anomaly`)
>
> Create and **start** it (run over the full time range, don't bother with real-time for this lab). Tell me the job ID once it's running.

When they confirm, call **`eap-grade-analyzing-lab-tool`** with `mode: ml_job`, `job_id: "<their job id>*"` (pass it as a wildcard-friendly prefix, e.g. `eap-*`).

- `passed: true`: confirm — "Job found, detector function is `{{detector_function}}`. Once it finishes processing, check the Anomaly Explorer — the spike on `web-1`'s last bucket should register as a high-severity anomaly given it's roughly 20x the baseline `bytes` value. If you don't see it yet, the job may still be running over the time range — give it a few seconds and refresh."
- `passed: false`: report the hint — usually the job wasn't created yet, or its datafeed isn't pointed at the lab index.

---

## Beat 3 — Challenge (population job + scripted field)

Say:

> Two more tasks:
>
> **1. Population job.** Create a **population** ML job, function **Mean** on `response_time_ms`, **population field** `host.name`. This asks "which host's response times are unusual compared to the other hosts" rather than compared to its own history. Job ID starting with `eap-`. Start it.
>
> **2. Scripted field.** On the `eap-analyst-lab-demo*` data view, add a scripted field named **`bytes_kb`** that converts `bytes` to kilobytes. Painless: `doc['bytes'].value / 1024.0`. Save it, then confirm in Discover that the field appears and shows a value roughly 1/1024th of `bytes` for any document.

When they confirm the population job, call **`eap-grade-analyzing-lab-tool`** with `mode: ml_job`, `job_id: "eap-*"` — note this check confirms *a* job exists over the lab index but can't distinguish single-metric from population from the saved config alone; ask them to describe the population field they set and sanity-check it's `host.name` before treating it as correct.

When they confirm the scripted field, call **`eap-grade-analyzing-lab-tool`** with `mode: scripted_field`, `field_name: "bytes_kb"`.

- `passed: true`: confirm — "Scripted field confirmed on the data view. Quick sanity check: the `web-1` spike doc should show `bytes_kb` around 46.9 (48000 / 1024)."
- `passed: false`: report the hint — usually it wasn't saved, or the field name doesn't match exactly.

---

## Beat 4 — Reference exercises (inline, no grade tool)

Work through these as the learner asks; they exercise the "answer questions from data" objective directly and don't need a grading tool — review their stated answer against the dataset's known shape.

### Quick question 1

"Which host had the highest total `bytes` over the lab window, and roughly how much higher than the others?" Expected: `web-1`, due to the spike — its total should be on the order of 20x `web-2` or `web-3`'s totals. If they answer differently, ask them to walk through which query/visualization they used; likely the time range excluded the spike bucket.

### Quick question 2

"What's the overall error rate (500s + 404s as a fraction of all requests) across the lab window?" Expected: 2 errors out of ~30 docs, so roughly 6-7%. This is the same arithmetic the "Error Rate" TSVB filter ratio panel from Visualizing Data computes automatically — point that connection out if they built that panel earlier.

### Multi-metric job (conceptual, optional to actually build)

Ask them to describe — not necessarily build — a **multi-metric** job for "mean `response_time_ms`, split by `host.name`" and explain how its output differs from the population job above: multi-metric gives each host its own independent model judged against its own history, while population compares hosts against each other within the same model. If they want to build it, same flow as before with `mode: ml_job`.

### Spaces (conceptual — lab doesn't require a second space)

Walk through creating a new Space called e.g. `Analyst Lab`, and note that data views, dashboards, and saved searches built earlier in this lab won't appear there unless explicitly copied via **Stack Management → Saved Objects → Copy to space**. This is a common point of exam confusion: switching spaces doesn't move objects, it changes which objects are visible.

---

## Hard rules

- Don't conflate ML job types in explanations — single metric, multi-metric, and population each answer a different question; always name which one a task calls for.
- Job IDs and field names are matched loosely (prefix/wildcard) by the grading tool since IDs vary — confirm the learner's actual configuration choices in conversation rather than trusting `passed: true` alone for job *type* correctness.
- Scripted field names are matched exactly.
- Don't paste raw workflow JSON or `.ml-config`/`.kibana` source documents to the user — summarize in plain language.
- One exercise per turn.
