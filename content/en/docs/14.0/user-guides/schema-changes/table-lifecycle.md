---
title: Table lifecycle
weight: 5
aliases: ['/docs/user-guides/table-lifecycle/','/docs/reference/table-lifecycle/', 'docs/reference/features/table-lifecycle/']
---

Vitess manages a table lifecycle flow, an abstraction and automation for a `DROP TABLE` operation.

## Problems with DROP TABLE

Vitess inherits the same issues that MySQL has with `DROP TABLE`.  Doing a direct
`DROP TABLE my_table` in production can be a risky operation. In busy environments
this can lead to a complete lockdown of the database for the duration of seconds,
to minutes and more. This is typically less of a problem in Vitess than it might
be in normal MySQL, if you are keeping your shard instances (and thus shard
table instances) small, but could still be a problem.

{{< info >}}MySQL 8.0.23 addresses the issues of DROP TABLE. Vitess changes its course of action based on the MySQL version, see below.{{< /info >}}


There are two locking aspects to dropping tables:

- Purging dropped table's pages from the InnoDB buffer pool(s)
- Removing table's data file (`.ibd`) from the filesystem.

The exact locking behavior and duration can vary depending on
various factors:

- Which filesystem is used
- Whether the MySQL adaptive hash index is used
- Whether you are attempting to hack around some of the MySQL `DROP TABLE`
  performance problems using hard links

It is common practice to avoid direct `DROP TABLE` statements and to follow
a more elaborate table lifecycle.

## Vitess table lifecycle

The lifecycle offered by Vitess consists of the following stages or some subset:

> _in use_ -> hold -> purge -> evac -> drop -> _removed_

To understand the flow better, consider the following breakdown:

- _In use_: the table is serving traffic, like a normal table.
- `hold`: the table is renamed to some arbitrary new name. The application cannot see it, and considers it as gone. However, the table still exists, with all of its data intact. It is possible to reinstate it (e.g. in case we realize some application still requires it) by renaming it back to its original name.
- `purge`: the table is in the process of being purged (i.e. rows are being deleted). The purge process completes when the table is completely empty. At the end of the purge process the table no longer has any pages in the buffer pool(s). However, the purge process itself loads the table pages to cache in order to delete rows.
  Vitess purges the table a few rows at a time, and uses a throttling mechanism to reduce load.
  Vitess disables binary logging for the purge. The deletes are not written to the binary logs and are not replicated. This reduces load from disk IO, network, and replication lag. Data is not purged on the replicas.
  Experience shows that dropping a table populated with data on a replica has lower performance impact than on the primary, and the tradeoff is worthwhile.
- `evac`: a waiting period during which we expect normal production traffic to slowly evacuate the (now inactive) table's pages from the buffer pool. Vitess hard codes this period for `72` hours. The time is heuristic, there is no tracking of table pages in the buffer pool.
- `drop`: an actual `DROP TABLE` is imminent
- _removed_: table is dropped. When using InnoDB and `innodb_file_per_table` this means the `.ibd` data file backing the table is removed, and disk space is reclaimed.

## Lifecycle subsets and configuration

Different environments and users have different requirements and workflows. For example:

- Some wish to immediately start purging the table, wait for pages to evacuate, then drop it.
- Some want to keep the table's data for a few days, then directly drop it.
- Some just wish to directly drop the table, they see no locking issues (e.g. smaller table).

Vitess supports all subsets via `-table_gc_lifecycle` flag to `vttablet`. The default is `"hold,purge,evac,drop"` (the complete cycle). Users may configure any subset, e.g. `"purge,drop"`, `"hold,drop"`, `"hold,evac,drop"` or even just `"drop"`.

Vitess will always work the steps in this order: `hold -> purge -> evac -> drop`. For example, setting `-table_gc_lifecycle "drop,hold"` still first _holds_, then _drops_

All subsets end with a `drop`, even if not explicitly mentioned. Thus, `"purge"` is interpreted as `"purge,drop"`.

In MySQL **8.0.23** and later, table drops do not acquire locks on the InnoDB buffer pool, and are non-blocking for queries that do not reference the table being dropped. Vitess automatically identifies whether the underlying MySQL server is at that version or later and will:

- Implicitly skip `purge` state, even if defined
- Implicitly skip `hold` state, even if defined

## Stateless flow by table name hints

Vitess does not track the state of the table lifecycle. The process is stateless thanks to an encoding scheme in the table names. Examples:

- The table `_vt_HOLD_6ace8bcef73211ea87e9f875a4d24e90_20210915120000` is held until `2021-09-15 12:00:00`. The data remains intact.
- The table `_vt_PURGE_6ace8bcef73211ea87e9f875a4d24e90_20210915123000` is at the state where it is being purged, or queued to be purged. Once it's fully purged (zero rows remain), it transitions to the next stage.
- The table `_vt_EVAC_6ace8bcef73211ea87e9f875a4d24e90_20210918093000` is held until `2021-09-18 09:30:00`
- The table `_vt_DROP_6ace8bcef73211ea87e9f875a4d24e90_20210921170000` is eligible to be dropped on `2021-09-21 17:00:00`

## Automated lifecycle

Vitess internally uses the above table lifecycle for [online, managed schema migrations](../../../user-guides/schema-changes/managed-online-schema-changes/). Online schema migration tools `gh-ost` and `pt-online-schema-change` create artifact tables or end with leftover tables: Vitess automatically collects those tables. The artifact or leftover tables are immediate moved to `purge` state. Depending on `-table_gc_lifecycle`, they may spend time in this state, getting purged, or immediately transitioned to the next state.

## User-facing DROP TABLE lifecycle

When using an online `ddl_strategy`, a `DROP TABLE` is a [managed schema migration](../../../user-guides/schema-changes/managed-online-schema-changes/). It is internally replaced by a `RENAME TABLE` statement, renaming it into a `HOLD` state (e.g. `_vt_HOLD_6ace8bcef73211ea87e9f875a4d24e90_20210915120000`). It will then participate in the table lifecycle mechanism. If `table_gc_lifecycle` does not include the `hold` state, the table proceeds to transition to next included state. 

A multi-table `DROP TABLE` statement is converted to multiple single-table `DROP TABLE` statements, each to then convert to a `RENAME TABLE` statement.
