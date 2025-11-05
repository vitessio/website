---
title: INSTANT DDL migrations
weight: 15
aliases: ['/docs/user-guides/schema-changes/instant-ddl-migrations/']
---

MySQL's [INSTANT DDL](https://dev.mysql.com/doc/refman/en/innodb-online-ddl-operations.html) is accessible in both unmanaged and managed vitess migrations.

`INSTANT` DDL refers to `ALTER TABLE ... ALGORITHM=INSTANT` which runs near-instantaneously, though some locking is still witnessed in heavy workloads. It is limited to a subset of operations. The [documentation](https://dev.mysql.com/doc/refman/en/innodb-online-ddl-operations.html) lists the general limitations but does not cover the precise range of scenarios.

A common naive approach to using `INSTANT` DDL is to optimistically attempt an `ALTER TABLE ... ALGORITHM=INSTANT`, and if that turns to be unsupported by `INSTANT` DDL, resort to standard `ALTER TABLE`.

## INSTANT DDL in unmanaged schema changes

A user may thus submit an `ALTER TABLE ... ALGORITHM=INSTANT` migration via `ApplySchema` with `direct` or `mysql` [strategies](../ddl-strategies), or plainly from their VTGate connection.

## INSTANT DDL in managed schema changes

With the `vitess` strategy, Vitess always prefers an Online DDL migration, which then allows [revertibility](../revertible-migrations). However, the `--prefer-instant-ddl` DDL strategy flag suggests to Vitess that, where possible, it should use `INSTANT` DDL.

Vitess can predict whether a schema change is eligible to `INSTANT` DDL based on the existing table schema and the requested change. It is aware of the MySQL limitations (some of which are listed in the documentation) and can devise a plan for each distinct migration. If eligible for `INSTANT` DDL, and if `--prefer-instant-ddl` is specified, Vitess will automatically add `ALGORITHM=INSTANT` to the statement. Otherwise any `ALGORITHM` directive is ignored.

If chosen to run as `INSTANT` DDL, the migration has no shadow table and is not revertible.

## Example

```sql

mysql> set @@ddl_strategy='vitess --prefer-instant-ddl';

-- The migration is tracked, but the ALTER process won't start running.
mysql> alter table corder add column name varchar(32);
+--------------------------------------+
| uuid                                 |
+--------------------------------------+
| f0070c6e_abe1_11ef_a809_b27afeff3c85 |
+--------------------------------------+
```

Migrations executed with `--prefer-instant-ddl` are visible on `show vitess_migrations` just like any other migration:


```sql
mysql> show vitess_migrations like 'f0070c6e_abe1_11ef_a809_b27afeff3c85' \G
*************************** 1. row ***************************
                             id: 1
                 migration_uuid: f0070c6e_abe1_11ef_a809_b27afeff3c85
                       keyspace: commerce
                          shard: 0
                   mysql_schema: vt_commerce
                    mysql_table: corder
            migration_statement: alter table corder add column `name` varchar(32)
                       strategy: vitess
                        options: --prefer-instant-ddl
                added_timestamp: 2024-11-26 12:33:55
            requested_timestamp: 2024-11-26 12:33:55
                ready_timestamp: NULL
              started_timestamp: 2024-11-26 12:33:57
             liveness_timestamp: 2024-11-26 12:33:57
            completed_timestamp: 2024-11-26 12:33:56.652159
              cleanup_timestamp: NULL
               migration_status: complete
                       log_path:
                      artifacts:
                        retries: 0
                         tablet: zone1-0000000101
                 tablet_failure: 0
                       progress: 100
              migration_context: vtgate:e1131b44-abe1-11ef-a809-b27afeff3c85
                     ddl_action: alter
                        message:
...
                   special_plan: {"operation":"instant-ddl"}
```

Note the migration has no `artifacts`, and that it is executed with `special_plan: {"operation":"instant-ddl"}`.

## PARTITIONING notes

MySQL partitioning changes sometimes exhibit behaviors similar to `INSTANT` DDL, although partition management really operates on entire hidden tables.

Vitess specifically addresses the common use case of [`RANGE` partitioned](https://dev.mysql.com/doc/refman/en/partitioning-management-range-list.html) tables and partition rotation.

The operation `ALTER TABLE ... ADD PARTITION` creates a new empty hidden table, which implements the new partition. The operation is as fast as `CREATE TABLE`. It is wasteful to run this operation with Online DDL because the existing data is completely unaffected. Vitess always opts to run `ADD PARTITION` directly against MySQL, much like an `INSTANT` DDL, and the operation is not revertible. This behavior is not controlled by any flags.

The operation `ALTER TABLE ... DROP PARTITION` drops one or more partitions, hence effectively drops one or more tables imlementing those partitions. It would be a logical error to run this operation with Online DDL, because the intended outcome is to drop rows of data, where an Online DDL operation would just copy those rows of data onto the next compatible partition. Vitess thus always opts to run `DROP PARTITION` directly against MySQL, and the operation is not revertible. This behavior is likewise not controlled by any flags.

Vitess does not offer any special behavior for other types of partitioning schemes and operations.