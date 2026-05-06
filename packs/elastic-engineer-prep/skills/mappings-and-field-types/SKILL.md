---
description: "Use when the user asks about mappings, field types, dynamic mapping, multi-fields, strict mapping, or mapping conflicts for engineer prep."
---

# Mappings and Field Types

## What to teach

- The mapping defines how values are indexed and queried.
- Use keyword for exact matching, aggregations, and sorting.
- Use text for full-text search and relevance scoring.
- Use multi-fields when the same value needs both text and keyword behavior.
- Use dynamic: strict in lab scenarios to catch accidental field drift.

## Exam-oriented checklist

- Pick the correct type for each field before indexing data.
- Verify mappings with GET /index/_mapping.
- Confirm query intent: exact term on keyword, full-text match on text.
- Watch for coercion and date parsing edge cases.

## Common mistakes to warn about

- Running term queries against text fields and expecting analyzed matching.
- Forgetting keyword subfields for sorting and aggregations.
- Leaving dynamic mapping fully open in structured datasets.
