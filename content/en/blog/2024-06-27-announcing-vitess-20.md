---
author: 'Vitess Maintainer Team'
date: 2024-06-27
slug: '2024-06-27-announcing-vitess-20'
tags: ['release', 'Vitess', 'v20', 'MySQL', 'kubernetes', 'operator', 'vreplication', 'multi-tenancy', 'Usability', 'Online DDL']
title: 'Announcing Vitess 20'
description: "Vitess 20 is now Generally Available"
---


## Announcing Vitess 20

We're delighted to announce the release of [Vitess 20](https://github.com/vitessio/vitess/releases/tag/v20.0.0) along with [version 2.13.0](https://github.com/planetscale/vitess-operator/releases/tag/v2.13.0) of the Vitess Kubernetes Operator.

Version 20 focuses on usability and maturity of existing features, and continues to build on the solid foundation of scalability and performance established in previous versions. Our commitment remains steadfast in providing a powerful, scalable, and reliable solution for your database scaling needs.

## What's New in Vitess 20

- **Query Compatibility**: enhanced DML support including improved query compatibility, Vindex hints, and extended support for various sharded `update` and `delete` operations.
- **VReplication**: multi-tenant imports (experimental).
- **Online DDL**: improved support for various schema change scenarios, dropping support for `gh-ost`.
- **Vitess Operator**: automated and scheduled backups.

## Dive Deeper

Let’s look into some key highlights of this release.

### Query Compatibility

The latest Vitess release enhances DML support with features like Vindex hints, sharded updates with limits, multi-table updates, and advanced delete operations. 

Vindex hints enable users to influence shard routing:

```sql
SELECT * FROM user USE VINDEX (hash_user_id, secondary_vindex) WHERE user_id = 123;
SELECT * FROM order IGNORE VINDEX (range_order_id) WHERE order_date = '2021-01-01';
```

Sharded updates with limits are now supported:

```sql
UPDATE t1 SET t1.foo = 'abc', t1.bar = 23 WHERE t1.baz > 5 LIMIT 1;
```

Multi-table updates and multi-target updates enhance flexibility:

```sql
UPDATE t1 JOIN t2 ON t1.id = t2.id JOIN t3 ON t1.col = t3.col SET t1.baz = 'abc', t1.apa = 23 WHERE t3.foo = 5 AND t2.bar = 7;
UPDATE t1 JOIN t2 ON t1.id = t2.id SET t1.foo = 'abc', t2.bar = 23;
```

Advanced delete operations with subqueries and multi-target support are included:

```sql
DELETE FROM t1 WHERE id IN (SELECT col FROM t2 WHERE foo = 32 AND bar = 43);
DELETE t1, t3 FROM t1 JOIN t2 ON t1.id = t2.id JOIN t3 ON t1.col = t3.col;
```

These features provide greater control and efficiency for managing sharded data. For more details, please refer to the Vitess and MySQL documentation.

### VReplication: Multi-tenant Imports (experimental)

Many web-scale applications use a multi-tenant architecture where each tenant has their own database (with identical schemas). There are several challenges with this approach like provisioning and scaling potentially tens of thousands of databases, and uniformly updating database schemas across them.

A sharded Vitess cluster is a great option for such a system with a single logical database serving all tenants. Vitess 20 adds support for importing data from such a multi-tenant cluster into a single Vitess Cluster, with new options to the MoveTables workflow. You would run one such workflow for each tenant, with imported tenants being served by the Vitess cluster.

### Online DDL

Vitess migrations now support `enum` definition reordering. Vitess opts to use `enum`s by alias (their string representation) rather than by ordinal value (the internal integer representation).

Vitess now has better analysis for `INSTANT` DDL scenarios, enabled with the `--prefer-instant-ddl` DDL [strategy flag](https://vitess.io/docs/20.0/user-guides/schema-changes/ddl-strategy-flags/). It is able to predict whether a migration can be fulfilled by the `INSTANT` algorithm and use this algorithm if so.

It also improves support for range partitioning migrations, and opts to use direct partitioning queries over Online DDL where appropriate.

VDiffs can now be run on Online DDL Workflows which are still in progress (i.e. not yet cut-over).

Release 20.0 drops support for `gh-ost` for Online DDL, as we continue to invest in `vitess` migrations based on VReplication. The `gh-ost` strategy is still recognized; however:

- Vttablet binaries no longer bundle the `gh-ost` binary. The user should provide their own `gh-ost` binary, and supply `vttablet --gh-ost-path`.
- Vitess no longer tests `gh-ost` in CI/endtoend tests.

### Vitess-operator

Automated and scheduled backups are now available as an experimental feature in v2.13.0. The getting started guide contains a [new guide](https://vitess.io/docs/20.0/user-guides/operating-vitess/backup-and-restore/scheduled-backups/) to learn how to use this new feature.

## Vitess and the Community

As an open-source project, Vitess thrives on the contributions, insights, and feedback from the community. Your experiences and input are invaluable in shaping the future of Vitess. We encourage you to share your stories and ask questions, on [GitHub](https://github.com/vitessio/vitess) or in our [Slack channel](http://vitess.io/slack).

## Getting Started

For a seamless transition to [Vitess 20](https://github.com/vitessio/vitess/releases/tag/v20.0.0), we highly recommend reviewing the [detailed release notes](https://github.com/vitessio/vitess/blob/main/changelog/20.0/20.0.0/release_notes.md). Additionally, explore [our documentation](https://vitess.io/docs/20.0/) for guides, best practices, and tips to make the most of Vitess 20. Whether you're upgrading from a previous version or integrating Vitess for the first time, our resources are designed to support you every step of the way.

Thank you for your support and contributions to the Vitess project!

---

_The Vitess Team_
