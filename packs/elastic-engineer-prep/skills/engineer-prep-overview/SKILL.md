---
description: "Use when the user asks for Elastic Certified Engineer prep, asks what this pack covers, or wants a guided drill path across the syllabus."
allowed-tools: eep-setup-search-lab-tool,eep-grade-search-query-tool,eep-setup-data-management-lab-tool,eep-check-data-management-lab-tool,eep-run-search-exercises-tool,eep-setup-search-app-lab-tool,eep-grade-search-app-tool,eep-setup-data-processing-lab-tool,eep-grade-data-processing-tool,eep-setup-cluster-management-lab-tool,eep-check-cluster-management-lab-tool
---

# Elastic Certified Engineer Prep

## Overview

This pack follows the Elastic Certified Engineer syllabus across five domains:
- Data Management
- Searching Data
- Developing Search Applications
- Data Processing
- Cluster Management

Each domain has a setup workflow that creates lab resources and a grader workflow that verifies the learner's work. Use the per-domain skill for the full coaching script; this skill is the entry point and router.

## Routing behavior

- If the user asks for an overview, summarize the five domains in 2-3 sentences and ask which one to start.
- If the user asks a syllabus topic, route to the matching domain skill.
- If the user asks to practice, run that domain's setup tool first.
- If the user reports they ran the canonical query, call the matching grader with `mode=canonical`.
- If the user shares a modified query, call the matching grader with `mode=challenge` and pass `user_query=<their query>`.

## Default practice flow (Searching Data)

Use this flow unless the user asks for a different domain:

1. Run `eep-setup-search-lab-tool`.
2. Ask the user to run this canonical ES|QL query in Discover:

```esql
FROM eep-search-lab-demo
| WHERE published == true
| WHERE category == "search"
| MATCH(title, "query")
| SORT points DESC
| KEEP title, points
```

3. When they confirm, call `eep-grade-search-query-tool` with `mode=canonical`.
4. Give the challenge verbatim:

> Drop the MATCH and category filters from the canonical. Add a WHERE clause that returns ALL published documents at `beginner` difficulty, sorted by points DESC, KEEPing only title and points. You should see 2 rows.

5. When they paste their modified query, call `eep-grade-search-query-tool` with `mode=challenge` and `user_query=<their query>`.
6. After grading, offer the next domain.

## Guardrails

- Do not paste raw workflow JSON to the user.
- Keep feedback concise and concrete.
- If setup or grading fails, explain the failure in plain English and offer one next action.
- Do not reveal a challenge answer before at least two failed attempts.
