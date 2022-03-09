---
title: Revertible migrations
weight: 14
aliases: ['/docs/user-guides/schema-changes/revertible-migrations/']
---

Vitess's [managed schema changes](../managed-online-schema-changes/) offer _lossless revert_ for online schema migrations: the user may regret a table migration after completion, and roll back the table's schema to previous state _without loss of data_.

Revertible migrations supported for:

- `CREATE TABLE` statements: the _revert_ is to _uncreate_ the table
- `DROP TABLE` statements: the _revert_ is to _reinstate_ the table, populated with data from time of `DROP`
- `ALTER TABLE` statements: supported in `vitess` strategy, the _revert_ is to reapply previous table schema, without losing any data added/modified since migration completion.
- Another `revert` migration. It is possible to revert a _revert_, revert the revert of a _revert_, and so forth.

## Behavior and limitations

- A revert is a migration of its own, with a migration UUID, similarly to "normal" migrations.
- Migrations are only for revertible for `24h` since completion.
- It's only possible to revert the last successful migration on a given table. Illustrated following.
  - In the future it may be possible to revert down the stack of completed migrations.
- `ALTER` migrations are revertible only in `vitess` strategy.
- If a DDL is a noop, then so is its revert:
  - If a table `t` exists, and an online DDL is `CREATE TABLE IF NOT EXISTS t (...)`, then the DDL does nothing, and its revert will do nothing.
  - If a table `t` does not exist, and an online DDL is `DROP TABLE IF EXISTS t`, then likewise the DDL does nothing, and its revert does nothing.
- Some `ALTER` reverts are not guaranteed to succeed. Examples:
  - An `ALTER` which modifies column `i` from `int` to `bigint`, followed by an `INSERT` that places a value larger than max `int`, cannot be reverted, because Vitess cannot place that new value in the old schema.
  - An `ALTER` which removes a `UNIQUE KEY`, followed by an `INSERT` that populates a duplicate value on some column, may not be reverted if that duplicate violates the removed `UNIQUE` constraint.
  
  Vitess cannot know ahead of time whether a _revert_ is possible or not.

## REVERT syntax

Via SQL:

```sql
REVERT VITESS_MIGRATION '69b17887_8a62_11eb_badd_f875a4d24e90';
```

{{< warning >}}
As of Vitess 12.0 `vtctl OnlineDDL revert` is deprecated. Use the `REVERT VITESS_MIGRATION '...' ` SQL command either via `vtctl ApplySchema` or via `vtgate`.
{{< /warning >}}

Via `vtctl`:
```shell
$ vtctlclient OnlineDDL commerce revert 69b17887_8a62_11eb_badd_f875a4d24e90
```

Both operations return a UUID for the revert migration. The user can track the revert migration to find its state.

## Usage & walkthrough

Consider the following annotated flow:
```sql
mysql> set @@ddl_strategy='vitess';

mysql> create table t(id int primary key);
+--------------------------------------+
| uuid                                 |
+--------------------------------------+
| 3837e739_8a60_11eb_badd_f875a4d24e90 |
+--------------------------------------+
-- Wait until migration is complete

mysql> alter table t add column ts timestamp not null default current_timestamp;
+--------------------------------------+
| uuid                                 |
+--------------------------------------+
| 6bc591b2_8a60_11eb_badd_f875a4d24e90 |
+--------------------------------------+
-- Wait until migration is complete

mysql> show create table t \G
*************************** 1. row ***************************
       Table: t
Create Table: CREATE TABLE `t` (
  `id` int(11) NOT NULL,
  `ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8

-- it is now possible to revert 6bc591b2_8a60_11eb_badd_f875a4d24e90, because it was the last successful migration on table t.
-- it is not possible to revert 3837e739_8a60_11eb_badd_f875a4d24e90, because while it was successful, it is not the last
-- successful migration to run on table t t.

mysql> revert vitess_migration '6bc591b2_8a60_11eb_badd_f875a4d24e90';
+--------------------------------------+
| uuid                                 |
+--------------------------------------+
| ead67f31_8a60_11eb_badd_f875a4d24e90 |
+--------------------------------------+
-- Wait until migration is complete

mysql> show create table t \G
*************************** 1. row ***************************
       Table: t
