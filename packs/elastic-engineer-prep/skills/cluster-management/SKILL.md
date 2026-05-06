---
description: "Use when the user asks about shard health, snapshots/restore, searchable snapshots, CCS/CCR, or snapshot lifecycle management."
allowed-tools: eep-setup-cluster-management-lab-tool
---

# Cluster Management

Syllabus objectives this skill covers:

- Diagnose shard issues and repair a cluster's health
- Backup and restore a cluster and/or specific indices
- Configure a snapshot to be searchable
- Configure a cluster for cross-cluster search
- Implement cross-cluster replication
- Automate snapshots with Snapshot Lifecycle Management

## Beat 1 — Explain

In 3-4 sentences:

> Cluster management is the operations side: keep shards allocated, take backups you can restore, and connect clusters for search and replication. On serverless and Elastic Cloud, much of this is managed for you, but the exam still expects you to read `_cluster/health`, run `allocation/explain`, and author the snapshot/SLM/CCR/CCS request shapes from memory. The lab in this skill gives you a known-healthy index to practice diagnostics against.

Close with: _"Want me to set up a healthy reference index so we can read its health together?"_

## Beat 2 — Setup

Call **`eep-setup-cluster-management-lab-tool`** with no parameters.

It creates `eep-cluster-demo` with 1 primary shard, 0 replicas (stays green on a single node), and 3 seed log docs.

After setup, ask the learner to run these in Console:

```
GET /_cluster/health/eep-cluster-demo
GET /_cat/indices/eep-cluster-demo?v
GET /_cluster/allocation/explain
{ "index": "eep-cluster-demo", "shard": 0, "primary": true }
```

Ask them to paste the health response. Verify `status` is `"green"` or `"yellow"`. If it's red, walk through `GET /_cluster/allocation/explain` together to diagnose the unassigned shard.

## Beat 3 — Trimmed install note

This install subset keeps the setup flow only. After setup, discuss health, snapshots, CCS, CCR, and SLM as a manual walkthrough.

The cluster-admin syllabus topics below are best practiced in Console because they require cluster-level privileges and resources we can't provision per learner. For each, share the request shape and have the learner explain what each field does:

**Snapshot + restore (self-managed; on cloud, repos are pre-registered):**

```
PUT /_snapshot/my-repo/snap-1
{ "indices": "eep-cluster-demo", "include_global_state": false }

POST /_snapshot/my-repo/snap-1/_restore
{ "indices": "eep-cluster-demo", "rename_pattern": "(.+)", "rename_replacement": "$1-restored" }
```

**Searchable snapshot (mount as cold/frozen):**

```
POST /_snapshot/my-repo/snap-1/_mount
{ "index": "eep-cluster-demo", "renamed_index": "eep-cluster-demo-mounted" }
```

**SLM policy:**

```
PUT /_slm/policy/nightly
{
  "schedule": "0 30 1 * * ?",
  "name": "<nightly-{now/d}>",
  "repository": "my-repo",
  "config": { "indices": ["eep-*"], "include_global_state": false },
  "retention": { "expire_after": "30d", "min_count": 5, "max_count": 50 }
}
```

**CCS / CCR (require a remote cluster registered in cluster settings):**

```
PUT /_cluster/settings
{ "persistent": { "cluster.remote.cluster_two.seeds": ["other-host:9300"] } }

# CCS query
POST /cluster_two:logs-*,/local-logs-*/_search

# CCR follower index
PUT /follower-index/_ccr/follow
{ "remote_cluster": "cluster_two", "leader_index": "leader-index" }
```

Encourage the learner to explain what each field does and _why_ each policy choice matters operationally.

## Hard rules

- Do not paste raw workflow JSON to the user.
- Be honest: snapshot/CCR/CCS API shapes are taught here as references, not run end-to-end on the lab cluster.
- For diagnostics, walk through `allocation/explain` — that's the exam's go-to for "shard is stuck" scenarios.
