---
title: Making Schema Changes
description:
weight: 11
aliases: ['/docs/schema-management/mysql-schema/', '/docs/user-guides/mysql-schema/', '/docs/user-guides/making-schema-changes/', '/docs/schema-management/schema-changes/', '/docs/user-guides/schema-changes/']
---

This user guide describes the problem space of schema changes and the various approaches you may use with Vitess.

Quick links:

- Vitess supports [managed, online schema changes](../schema-changes/managed-online-schema-changes/) using different [strategies](../schema-changes/ddl-strategies/), and with visibility and control over the migration process
- Multiple approaches to [unmanaged schema changes](../schema-changes/unmanaged-schema-changes/), either blocking, or owned by the user/DBA.

{{< info >}}
It is recommended to use Vitess' managed, online schema changes.
{{< /info >}}

Some background on schema changes follows.

## The schema change problem

Schema change is one of the oldest problems in MySQL and in the relational world in general. With accelerated development and deployment flows, engineers find they need to deploy schema changes sometimes on a daily basis. With the growth of data this task becomes more and more difficult. A direct MySQL `ALTER TABLE` statement is a blocking (no reads nor writes are possible on the migrated table) and resource heavy operation; variants of `ALTER TABLE` include `InnoDB` [Online DDL](https://dev.mysql.com/doc/refman/8.0/en/innodb-online-ddl-operations.html), which allows for some concurrency on a `primary` server, but still blocking on replicas, leading to unacceptable replication lags once the statement hits the replicas. 

MySQL's [Instant DDL](https://dev.mysql.com/doc/refman/8.0/en/innodb-online-ddl-operations.html) brings a much better experience where supported migrations run instantly and without additional load. Where possible, these are generally desired.

`ALTER TABLE` (non-`INSTANT`) operations are greedy, consume as much CPU/Disk IO as needed, are uninterruptible and uncontrollable. Once the operation has begun, it must run to completion; aborting an `ALTER TABLE` may be more expensive than letting it run through, depending on the progress the migration has made.

Such direct `ALTER TABLE` is fine in development or possibly staging environments, where datasets are either small, or where table locking is acceptable.

## ALTER TABLE solutions

Busy production systems tend to use either of these two approaches, to make schema changes less disruptive to ongoing production traffic:

- Using general purpose online schema change tools, such as [gh-ost](https://github.com/github/gh-ost) and [pt-online-schema-change](https://www.percona.com/doc/percona-toolkit/3.0/pt-online-schema-change.html). These tools _emulate_ an `ALTER TABLE` statement by creating a _ghost_ table in the new desired format, and slowly working through copying data from the existing table, while also applying ongoing changes throughout the migration.
  - Vitess offers a built in online schema change flow based on VReplication, and additionally supports `gh-ost` and `pt-online-schema-change`.
  - Online schema change tools can be throttled on high load, and can be interrupted at will.
- Run the migration independently on replicas; when all replicas have the new schema, demote the `primary` and promote a `replica` as the new `primary`; then, at leisure, run the migration on the demoted server. Two considerations if using this approach are:
  - Each migration requires a failover (aka _successover_, aka _planned reparent_).
  - Total wall clock time is higher since we run the same migration in sequence on different servers.

## Schema change cycle and operation

The cycle of schema changes, from idea to production, is complex, involves multiple environments and possibly multiple teams. Below is one possible breakdown common in production. Notice how even interacting with the database itself takes multiple steps:

1. Design: the developer designs a change, tests locally
2. Publish: the developer requests a review of their changes (e.g. on a Pull Request)
3. Review: developer's colleagues and database engineers to check the changes and their impact
4. Formalize: what is the precise `ALTER TABLE` statement to be executed? If running with `gh-ost` or `pt-online-schema-change`, what are the precise command line flags?
5. Locate: where does this change need to go? Which keyspace/cluster? Is this cluster sharded? What are the shards?
  Having located the affected MySQL clusters, which is the `primary` server per cluster?
6. Schedule: is there an already running migration on the relevant keyspace/cluster(s)?
7. Execute: invoke the command. In the time we waited, did the identity of `primary` servers change?
8. Audit/control: is the migration in progress? Do we need to abort for some reason?
9. Cut-over/complete: a potential manual step to complete the migration process
10. Cleanup: what do you do with the old tables? An immediate `DROP` is likely not advisable. What's the alternative?
11. Notify user: let the developer know their changes are now in production.
12. Deploy & merge: the developer completes their process.

Steps `4` - `10` are tightly coupled with the database or with the infrastructure around the database.

## Schema change and Vitess

Vitess solves or automates multiple parts of the flow:

### Formalize

In [managed, online schema changes](../schema-changes/managed-online-schema-changes/) the user supplies a valid SQL `ALTER TABLE` statement, and Vitess [schedules and runs](../../../design-docs/online-ddl/scheduler/) the migration, based on a specified [strategy](../schema-changes/ddl-strategies/).

In addition, `vitess` strategy migrations offer [declarative](../schema-changes/declarative-migrations/) changes, where the user only needs to supply the desired `CREATE TABLE` or `DROP TABLE` statements, and Vitess computes the correct migration needed.

### Locate

For a given table in a given keyspace, Vitess knows at all times:

- In which shards (MySQL clusters) the table is found
- Which is the `primary` server per shard.

When using either managed schema changes, or direct schema changes via `vtctldclient` or `vtgate`, Vitess resolves the discovery of the affected servers automatically, and this is hidden from the user.

### Schedule

In managed, online schema changes, Vitess owns and tracks all pending and active migrations. Vitess schedules migrations to run, either sequentially or, where possible, [concurrently](../schema-changes/concurrent-migrations/).

### Execute

In managed, online schema changes, Vitess owns the execution of `vitess`, `gh-ost` or `pt-online-schema-change` migrations. While these run in the background, Vitess keeps track of the migration state.

In direct schema changes via `vtctldclient` or `vtgate`, Vitess issues a synchronous `ALTER TABLE` statement on the relevant shards.

### Audit/control

In managed, online schema changes, Vitess keeps track of the state of the migration. It automatically detects when the migration is complete or has failed. It will detect failure even if the tablet itself, which is running the migration, fails. Vitess allows the user to cancel a migration. If such a migration is queued by the scheduler, then it is unqueued. If it's already running, it is interrupted and aborted. Vitess allows the user to check on a migration status across the relevant shards.

### Cut-over/complete

By default, Vitess runs automated cut-overs. The migration will complete as soon as it's able to. Optionally, the user may request to [postpone](../schema-changes/postponed-migrations/) the migration's completion until an explicit `COMPLETE` command is given.

### Cleanup

Vitess automatically garbage-collects the "old" tables, artifacts of `vitess`, `gh-ost` and `pt-online-schema-change` migrations. It drops those tables in an incremental, non blocking method.

In the case of managed, online schema changes via `pt-online-schema-change`, Vitess will ensure to drop the triggers in case the tool failed to do so for whatever reason.

## The various approaches

Vitess allows a variety of approaches to schema changes, from fully automated to fully owned by the user.

- Managed, online schema changes are the preferred approach in Vitess .
- Direct, blocking ALTERs are generally impractical in production given that they can block writes for substantial lengths of time.
- User controlled migrations are allowed, and under the user's responsibility.

See breakdown in [managed, online schema changes](../schema-changes/managed-online-schema-changes/) and in [unmanaged schema changes](../schema-changes/unmanaged-schema-changes/).
