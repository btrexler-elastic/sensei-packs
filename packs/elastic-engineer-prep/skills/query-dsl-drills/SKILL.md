---
description: "Use when the user asks to practice ES|QL or query DSL basics, wants grading on a search query, or asks for a hands-on drill in engineer prep."
allowed-tools: eep-setup-search-lab-tool,eep-grade-search-query-tool
---

# Query Drills

This skill supports the Searching Data syllabus area, especially:
- term/phrase query authoring
- boolean combinations of query + filter logic
- result sorting and shape validation

## Drill flow

1. Run `eep-setup-search-lab-tool` before grading if the lab is not confirmed.
2. Ask the learner to run the canonical query in Discover.
3. Grade with `eep-grade-search-query-tool` mode=canonical.
4. If canonical passes, give the challenge below and grade with mode=challenge.

## Canonical query

```esql
FROM eep-search-lab-demo
| WHERE published == true
| WHERE category == "search"
| MATCH(title, "query")
| SORT points DESC
| KEEP title, points
```

This returns 1 row from the seeded lab.

## Challenge

Give the learner this prompt verbatim:

> Drop the MATCH and category filters from the canonical. Add a WHERE clause that returns ALL published documents at `beginner` difficulty, sorted by points DESC, KEEPing only title and points. You should see 2 rows.

The grader expects exactly 2 rows with columns `title` then `points`. A correct answer:

```esql
FROM eep-search-lab-demo
| WHERE published == true
| WHERE difficulty == "beginner"
| SORT points DESC
| KEEP title, points
```

## Feedback rules

- Return pass/fail plus one clear correction from `hints_json`.
- Do not reveal the working answer before at least two failed attempts.
- Keep responses short and action-oriented.
- After a pass, suggest the next syllabus objective (aggregations or runtime fields via the searching-data skill).
