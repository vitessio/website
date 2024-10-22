---
author: 'Vitess Maintainer Team'
date: 2024-10-29
slug: '2024-10-29-announcing-vitess-21'
tags: [ 'release', 'Vitess', 'v21', 'MySQL', 'kubernetes', 'operator', 'vreplication', 'multi-tenancy', 'Usability', 
        'Online DDL' ]
title: 'Announcing Vitess 21'
description: "Vitess 21 is now Generally Available"
---

# **Announcing Vitess 21**

We're delighted to announce the release of [Vitess 21](https://github.com/vitessio/vitess/releases/tag/v21.0.0) along
with [version 2.14.0](https://github.com/planetscale/vitess-operator/releases/tag/v2.14.0) of the Vitess Kubernetes
Operator.

Version 21 focuses on enhancing query compatibility, improving cluster management, and expanding VReplication
capabilities, with experimental support for atomic distributed transactions and recursive CTEs. Key features include
reference table materialization, multi-metric throttler support, and enhanced online DDL functionality. Backup and
restore processes benefit from a new **mysqlshell** engine, while **vexplain** now offers detailed execution traces and
schema analysis. The Vitess Kubernetes Operator introduces horizontal auto-scaling for VTGate pods and Kubernetes 1.31
support, improving overall scalability and deployment flexibility.

## What's New in Vitess 21

* **Query Compatibility**: Experimental support for atomic distributed transactions and recursive CTEs
* **VReplication**: Reference table materialization, dynamic workflow configuration
* **Cluster Management And VTOrc**: More metrics in VTOrc to track errant GTIDs
* **Throttler**: multi-metric support
* **Online DDL**: Various improvements
* **Backup & restore**: Experimental mysqlshell engine
* **Vitess Operator**: VTGate scaling, image customization, Kubernetes 1.31 support
* **VTAdmin**: VReplication workflow creation and management, distributed transaction management
* **VExplain**: **vexplain trace** for detailed query execution insights, **vexplain keys** for analyzing sharding key
  usage and optimizing query performance

## Let’s Dive Deeper

Let’s take a deeper look at some key highlights of this release.

### Query Compatibility

#### Atomic Distributed Transactions

We’re reintroducing atomic distributed transactions with a revamped, more resilient design. This feature now offers
deeper integration with core Vitess components and workflows, such as OnlineDDL and VReplication (including operations
like **MoveTables** and **Reshard**). We have also greatly simplified the configuration required to use atomic
distributed transactions. This feature is currently in an experimental state, and we encourage you to explore it and
share your feedback to help us improve it further.

#### Recursive Common Table Expressions (CTEs)

Vitess 21 introduces experimental support for recursive CTEs, allowing more complex hierarchical queries and graph
traversals. This feature enhances query flexibility, particularly for managing parent-child relationships like
organizational structures or tree-like data. As this functionality is still experimental, we encourage you to explore it
and provide feedback to help us improve it further.

### Cluster Management and VTOrc

We have added a new metric in VTOrc that shows
the count of errant GTIDs in all the tablets for better visibility and alerting. This will help
operators to track and manage errant GTIDs across the cluster.

### VReplication

#### Reference Table Materialization

Vitess provides **Reference Tables** as a mechanism to replicate commonly used lookup tables from an unsharded keyspace
into all shards in a sharded keyspace. Such tables might be used to hold lists of countries, states, zip codes, etc,
which are commonly used in joins with other tables in the sharded keyspace. Using reference tables allows Vitess to
execute joins in parallel on each shard thus avoiding cross-shard joins. Previously, we recommended creating Materialize
workflows for reference tables, but did not provide an easy way to do so. In v21 we have added explicit support to the 
**Materialize** command to replicate a set of reference tables into a sharded keyspace.

#### Dynamic Workflow Configuration

Previously, many configuration options for VReplication workflows were controlled by VTTablet flags. This meant that any
change required restarting all VTTablets. We now allow these to be overridden while creating a workflow or updated
dynamically once the workflow is in progress.

### Throttler: multi-metric support

The tablet throttler has been redesigned
with [new multi-metric support](https://vitess.io/docs/21.0/reference/features/tablet-throttler/). With this, the
throttler now handles more than just replication lag or custom queries, but instead can work with multiple metrics at
the same time, and check for different metrics for different clients or for different workflows. This gives users better
control over the throttler allowing them to fine-tune its behavior based on their specific production requirements.

Several new metrics have been introduced in v21, with plans to expand the list of available metrics in later versions.

The multi-metric throttler in v21 is backward compatible with the v20 throttler. It is possible to have a v20 primary
tablet collecting throttler data from a v21 replica tablet, and vice versa. This backward compatibility will be removed
in v22, where all tablet throttlers will be expected to communicate multi-metric data.

Other key throttler changes:

* With the above, the sub-flags `--check-as-check-self` and `--check-as-check-shard` to
  the `UpdateThrottlerConfig` command are deprecated and slated to be removed in a future version. \
  Similarly, `SHOW VITESS_THROTTLER STATUS` and `SHOW VITESS_THROTTLED_APPS` queries, and all `/throttler/` 
API access points (with the exception of `/throttler/check`) are deprecated and slated to be removed in v22.
* When enabled, the throttler ensures it leases heartbeat updates, even if heartbeat configuration is otherwise unset.
  In other words, the throttler overrides the configuration when it requires heartbeat information.
* Throttler check response now includes a human readable summary detailing exactly why a request was rejected (if
  rejected).

### Online DDL

Several bug fixes and improvements, including:

* Added support for the `ALTER VITESS_MIGRATION CLEANUP ALL` command.
* More `INSTANT` DDL scenario analysis, going further beyond the documented limitations.
* In schema changes where columns change charsets, Online DDL now converts the text programmatically rather than using
  a `CONVERT(... USING utf8mb4)` clause, thereby improving performance when such columns are part of the Primary Key
  or the iteration key.
* Internally, more of the schema and diff analysis is now delegated to `schemadiff` library, which means more
  programmatic power and better testability.
* Fixes for self-referencing foreign key tables (only relevant when using the PlanetScale MySQL build).

### Backup & restore

Introducing an experimental [mysqlshell engine](https://vitess.io/docs/21.0/user-guides/operating-vitess/backup-and-restore/creating-a-backup/#using-mysqlshell-experimental). With this engine it is possible to run logical backups and restores. The mysqlshell engine can be used to create
full backups, incremental backups and point in time recoveries. It is also available to use with the Vitess Kubernetes
Operator.

The **mysqlshell** engine work was contributed by the Slack engineering team.

### VExplain Enhancements

#### VExplain Trace

The new **vexplain trace** command provides deeper insights into query execution paths by capturing
detailed execution traces. This helps developers and DBAs analyze performance bottlenecks, review query plans, and gain
visibility into how Vitess processes queries across distributed nodes. The trace output is delivered as a JSON object,
making it easy to integrate with external analysis tools.

#### VExplain Keys

The new **vexplain keys** feature helps you analyze how your queries interact with your schema,
showing which columns are used in filters, groupings, and joins across tables. This tool is especially useful for
identifying candidate columns for indexing, sharding, or optimization, whether you’re using Vitess or a standalone MySQL
setup. By providing a clear view of column usage, **vexplain keys** makes it easier to
fine-tune your database for better performance, regardless of your backend infrastructure.

### Vitess Kubernetes Operator

Vitess v21.0.0 comes with a companion release of
the [vitess-operator v2.14.0](https://github.com/planetscale/vitess-operator/releases/tag/v2.14.0). In v2.14 we have
added the ability to horizontally scale the VTGate deployment using an HPA. We have upgraded the supported version of
Kubernetes to the latest version (v1.31). We have added a feature that allows users to select Docker images on a
per-keyspace basis instead of a single setting for the entire cluster.

### VTAdmin

New VTAdmin pages have been added for creating, monitoring and managing VReplication Workflows. We have also added a
dashboard to view and conclude distributed transactions.

## Vitess and the Community

As an open-source project, Vitess thrives on the contributions, insights, and feedback from the community. Your
experiences and input are invaluable in shaping the future of Vitess. We encourage you to share your stories and ask
questions, on [GitHub](https://github.com/vitessio/vitess) or in our [Slack community](http://vitess.io/slack).

## Getting Started

For a seamless transition to [Vitess 21](https://github.com/vitessio/vitess/releases/tag/v21.0.0), we highly recommend
reviewing the [detailed release notes](https://github.com/vitessio/vitess/tree/main/changelog/21.0). Additionally, you
can explore our documentation for guides, best practices, and tips to make the most of Vitess 21. Whether you're
upgrading from a previous version or running Vitess for the first time, our resources are designed to support you every
step of the way.

Thank you for your support and contributions to the Vitess project!


---

*The Vitess Maintainer Team*
