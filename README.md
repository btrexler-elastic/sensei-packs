# Sensei

Sensei is an enablement coach for Elastic Field Engineers, built on **Elastic Agent Builder**, **Elastic Workflows**, and **Agent Builder plugins**. It teaches product capabilities through short, hands-on drills backed by installable **content packs**: each pack adds workflows, registered workflow-tools, and plugin skills that Sensei can use in chat. This repository is the public source for those packs, the meta orchestration workflows Sensei uses to install them, and the baseline `sensei` agent definition.

## Quickstart

1. Clone this repository and `cd` into it.
2. `cp .env.example .env` and fill in `KIBANA_URL`, `ELASTICSEARCH_URL`, and `ELASTICSEARCH_API_KEY` (see comments in `.env.example`).
3. Run `./scripts/install-sensei.sh` (use `./scripts/install-sensei.sh --plan` first to preview actions).
4. Open **Kibana** → **Agent Builder** → select the **Sensei** agent.
5. Ask: **"What packs are available?"** to confirm the catalog tool path.

## Prerequisites

- Elastic Cloud **Serverless 9.5.0+** (a Search project is recommended; Observability or Security projects may also work).
- An **inference connector** configured on the project (development used Anthropic Claude Sonnet 4.6).
- A **Kibana API key** with permission to use Agent Builder, Workflows, and related stack APIs.
- Local tools: `bash`, `curl`, `jq`, `python3`.

## Installation

The `./scripts/install-sensei.sh` script bootstraps the **sensei-meta** workflows (install / uninstall / list packs), registers their workflow-tools with cluster-assigned `workflow_id` values, creates or updates the **Sensei** agent from `agents/sensei.json`, and installs the **`sensei-core`** catalog plugin via the install-pack workflow.

- **`--plan`** — Prints what would be created or skipped; performs **GET** checks only (including `/api/status`). No writes.
- **`--force`** — Removes Sensei bootstrap objects from Kibana (the Sensei agent, the three meta tools, workflows tagged `sensei-meta`, and the `sensei-core` plugin), then recreates them. Use when workflow IDs drift or artifacts are half-deleted.

**Artifacts created**

| Kind | Names |
|------|--------|
| Workflows | `sensei-install-pack`, `sensei-uninstall-pack`, `sensei-list-packs` (tagged `sensei-meta`) |
| Tools | `sensei-install-pack-tool`, `sensei-uninstall-pack-tool`, `sensei-list-packs-tool` |
| Agent | `sensei` |
| Plugin | `sensei-core` (installed from `packs/sensei-core` on GitHub) |

**Idempotency**

Without `--force`, re-running the script skips workflows that already exist, skips tools whose `workflow_id` matches the live workflows, skips agent creation when the baseline matches `agents/sensei.json` (instructions, tools, and `enable_elastic_capabilities`), and skips `_execute` when `sensei-core` skills are already present on the agent. If the agent exists but the baseline differs, the script **merges** the repo definition onto the live agent with **`GET → PUT`** so **`skill_ids`** and **`plugin_ids`** from an existing install are preserved.

Optional environment variable **`KIBANA_SPACE_ID`** (when set and not `default`) scopes all URLs to `/s/<space_id>/`.

## Layout

```
packs/<pack-id>/                   # one folder per content pack
  .claude-plugin/plugin.json       # plugin manifest
  _manifest.json                   # workflows + tools + skills file lists (see below)
  skills/<skill-id>/SKILL.md       # one folder per skill
  workflows/<workflow-id>.yaml     # workflow definitions (POSTed to /api/workflows on install)
  tools/<tool-id>.json             # tool registrations (POSTed to /api/agent_builder/tools on install)

meta/                              # orchestration used by Sensei (not topic packs)
  packs.json                       # catalog data returned by the list-packs workflow
  sensei-install-pack.yaml
  sensei-uninstall-pack.yaml
  sensei-list-packs.yaml
  tools/                           # tool JSON for the meta workflows

agents/                            # agent definitions (JSON per agent)
scripts/
  install-sensei.sh                # bootstrap meta workflows + agent + sensei-core
```

### `_manifest.json` shape

Each pack ships **`_manifest.json`** at the pack root (next to `.claude-plugin/`). The install workflow reads it once from `raw.githubusercontent.com`, then fetches each listed file by path. Example:

```json
{
  "workflows": ["workflows/r94-grade-promql.yaml"],
  "tools": ["tools/r94-grade-promql.json"],
  "skills": ["skills/promql-in-esql/SKILL.md"]
}
```

Paths are **relative to the pack root**. `workflows` and `tools` are required when the pack registers workflows and workflow-tools before plugin install.

**Installer pairing rule (`sensei-install-pack`):** `workflows[N]` and `tools[N]` must be the pair that belongs together (same index **N**). The installer posts workflow **N**, reads the cluster-assigned workflow **`id`** from that POST response, then registers tool **N** with `configuration.workflow_id` set to that **`id`**. On Serverless 9.5.x, persisted workflow IDs may be **suffixed** compared to the YAML `name`. `skills` is optional for orchestration (skill bodies still come from the plugin tree at install time).

## Authoring a pack

- **`allowed-tools` in `SKILL.md` frontmatter** must be a **comma-separated** list (e.g. `allowed-tools: tool-a, tool-b`). Space-separated IDs, YAML lists, or other formats are ignored or rejected — see Agent Builder plugin documentation for details.
- Prefer **`kibana.request`** and **`elasticsearch.request`** steps in workflow YAML instead of raw **`http`** calls to Kibana or Elasticsearch, so `kbn-xsrf`, paths, and credentials are handled consistently.
- Tag workflows with your pack identifier (and/or a dedicated cleanup tag) so operators can find and remove them later.
- Ship **`_manifest.json`** with **`workflows[]`** and **`tools[]` index-paired** as described above.

## License

MIT — see [LICENSE](./LICENSE).
