# Sensei packs

Content packs for **Sensei** — an enablement coach for Elastic Field Engineers, built on Elastic Agent Builder and Elastic Workflows (FY27 FE Summit hackathon submission). This repository is the **installable artifact**: Claude-spec plugins under `packs/`, orchestration workflows under `meta/`, and agent definitions under `agents/`.

For the full demo script and architecture (including Phase 6 layout rationale), see the coordinating **sko-hack** project: `docs/demo/MASTER_DEMO.md` and `spike/REPORT.md`. Lessons learned for plugins and Workflows 9.5 live in `docs/lessons-learned/agent-builder-plugins.md` and `docs/lessons-learned/workflows-9.5-api-changes.md` in that repo.

> **Status**: hackathon / tech preview. Target stack is Elastic Serverless **9.5.0**; behaviors may shift between previews.

## Layout

```
packs/<pack-id>/                   # one folder per content pack
  .claude-plugin/plugin.json       # plugin manifest
  _manifest.json                   # workflows + tools + skills file lists (see below)
  skills/<skill-id>/SKILL.md       # one folder per skill
  workflows/<workflow-id>.yaml     # workflow definitions (POSTed to /api/workflows on install)
  tools/<tool-id>.json             # tool registrations (POSTed to /api/agent_builder/tools on install)

meta/                              # orchestration owned by Sensei itself, not topic packs
  packs.json                       # catalog the list-packs workflow returns (stub until populated)
  sensei-install-pack.yaml         # lands with meta workflow authoring (gav.3)
  sensei-uninstall-pack.yaml
  sensei-list-packs.yaml
  tools/                           # corresponding tool registrations for meta workflows

agents/                            # agent definitions (one JSON file per agent; sensei.json via follow-on work)
```

Historical spike-era plugins (root `.claude-plugin/`, `skills/`, and `spike/`) are preserved on the **`spike-archive`** Git branch.

### `_manifest.json` shape

Each pack ships **`_manifest.json`** at the pack root (next to `.claude-plugin/`). The install workflow reads it once from `raw.githubusercontent.com`, then fetches each listed file by path. Example:

```json
{
  "workflows": ["workflows/r94-grade-promql.yaml"],
  "tools": ["tools/r94-grade-promql.json"],
  "skills": ["skills/promql-in-esql/SKILL.md"]
}
```

Paths are **relative to the pack root**. `workflows` and `tools` are required for installs that register workflows and workflow-tools before plugin install.

**Installer pairing rule (`sensei-install-pack`):** `workflows[N]` and `tools[N]` must refer to the workflow/tool pair that belongs together (same N). The meta installer posts workflow N, reads the cluster-assigned persisted workflow `id` from that POST response, then registers tool N with `configuration.workflow_id` set to that `id` (Serverless 9.5.0 may suffix ids vs the YAML `name`; see sko-hack `docs/lessons-learned/workflows-9.5-api-changes.md` Issue 5). `skills` is optional but recommended for validation and docs — skill bodies still come from the plugin tree at install time.

## For Sensei maintainers

- Follow **`allowed-tools`** frontmatter rules when authoring skills (comma-separated list only; other formats are ignored silently). See **`agent-builder-plugins.md`** in the sko-hack lessons-learned folder.
- Prefer **`kibana.request`** / **`elasticsearch.request`** workflow steps over raw HTTP to cluster APIs (Xsrf and credentials).

## License

MIT — see [`LICENSE`](./LICENSE).
