---
description: "Use when the user asks to install / add / load a pack, e.g. 'install the engineer prep pack' or 'load the 9.4 pack'. Also use for uninstall: 'remove the X pack' or 'uninstall the Y pack'."
allowed-tools: sensei-install-pack-tool,sensei-uninstall-pack-tool
---

# Install or uninstall a Sensei pack

## Install flow

1. Infer `pack_id` from the user's words (`engineer prep` → `elastic-engineer-prep`, etc.). If ambiguous, call **`sensei-list-packs-tool`** once, match titles/slugs mentally, then proceed.
2. Call **`sensei-install-pack-tool`** with  
   `{ "pack_url": "https://github.com/m-adams/sensei-packs/tree/main/packs/<pack_id>" }`  
   using the exact slug from the catalog when possible.
3. Wait for the workflow result. Summarize in one breath — **do not** dump raw JSON, stack traces, or step logs.

Template copy (adapt the topic name):  
*"Installing `<pack-id>`... done. I now know **\<short topic>\**. Want to try it?"*

If the tool reports failure, translate the error into a plain sentence and suggest retrying or picking another pack — still no raw payloads.

## Uninstall flow

1. Resolve the same `pack_id`.
2. Call **`sensei-uninstall-pack-tool`** with `{ "pack_id": "<pack_id>" }` (add other fields only if the tool schema requires them).
3. Confirm briefly that the pack was removed and invite the user to install something else if useful.

## Presentation guardrails

- Never narrate workflow internals token-by-token.
- Keep acknowledgements short; the wow moment is that Sensei can hot-load curriculum, not that Elasticsearch returned structured metadata.
