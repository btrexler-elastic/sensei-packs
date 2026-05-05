# Sensei Packs

Open content packs for **Sensei** — an interactive enablement agent for Elastic Field Engineers, built on Elastic Agent Builder + Elastic Workflows.

Each pack bundles:

- **Skills** — markdown drill scripts that tell Sensei how to tutor on a topic
- **Workflows** — YAML lab setup + answer-grading automations
- **Manifest** — what the pack contains, what version of Elastic it targets

Packs install directly into a Kibana / Elastic Agent Builder deployment, either:

- via the **Plugins library** ("Install from URL" pointing at this repo), _or_
- via a **Sensei sync workflow** that fetches the pack files and POSTs them to the relevant Agent Builder + Workflows APIs.

> **Status**: experimental, hackathon project.
> The format and install mechanism are being validated against Elastic Serverless 9.5.0. Expect breaking changes.

## What's a pack?

```
packs/<pack-id>/
├── pack.yaml                 # manifest: id, title, description, drills[], elastic version target
├── skills/
│   └── <skill-id>.md         # Claude Agent Skill format (frontmatter + markdown body)
└── workflows/
    └── <workflow-name>.yaml  # Elastic Workflow YAML (setup, grader, etc.)
```

Each drill is one or more skill + workflow pairs. A skill tells Sensei how to tutor; the matching workflows do the deterministic cluster work (provisioning the lab, grading the user's answer).

## Planned packs

| Pack ID | Purpose | Status |
|---|---|---|
| `core` | Bootstraps Sensei: tutoring meta-skills, list/install pack tools | TBD |
| `engineer-exam-text-analysis` | Exam-prep drills for analyzers, tokenizers, token filters | TBD |
| `release-9-4-enablement` | What's new in 9.4: ES\|QL JOIN, semantic_text v2, etc. | TBD |

## How to install a pack

_Pending plugin spike — instructions added after the install mechanism is validated._

## Authoring a new pack

_Pending pack format lock — guidelines added after the first pack ships._

## License

MIT — see [`LICENSE`](./LICENSE).
