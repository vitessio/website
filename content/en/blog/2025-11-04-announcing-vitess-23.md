---
title: "Announcing Vitess 23.0.0"
date: 2025-11-03  
authors: [“Vitess Maintainer Team”]
slug: '2025-04-29-announcing-vitess-22'
tags: [ 'release', 'Vitess', 'v22', 'MySQL', 'kubernetes', 'operator', 'vreplication', 'multi-tenancy', 'Usability', 'Online DDL' ]
description: "Vitess 22 is now Generally Available"
---


# Announcing Vitess 23.0.0
We’re excited to release Vitess 23.0.0 — the latest major version of Vitess — bringing new defaults, better operational tooling, and refined metrics.  
This release builds on the strong foundation of version 22 and is designed to make deployment and observability smoother, while continuing to scale MySQL workloads horizontally with confidence.

---

## 🚀 What’s New in Vitess 23
Here are some of the standout changes you should know about:

### New Default Versions
* The default MySQL version for the `vitess/lite:latest` image has been bumped from **8.0.40** to **8.4.6**.  [oai_citation:0‡GitHub](https://github.com/vitessio/vitess/releases?utm_source=chatgpt.com)
* VTGate now advertises MySQL version 8.4.6 by default (instead of 8.0.40). If your backend uses a different version, set the `mysql_server_version` flag accordingly.  [oai_citation:1‡GitHub](https://github.com/vitessio/vitess/releases?utm_source=chatgpt.com)
* **Important upgrade detail for operator users**: If you are using the Vitess Operator and upgrading from MySQL 8.0.x → 8.4.x, you need to:
  1. Add `innodb_fast_shutdown=0` to your extra .cnf in the YAML.
  2. Apply the file, wait for all pods healthy.
  3. Switch the image to `vitess/lite:v23.0.0`.
  4. Remove the `innodb_fast_shutdown=0` extra and apply again.  
     This one-time step is required when crossing 8.0 → 8.4. After that you can freely upgrade/downgrade within 8.4.x versions.  [oai_citation:2‡GitHub](https://github.com/vitessio/vitess/releases?utm_source=chatgpt.com)

### New & Improved Metrics
* A new VTGate metric: `TransactionsProcessed` (dimensions: Shard, Type) — counts transactions processed at VTGate by shard distribution and transaction type.  [oai_citation:3‡GitHub](https://github.com/vitessio/vitess/releases?utm_source=chatgpt.com)
* A new VTOrc metric: `SkippedRecoveries` (dimensions: RecoveryName, Keyspace, Shard, Reason) — tracks how many recoveries were skipped, and why.  [oai_citation:4‡GitHub](https://github.com/vitessio/vitess/releases?utm_source=chatgpt.com)  
  These enhancements strengthen observability and help operators track system behaviour with finer granularity.

### Deprecations & Removals
* The VTOrc metric `DiscoverInstanceTimings` has been deprecated in favour of `DiscoveryInstanceTimings`.  [oai_citation:5‡GitHub](https://github.com/vitessio/vitess/releases?utm_source=chatgpt.com)
* Several older VTGate metrics (`QueriesProcessed`, `QueriesRouted`, `QueriesProcessedByTable`, `QueriesRoutedByTable`) have been removed — these were deprecated in v22.0.0 and are now gone.  [oai_citation:6‡GitHub](https://github.com/vitessio/vitess/releases?utm_source=chatgpt.com)
* The VTOrc HTTP API endpoint `/api/aggregated-discovery-metrics` has been removed. Operators should use standard documented VTOrc metrics instead.  [oai_citation:7‡GitHub](https://github.com/vitessio/vitess/releases?utm_source=chatgpt.com)

### Topology & VTOrc Enhancements
* The `--consul_auth_static_file` flag now **requires at least one credential** loaded from the provided JSON file.  [oai_citation:8‡GitHub](https://github.com/vitessio/vitess/releases?utm_source=chatgpt.com)
* VTOrc supports **dynamic control of `EmergencyReparentShard`-based recoveries**. (Warning: disabling this recovery path may impact availability; use with care.)  [oai_citation:9‡GitHub](https://github.com/vitessio/vitess/releases?utm_source=chatgpt.com)  
  These changes help tighten the operational security and resilience of the cluster management story.

### VTTablet & CLI / Docker Updates
* Managed MySQL configuration now defaults to `caching-sha2-password`.  [oai_citation:10‡GitHub](https://github.com/vitessio/vitess/releases?utm_source=chatgpt.com)
* MySQL timezone environment propagation is improved.  [oai_citation:11‡GitHub](https://github.com/vitessio/vitess/releases?utm_source=chatgpt.com)
* gRPC tabletmanager client error behaviors have changed.  [oai_citation:12‡GitHub](https://github.com/vitessio/vitess/releases?utm_source=chatgpt.com)
* Docker image workflows and default flags updated for consistency.  [oai_citation:13‡GitHub](https://github.com/vitessio/vitess/releases?utm_source=chatgpt.com)

---

## ✅ Why This Release Matters
For production users of Vitess, this release is meaningful in several ways:

- **Upgrading defaults**: Moving to MySQL 8.4 as default future-proofs deployments and signals forward compatibility.
- **Better metrics**: The added observability enables deeper insights into transaction routing, shard behaviour and recovery actions — making debugging and alerting more precise.
- **Clean-ups & deprecations**: Removing legacy metrics and APIs simplifies the code surface and avoids confusing older monitoring systems.
- **Operational strength**: Enhanced VTOrc and topology controls reduce risk in large-scale fleets and tighten security boundaries.

For teams scaling MySQL clusters with sharding, replica management, and operational complexity, these changes reduce friction and bring clarity.

---

## 🔧 Upgrade Notes
- Review any custom monitoring dashboards: if you relied on removed metrics (e.g., `QueriesProcessed`), you will need to update those dashboards to use the new metrics (`TransactionsProcessed`, etc.).
- If you are using the Vitess Operator and upgrading from MySQL 8.0 → 8.4, follow the multi-step upgrade path above.
- For custom `mysql_server_version` settings in VTGate, confirm they reflect the correct backend MySQL version.
- Test the change on a staging environment if you use features around reparenting, recovery automation or topology service integrations like Consul.

---

## 🧠 What’s Next
We continue to evolve Vitess in these directions:

- Deepening MySQL compatibility and sharding support (especially for new MySQL 8.x features)
- Further refinement of metrics & observability across more operational surfaces (VReplication, MoveTables, Resharding).
- Continued improvements to Kubernetes Operator experience, fidelity of upgrades, and cloud-native posture.

Stay tuned for more detailed deep-dives on specific features, and don’t hesitate to give feedback or raise issues in the community.

---

## 🙏 Thanks & Acknowledgements
As always, this release was made possible by **dozens of contributors** from the Vitess community, the PlanetScale team, and countless users who filed bugs, suggested improvements, and helped test release candidates. We’re grateful for your feedback and involvement.

Let’s keep scaling.

> “Scale beyond single MySQL instances — without giving up SQL semantics.”
>
> – The Vitess Team

---

Want to dive deeper into the full list of changes? Check out the [detailed release notes](https://github.com/planetscale/vitess/blob/5164fafb70b43192f4965842ae0a8679f8b2dd83/changelog/23.0/23.0.0/release_notes.md) for all the minor fixes, improvements and platform‐specific details.  
[oai_citation:14‡GitHub](https://github.com/planetscale/vitess/blob/5164fafb70b43192f4965842ae0a8679f8b2dd83/changelog/23.0/23.0.0/release_notes.md)  
