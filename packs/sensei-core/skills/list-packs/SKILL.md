---
description: "Use when the user asks what packs / topics / content / lessons / drills / courses are available, or asks 'what can you teach me?' or similar."
allowed-tools: sensei-list-packs-tool
---

# List available Sensei packs

1. Call **`sensei-list-packs-tool`** with no hidden assumptions — it returns JSON shaped like `{ "packs": [ ... ] }` from the repo catalog.
2. Turn that payload into a **short bullet list**:
   - One line per pack: **bold title** — one clause describing what it teaches.
   - Append **`(coming soon)`** immediately after the title when `status` (or equivalent flag) is `coming-soon`.
3. **Sort for readability**: every **`available`** pack first, then every **`coming-soon`** pack. Keep the ordering stable within each group as returned unless the user asked otherwise.
4. Close with: **Which one do you want to start with?**

Do **not** invent packs that aren't in the JSON. If the tool errors, say the catalog could not be fetched and suggest retrying — don't hallucinate titles.
