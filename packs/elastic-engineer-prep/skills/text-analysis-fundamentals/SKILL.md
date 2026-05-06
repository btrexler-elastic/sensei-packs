---
description: "Use when the user asks about analyzers, tokenization, lowercase/stemming, search analyzer differences, or why a text query did not match."
---

# Text Analysis Fundamentals

## What to teach

- Analysis happens at index time and search time.
- An analyzer is tokenizer + filters.
- Standard + lowercase is a safe default for many English text fields.
- Stemming can improve recall but may reduce precision.

## Practical debug flow

- Use _analyze to inspect produced tokens.
- Compare analyzer output to query terms.
- Check whether fields use text vs keyword.
- Validate whether stopwords or stemming changed expected tokens.

## High-value exam reminders

- Know when to use custom analyzers.
- Understand how match queries rely on analyzed tokens.
- Keep exact identifiers in keyword fields, not text-only fields.
