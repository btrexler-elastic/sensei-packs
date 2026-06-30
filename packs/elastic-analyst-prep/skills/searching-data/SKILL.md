---
description: "Use when the user asks about data views, the time filter, KQL/Lucene search syntax, filters, or saved searches in Kibana Discover."
allowed-tools: eap-setup-analyst-lab-tool, eap-grade-discover-lab-tool
---

# Searching Data

Exam objectives this skill covers:

- Define an index pattern (data view) with or without a Time Filter field
- Set the time filter to a specified date or time range
- Use the Kibana Query Language (KQL) in the search bar to display only documents that match a specified criteria
- Create and pin a filter based on a search criteria
- Apply a search criteria to a visualization or dashboard

---

## Beat 1 — Explain

Give a 2-sentence summary of each concept, then ask if they want to set up a lab:

**Data views (index patterns)**
> A data view tells Kibana which indices to query and which field is time-based. Created in **Stack Management → Data Views**, or on the fly from Discover. Wildcards (`logs-*`) match multiple indices; the time field (usually `@timestamp`) is what powers the time picker and histogram.

**Time filter**
> Top-right time picker sets the global time range — absolute dates, relative ("Last 15 minutes"), or a dragged selection on the histogram. Every panel using that data view's time field respects it unless explicitly overridden.

**KQL in the search bar**
> Default Discover query language. `field: value` matches a term; quote for phrases (`field: "exact phrase"`); combine with `and`/`or`/`not`; use `*` for wildcards and comparison operators (`>`, `>=`, `<`, `<=`) on numeric/date fields. Lucene syntax is still selectable from the language switcher but KQL is what the exam expects by default.

**Filters**
> Built from the **+ Add filter** button (or by clicking a field value), filters are exact-match AND'ed restrictions shown as pills below the search bar — separate from the free-text query. **Pin** a filter (the pin icon) to keep it active across apps as you navigate between Discover, visualizations, and dashboards.

**Applying search criteria to visualizations/dashboards**
> A KQL query or filter set active in Discover, or saved with a search, carries over when you create a visualization "from" that saved search, and pinned filters persist as you move into the Visualize or Dashboard apps.

Close with: _"Want me to set up a lab index so you can practice these in Discover?"_

---

## Beat 2 — Setup and canonical exercise

Call **`eap-setup-analyst-lab-tool`** with no parameters. It creates `eap-analyst-lab-demo`, a small web-traffic index — three hosts, ~30 minutes of data, a couple of planted errors, and a byte-volume spike — but **does not** create the Kibana data view. That's the learner's first task.

After the tool returns, tell the learner:

> Lab index `eap-analyst-lab-demo` is ready with {{doc_count}} docs spanning roughly {{time_window_iso_start}} to {{time_window_iso_end}}. Now, in Kibana:
>
> 1. Go to **Stack Management → Data Views → Create data view**.
> 2. Index pattern: `eap-analyst-lab-demo*`. Time field: `@timestamp`.
> 3. Save it.
> 4. Open **Discover**, select that data view, and set the time range to **Last 1 hour**.
> 5. In the KQL search bar, find documents where `response_code` is `"500"` or `"404"`.
> 6. Save the search as **"Lab Errors"** (Save button in the Discover toolbar).
>
> Tell me once you've saved it.

When they confirm, call **`eap-grade-discover-lab-tool`** with `saved_search_title: "Lab Errors"`.

- `passed: true`: confirm — "Found it. Two error docs in this dataset: a `500` from `web-2` and a `404` from `web-2` a few minutes later — same host, different failure modes. Your KQL likely read `response_code: "500" or response_code: "404"`, or you built it as two `+ Add filter` pills OR'd together. Either is valid; the search bar is generally faster for simple disjunctions."
- `passed: false`: report the hint from `hints_json`. Most common cause is the data view not being created yet, or the saved search title not matching exactly (it's case-sensitive in this check).

---

## Beat 3 — Challenge

Say:

> New saved search: **"EU Search Traffic"**, showing only documents from the `eu-west` region with `url.path` of `/search`, with the time filter pinned to the same range. Save it, and **pin** a filter for the region before you save (don't put the region in the KQL bar — use a real filter pill).

There's no separate grading tool call for the pinned-filter requirement (saved object inspection can't distinguish a pinned filter from KQL text), so review their description of what they did:

- The query bar should contain only the `url.path` condition (e.g. `url.path: "/search"`).
- A separate filter pill for `region: eu-west` should exist and be pinned (pin icon engaged, shown with a small pin glyph on the pill).
- Ask them to paste a screenshot description or confirm pin state if unclear — don't assume.

Then call **`eap-grade-discover-lab-tool`** with `saved_search_title: "EU Search Traffic"`. Note: this grading call's `query_mentions_response_code` check is built for the canonical exercise — for this challenge, only treat `passed: false` due to `has_saved_search: false` or `has_index_pattern: false` as blocking; a `false` on the content check here is expected and not a problem, since the challenge query targets `url.path`, not `response_code`. Tell the learner this explicitly so they're not confused by an unrelated hint.

- If the saved search exists: "Saved search confirmed. Three hits expected — all the `web-3`/`eu-west` `/search` requests. The key habit: free-text query for what varies in your investigation, filter pills (pinned if they should survive navigation) for the fixed context you're investigating within."
- If missing: ask them to re-save with the exact title.

---

## Beat 4 — Reference exercises (inline, no grade tool)

Work through these one at a time as the learner asks. No grading tool call needed — review their description of the result against the reference behavior.

### Time filter precision

Tell them: set the time picker to an **absolute** range covering only the last 6 minutes of the lab window (use `time_window_iso_end` minus 6 minutes through `time_window_iso_end`). Confirm: Discover should show exactly 6 documents (2 hosts × 3 time slices) — the 500, the 404, and the byte spike all fall inside this window along with their neighbors. If they get a different count, the absolute range boundaries are off — remind them Kibana's range is typically start-inclusive, end-inclusive on the picker UI.

### Range query in KQL

Base ask: find documents where `bytes` is greater than `10000`. Reference: `bytes > 10000`. Expect exactly 1 hit — the planted spike on `web-1`. Explain: comparison operators work directly on numeric and date mapped fields, no range filter needed for simple cases.

### Wildcard + boolean combination

Base ask: find all `/checkout` or `/search` traffic, excluding errors. Reference: `(url.path: "/checkout" or url.path: "/search") and not tags: "error"`. Walk through why parentheses matter here — without them, `and not tags: "error"` binds only to the second `or` clause due to KQL precedence, not the whole expression.

### Filter ratio sanity check (bridges into Analyzing)

Mention that the error count vs. total count visible in Discover is the same arithmetic that powers a "filter ratio" panel later in Visualizing/Analyzing — worth noting now, not solving now.

---

## Hard rules

- Data views are created and verified — never assume one exists; the setup tool deliberately doesn't create it so the learner practices the actual exam objective.
- Saved search titles are graded as exact (case-sensitive) string matches — tell the learner the precise title to use, every time.
- Distinguish free-text KQL from filter pills explicitly when reviewing what the learner built; conflating the two is the most common real-exam mistake on this objective.
- Don't paste raw workflow JSON to the user.
- One exercise per turn — don't front-load all four objectives at once.
