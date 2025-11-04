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

## ✅ Why This Release Matters
For production users of Vitess, this release is meaningful in several ways:

- **Upgrading defaults:** Moving to MySQL 8.4 as default future-proofs deployments and signals forward compatibility.
- **Better metrics:** The added observability enables deeper insights into transaction routing, shard behavior, and recovery actions — making debugging and alerting more precise.
- **Clean-ups & deprecations:** Removing legacy metrics and APIs simplifies monitoring and avoids confusion.
- **Operational strength:** Enhanced VTOrc and topology controls reduce risk in large-scale fleets and tighten security boundaries.

---

## 🚀 What’s New in Vitess 23
Here are some of the standout changes you should know about:

### New Default Versions
* The default MySQL version for the `vitess/lite:latest` image has been bumped from **8.0.40** to **8.4.6**.  
  → [PR #18569](https://github.com/vitessio/vitess/pull/18569)
* VTGate now advertises MySQL version 8.4.6 by default (instead of 8.0.40). If your backend uses a different version, set the `mysql_server_version` flag accordingly.  
  → [PR #18568](https://github.com/vitessio/vitess/pull/18568)
* **Important upgrade detail for operator users:**  
  When upgrading from MySQL 8.0 → 8.4 with the Vitess Operator, you must:
  1. Add `innodb_fast_shutdown=0` to your extra .cnf in the YAML.
  2. Apply the file and wait until all pods are healthy.
  3. Switch the image to `vitess/lite:v23.0.0`.
  4. Remove `innodb_fast_shutdown=0` and re-apply.  
     This is only required once when crossing 8.0 → 8.4. See the [official release notes](https://github.com/planetscale/vitess/blob/5164fafb70b43192f4965842ae0a8679f8b2dd83/changelog/23.0/23.0.0/release_notes.md#upgrade-instructions-for-operator-users).

### New & Improved Metrics
* **VTGate:** new metric `TransactionsProcessed` (dimensions: Shard, Type) counting transactions processed at VTGate by shard and transaction type.  
  → [PR #18408](https://github.com/vitessio/vitess/pull/18408)
* **VTOrc:** new metric `SkippedRecoveries` (dimensions: RecoveryName, Keyspace, Shard, Reason) tracking how many recoveries were skipped and why.  
  → [PR #18405](https://github.com/vitessio/vitess/pull/18405)

These improvements strengthen observability and help operators track system behavior with finer granularity.

### Deprecations & Removals
* **VTOrc metric rename:** `DiscoverInstanceTimings` → `DiscoveryInstanceTimings`.  
  → [PR #18406](https://github.com/vitessio/vitess/pull/18406)
* **Removed deprecated VTGate metrics:** `QueriesProcessed`, `QueriesRouted`, `QueriesProcessedByTable`, `QueriesRoutedByTable`.  
  → [PR #17727](https://github.com/vitessio/vitess/pull/17727)
* **Removed VTOrc API endpoint:** `/api/aggregated-discovery-metrics`.  
  → [PR #18407](https://github.com/vitessio/vitess/pull/18407)

### Topology & VTOrc Enhancements
* The `--consul_auth_static_file` flag now **requires at least one credential** in the provided JSON.  
  → [PR #18409](https://github.com/vitessio/vitess/pull/18409)
* VTOrc now supports **dynamic control of EmergencyReparentShard-based recoveries.**  
  → [PR #18410](https://github.com/vitessio/vitess/pull/18410)  
  These changes improve operational safety and resilience for cluster management.

### VTTablet & CLI / Docker Updates
* Managed MySQL configuration now defaults to `caching-sha2-password`.  
  → [PR #18403](https://github.com/vitessio/vitess/pull/18403)
* MySQL timezone environment propagation improved.  
  → [PR #18404](https://github.com/vitessio/vitess/pull/18404)
* gRPC tabletmanager client error behaviors clarified.  
  → [PR #18402](https://github.com/vitessio/vitess/pull/18402)
* Docker image workflows and flags updated for consistency.  
  → [PR #18411](https://github.com/vitessio/vitess/pull/18411)

---

## 🔧 Upgrade Notes
- Review custom dashboards: if you relied on removed metrics, update them to new ones (`TransactionsProcessed`, etc.).
- Operator users upgrading 8.0 → 8.4: follow the [four-step sequence](https://github.com/planetscale/vitess/blob/5164fafb70b43192f4965842ae0a8679f8b2dd83/changelog/23.0/23.0.0/release_notes.md#upgrade-instructions-for-operator-users).
- If you override `mysql_server_version` in VTGate, ensure it matches your backend MySQL version.
- Test changes involving reparenting, recovery, or Consul integration in staging first.

---

## 🧠 What’s Next
We continue to evolve Vitess toward:

- Deeper MySQL 8.4 compatibility.
- Expanded observability across VReplication, MoveTables, and Resharding.
- Ongoing Operator improvements for reliability and clarity.

---

## 🙏 Thanks & Acknowledgements
This release was made possible by dozens of contributors from the Vitess community and the PlanetScale team.  
Thank you for filing bugs, testing RCs, and helping keep Vitess robust and scalable.

Let’s keep scaling.

> “Scale beyond single MySQL instances — without giving up SQL semantics.”
>
> – The Vitess Team

---

To explore every detail, see the  
👉 [Full Release Notes for Vitess 23.0.0](https://github.com/planetscale/vitess/blob/5164fafb70b43192f4965842ae0a8679f8b2dd83/changelog/23.0/23.0.0/release_notes.md)
