---
author: 'Vitess Maintainer Team'
date: 2025-04-29
slug: '2025-04-29-announcing-vitess-22'
tags: [ 'release', 'Vitess', 'v22', 'MySQL', 'kubernetes', 'operator', 'vreplication', 'multi-tenancy', 'Usability', 
        'Online DDL' ]
title: 'Announcing Vitess 22'
description: "Vitess 22 is now Generally Available"
---

# **Announcing Vitess 22**

The Vitess maintainers are happy to announce the release of [version 22.0.0](https://github.com/vitessio/vitess/releases/tag/v22.0.0), along with [version 2.15.0](https://github.com/planetscale/vitess-operator/releases/tag/v2.15.0) of the Vitess Kubernetes Operator.
This release is the first to benefit from a 6-month-long development cycle, after our [recent change to the release cadence](https://github.com/vitessio/enhancements/pull/12).

Version 22.0.0 comes with significant enhancements to query serving and cluster management.
These changes have allowed Vitess to be more performant and easier to operate compared to version 21.
This blog post highlights some of the major changes that went into the release.
For a more detailed description of the release, please refer to the [release notes](https://github.com/vitessio/vitess/releases/tag/v22.0.0).

---

## Summary

* **Query Serving**: Prepared statements and new VTGate metrics
* **Cluster Management and VTOrc**: Stalled-disk recovery, improved errant GTID discovery and VTOrc performance improvements
* **Kubernetes Operator**: Automated backups, Kubernetes 1.32 support, better examples
* **Performance**: Improvements compared to v21.0.0

---

### Query Serving

Vitess 22.0 brings a host of query‑serving enhancements focused on observability, smarter handling of prepared statements, GA support for sharded views, and feature‑complete atomic distributed transactions.

#### Observability

Vitess now emits metrics for query execution plans, which help you analyze execution patterns and optimize costly plans—see the [Query Serving metrics guide](https://vitess.io/docs/22.0/reference/query-serving/metrics/).

#### Prepared Statements

We have overhauled VTGate’s prepare pipeline: prepared statements are cached as raw SQL to skip redundant parsing, and deferred execution plans are generated using actual bind values for more optimized, parameter‑aware planning.

#### Views and Atomic Distributed Transactions

Sharded view support is GA now, and the atomic distributed transaction feature is complete—learn more in the [Distributed Transactions guide](https://vitess.io/docs/22.0/reference/features/distributed-transaction/).


### Cluster Management and VTOrc

There were several performance and usability enhancements to VTOrc in the Vitess 22.0 release.
It now operates more efficiently, with fewer topology service calls and better overall resource consumption.

VTOrc now supports specifying shard ranges in the `--keyspaces-to-watch` flag, making it easier to configure in large deployments.

This release also introduces stalled disk recovery to VTOrc, along with improved handling of errant GTID detection.
Additionally, vttablets are now prevented from joining the replication topology if they contain errant GTIDs.

Finally, we’ve added a new semi-sync monitor to VTOrc.
This helps detect and unblock vttablets that are stuck waiting for semi-sync ACKs – a situation that can occur if ACKs are lost due to network issues.

### Kubernetes Operator

The v22.0.0 release of Vitess comes along with the v2.15.0 release of our Kubernetes operator.
This new release follows the same release cycle as Vitess.
As part of this release, the officially supported Kubernetes version is v1.32.

The original implementation of automated and scheduled backups done in v2.13.0 used an empty pod running `vtctldclient BackupShard` to execute the backup.
This approach had trade-offs, the backup process ran faster but effectively removed a serving tablet from the available tablet pool.
In v2.15.0, we have changed the implementation to use a VTBackup pod instead, to be consistent with our own recommendations for production deployments and to reduce impact on availability.

All our provided examples have been enhanced to illustrate how the VitessOperator and VitessCluster can be run in two different namespaces.

Please refer to the [operator release notes](https://github.com/planetscale/vitess-operator/releases/tag/v2.15.0) to learn more about v2.15.0.

### Performance

In this release, we have reduced query latency and cut memory allocations across Vitess through targeted optimizations:

* **gRPC Codec upgrade**: Vitess now uses gRPC with Codec v2 and a pooled buffer, yielding a ~3% QPS improvement and ~13% reduction in per‑request allocations.
* **Normalizer AST walk reduction**: Merged two normalization AST passes into one, speeding VTGate’s normalizer by ~5% and cutting allocations per operation by ~5.5%.
* **AST rewriting optimization**: Combined RewriteAST and Normalizer into a single pass, trimming planner latency by ~2.7% and reducing allocations by ~4.3%.
* **Merge‑sort avoidance on single‑shard queries**: VTGate now skips redundant merge sorts when only one shard is involved, eliminating unnecessary CPU work for the common single‑shard case.

---

### Migrate and Learn More

To ease migration from a previous version to v22.0.0, it is highly recommended to read the release notes of both [Vitess](https://github.com/vitessio/vitess/releases/tag/v22.0.0) and the [Kubernetes Operator](https://github.com/planetscale/vitess-operator/releases/tag/v2.15.0).
The entire [changelog](https://github.com/vitessio/vitess/blob/main/changelog/22.0/22.0.0/changelog.md) for this version is available too.

It is also recommended to explore our [documentation for v22.0.0](https://vitess.io/docs/22.0/), where you can find step-by-step user guides, best practices, and tips to run Vitess.

### Community

As an open-source project, we truly appreciate feedback, insights, and contributions from our community.
Whether you want to share a story, ask a question, or anything else, you can reach out to us on [GitHub](https://github.com/vitessio/vitess) or in our [Slack](http://vitess.io/slack).

---

*The Vitess Maintainer Team*