Create Table: CREATE TABLE `t` (
  `id` int(11) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8

-- It is now possible to revert ead67f31_8a60_11eb_badd_f875a4d24e90 as it is the last successful migration to run on table t.
-- Reverting ead67f31_8a60_11eb_badd_f875a4d24e90 affectively means restoring the changes made by 6bc591b2_8a60_11eb_badd_f875a4d24e90

mysql> revert vitess_migration 'ead67f31_8a60_11eb_badd_f875a4d24e90';
+--------------------------------------+
| uuid                                 |
+--------------------------------------+
| 3b99f686_8a61_11eb_badd_f875a4d24e90 |
+--------------------------------------+
-- Wait until migration is complete

mysql> show create table t \G
*************************** 1. row ***************************
       Table: t
Create Table: CREATE TABLE `t` (
  `id` int(11) NOT NULL,
  `ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8

-- Let's try an invalid migration:
+--------------------------------------+
| uuid                                 |
+--------------------------------------+
| 7fbdf1c7_8a61_11eb_badd_f875a4d24e90 |
+--------------------------------------+
-- This will fail because column `id` already exists.

                 id: 11
     migration_uuid: 7fbdf1c7_8a61_11eb_badd_f875a4d24e90
           keyspace: commerce
              shard: 0
       mysql_schema: vt_commerce
        mysql_table: t
migration_statement: alter table t add column id bigint
           strategy: vitess
            options: 
    added_timestamp: 2021-03-21 18:21:36
requested_timestamp: 2021-03-21 18:21:32
    ready_timestamp: 2021-03-21 18:21:36
  started_timestamp: 2021-03-21 18:21:36
 liveness_timestamp: 2021-03-21 18:21:36
completed_timestamp: NULL
  cleanup_timestamp: NULL
   migration_status: failed
...
         ddl_action: alter
            message: Duplicate column name 'id' (errno 1060) (sqlstate 42S21) during query: ALTER TABLE `_7fbdf1c7_8a61_11eb_badd_f875a4d24e90_20210321182136_vrepl` add column id bigint
...

-- it is impossible to revert 7fbdf1c7_8a61_11eb_badd_f875a4d24e90 because it failed.

+--------------------------------------+
| uuid                                 |
+--------------------------------------+
| c3dff91a_8a61_11eb_badd_f875a4d24e90 |
+--------------------------------------+

mysql> show vitess_migrations like 'c3dff91a_8a61_11eb_badd_f875a4d24e90' \G
*************************** 1. row ***************************
                 id: 12
     migration_uuid: c3dff91a_8a61_11eb_badd_f875a4d24e90
           keyspace: commerce
              shard: 0
       mysql_schema: vt_commerce
        mysql_table: 
migration_statement: revert 7fbdf1c7_8a61_11eb_badd_f875a4d24e90
           strategy: vitess
            options: 
    added_timestamp: 2021-03-21 18:23:31
requested_timestamp: 2021-03-21 18:23:26
    ready_timestamp: 2021-03-21 18:23:36
  started_timestamp: NULL
 liveness_timestamp: NULL
completed_timestamp: NULL
  cleanup_timestamp: NULL
   migration_status: failed
...
         ddl_action: revert
            message: can only revert a migration in a 'complete' state. Migration 7fbdf1c7_8a61_11eb_badd_f875a4d24e90 is in 'failed' state
...

mysql> insert into t values (1, now());

mysql> select * from t;
+----+---------------------+
| id | ts                  |
+----+---------------------+
|  1 | 2021-03-21 18:26:47 |
+----+---------------------+

mysql> drop table t;
+--------------------------------------+
| uuid                                 |
+--------------------------------------+
| 69b17887_8a62_11eb_badd_f875a4d24e90 |
+--------------------------------------+
-- Wait until migration is complete

mysql> select * from t;
ERROR 1146 (42S02): ... 

mysql> revert vitess_migration '69b17887_8a62_11eb_badd_f875a4d24e90';
+--------------------------------------+
| uuid                                 |
+--------------------------------------+
| 9eb00275_8a62_11eb_badd_f875a4d24e90 |
+--------------------------------------+
-- Wait until migration is complete
-- `t` was not really dropped, but renamed away. This REVERT reinstates it.

mysql> select * from t;
+----+---------------------+
| id | ts                  |
+----+---------------------+
|  1 | 2021-03-21 18:26:47 |
+----+---------------------+
```

## Implementation details

Revert for `CREATE` and `DROP` are implemented similarly for all online strategies.

- The revert for a `CREATE` DDL is to rename the table away and into a [table lifecycle](../table-lifecycle/) name, rather than actually `DROP` it. This keeps th etale safe for a period of time, and makes it possible to reinstate the table, populated with all data, via a 2nd revert.
- The revert for a `DROP` relies on the fact that Online DDL `DROP TABLE` does not, in fact, drop the table, but actually rename it away. Thus, reverting the `DROP` is merely a `RENAME` back into its original place.
- The revert for `ALTER` is only available for `vitess` strategy (formerly called `online`), implemented by `VReplication`. VReplication keep track of a DDL migration by writing down the GTID position through the migration flow. In particular, at time of cut-over and when tables are swapped, VReplication notes the _final_ GTID pos for the migration.
  When a revert is requested, Vitess computes a new VReplication rule/filter for the new stream. It them copies the _final_ GTID pos from the reverted migration, and instructs VReplication to resume from that point.
  As result, a revert for an `ALTER` migration only needs to catch up with the changelog (binary log entries) since the cut-over of the original migration. To elaborate, it does not need to copy table data, and only needs to consider events for the specific table affected by the revert. This makes the revert operation efficient.
