---
description: "Use when the user asks about Lens, classic visualizations, TSVB, Maps, Data Tables, Tag Clouds, Markdown panels, controls, or building dashboards in Kibana."
allowed-tools: eap-setup-analyst-lab-tool, eap-grade-visualizing-lab-tool
---

# Visualizing Data

Exam objectives this skill covers:

- Create a Metric or Gauge visualization that displays a value satisfying a given criteria
- Create a Lens visualization that satisfies a given criteria
- Create an Area, Line, Pie, Vertical Bar, or Horizontal Bar visualization that satisfies a given criteria
- Split a visualization using sub-bucket aggregations
- Create a visualization that computes a moving average, derivative, or serial diff aggregation
- Customize the format and colors of a line chart or bar chart
- Using geo data, create an Elastic Map that satisfies a given criteria
- Create a Time Series Visual Builder (TSVB) visualization that satisfies a given set of criteria
- Define multiple line or bar charts on a single TSVB visualization
- Create a chart that displays a filter ratio, moving average, or mathematical computation of two fields
- Define a metric, gauge, table, or Top N visualization in TSVB
- Create a Tag Cloud visualization on a keyword field of an index
- Create a Data Table visualization that satisfies a given criteria
- Create a Markdown visualization
- Define and use an Options List or Range Slider control
- Create a Dashboard that consists of a collection of visualizations

---

## Beat 1 — Explain

Give a 2-sentence summary of each cluster, then ask if they want to set up a lab:

**Lens (the default builder)**
> Drag a field into the workspace, Lens suggests a chart type; switch chart types anytime without rebuilding. Buckets (X-axis/Break down by) come from terms, date histogram, or ranges; metrics (Y-axis) come from count/sum/avg/etc. This is what the exam expects for most "create a chart" objectives unless TSVB is named explicitly.

**Sub-buckets and pipeline aggregations**
> "Split series" / "Break down by" adds a second bucket dimension — e.g., bars by host, split further by response code. Moving average, derivative, and serial diff are pipeline aggs that operate on a date histogram's metric output; in Lens these appear as a function wrapping an existing metric ("Differences", "Moving average").

**TSVB**
> A separate panel type for time-series-specific needs Lens doesn't cover well: multiple unrelated metrics on one chart, filter ratios, raw Painless math between series, and non-time panel types (Top N, gauge, markdown-in-TSVB) sharing one config UI. Index pattern is typed as a string, not picked from a dropdown — that trips people up first time.

**Maps**
> Built from geo_point or geo_shape fields. Document layer plots individual points; choropleth needs a boundary join (e.g., by country code) plus a metric. Heat map layers cluster density visually rather than as discrete points.

**Tag Cloud, Data Table, Markdown**
> Tag Cloud needs a keyword (aggregatable) field — never plain text. Data Table is the "show me the raw aggregated numbers" visualization, good when a chart would lose precision. Markdown panels render static or templated text/links, often used for dashboard instructions or links.

**Controls**
> Options List = dropdown of distinct field values, multi-select. Range Slider = numeric bounds. Both filter every panel on the dashboard they're added to, without editing each visualization.

**Dashboards**
> A saved collection of panel references plus their layout — panels aren't duplicated, they're referenced, so editing the source visualization updates every dashboard using it.

Close with: _"Want me to set up a lab index so you can build some of these?"_

---

## Beat 2 — Setup and canonical exercise (Lens chart)

If the lab isn't already set up from the Searching Data skill, call **`eap-setup-analyst-lab-tool`**. Otherwise reuse the existing `eap-analyst-lab-demo` index and data view.

> Build this in **Lens**: a **vertical bar chart**, titled exactly **"Bytes by Host"**, with `host.name` (terms) on the X-axis and the **sum of `bytes`** on the Y-axis. Save it.

When they confirm, call **`eap-grade-visualizing-lab-tool`** with `mode: chart`, `title: "Bytes by Host"`.

- `passed: true`: confirm — "Saved. `web-1` should dominate that chart because of the planted spike — its sum of bytes is roughly 20x the other two hosts combined. That's the same anomaly we'll formally detect with an ML job later."
- `passed: false`: report the hint. Most likely cause is a title mismatch (titles are matched exactly) or the visualization wasn't saved.

---

## Beat 3 — Challenge (TSVB filter ratio)

Say:

> Build a **TSVB** time series panel titled **"Error Rate"**, with two series on one chart using **Filter Ratio**: numerator query `response_code: "500" or response_code: "404"`, denominator query `*` (all docs). Set the index pattern string to `eap-analyst-lab-demo*` and the time field to `@timestamp` (TSVB asks for these as text, not a data view picker). Save it.

When they confirm, call **`eap-grade-visualizing-lab-tool`** with `mode: tsvb`, `title: "Error Rate"`.

- `passed: true`: confirm — "Confirmed as a TSVB panel. With this dataset the ratio should spike to non-zero only in the two buckets containing the 500 and 404, sitting at 0 everywhere else — that's the shape a filter ratio panel is built to show: a 'how bad is it right now relative to total traffic' signal rather than a raw error count."
- `passed: false`: most likely they built it in Lens instead of TSVB (the check specifically looks for `visState.type == "metrics"`, TSVB's internal type name), or the title doesn't match.

---

## Beat 4 — Reference exercises (inline, no grade tool)

Work through these one at a time as the learner asks; review their description against the reference behavior rather than calling a grading tool (these are harder to fingerprint reliably from saved-object JSON alone).

### Metric + customized line chart

Ask for a **Metric** visualization showing the **average `response_time_ms`** across the whole lab window. Then ask them to build a **line chart** of `response_time_ms` average over time (date histogram on `@timestamp`), and customize: change the line color, and add a static **annotation or threshold customization** marking 1000ms. Confirm the average jumps because of the 500 error's inflated `response_time_ms` (2400ms) — a good moment to discuss how a single outlier skews an average versus a median/percentile metric.

### Sub-bucket split

Ask them to take the canonical "Bytes by Host" bar chart and add a **split series** by `response_code`. Expect each host's bar to mostly be one solid color (200) except `web-2`'s, which should show a sliver for 500 and 404.

### Moving average / derivative

Ask for a line chart of **sum of `bytes`** over time, date histogram on `@timestamp`, then add a **moving average** pipeline function wrapping that metric. With only 10 time buckets and one big spike at the end, the moving average should lag visibly behind the raw spike — a good talking point for why smoothing trades responsiveness for noise reduction.

### Data Table + Tag Cloud

Data Table: rows = `host.name` terms, columns = count and sum of `bytes`. Tag Cloud: built on `url.path` (it's mapped `keyword`, so this works directly) — sized by count, expect `/checkout`, `/home`, `/search` roughly even except for the 404's `/missing` path appearing small.

### Map (conceptual only — lab has no geo field)

Note the lab index doesn't include a geo_point field, so this is discussion-only: walk through how they'd add a `region_point: geo_point` field to a mapping and build a document layer map from it, since the actual exam will supply geo-enabled sample data.

### Dashboard + controls

Ask them to assemble a dashboard titled **"Lab Overview"** combining: "Bytes by Host", "Error Rate" (TSVB), the Data Table, and a Markdown panel with a one-line description. Then add an **Options List control** on `host.name` and confirm selecting a single host filters every panel.

When ready to confirm the dashboard exists, call **`eap-grade-visualizing-lab-tool`** with `mode: dashboard`, `title: "Lab Overview"`, `min_panels: "4"`.

- `passed: true`: confirm panel count matches what they intended.
- `passed: false`: report hint — usually a missing panel or title mismatch.

---

## Hard rules

- Visualization and dashboard titles are matched exactly (case-sensitive) — always state the precise title to use.
- Default to **Lens** unless an exercise explicitly calls for TSVB, classic visualize, or Maps — that mirrors what the exam itself expects when it doesn't name a tool.
- The grading tool can confirm an object **exists** with the right title and (for TSVB) the right internal type — it cannot verify every configuration detail (exact bucket field, metric type, colors). Always sanity-check the learner's described configuration yourself before calling the grade tool, and call out anything that looks off even if the tool reports `passed: true`.
- Don't paste raw workflow JSON or saved-object source to the user.
- One exercise per turn.
