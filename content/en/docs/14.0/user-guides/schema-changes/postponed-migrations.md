---
title: Postponed migrations
weight: 12
aliases: ['/docs/user-guides/schema-changes/postponed-migrations/']
---

Postponed migrations await final cut-over until the user manually issues a completion statement.

Normally, migrations are executed by Vitess and completed automatically. For example, an `ALTER` on a large table can take hours or more to complete. Vitess automatically instates the new schema in place whenever it is satisfied that the `ALTER` is complete. Or, a `DROP` statement could wait in queue while other statements are running, only to actually execute hours later.

Some engineers wish to have more control over the cut-over time. With postponed migrations, it is possible to:

- Invoke a migration that postpones completion
- Manually `COMPLETE` a migration

This lets an engineer observe the change of schema at a point when they're comfortably at their console and prepared to take action should any issue occur.

## Postpone completion

Add `-postpone-completion` to any* (see [supported migrations](#supported-migrations)) of the online DDL strategies. Example:

```sql

mysql> set @@ddl_strategy='vitess -postpone-completion';

-- The migration is tracked, but the table won't get created
mysql> create table mytable(id int primary key);
+--------------------------------------+
| uuid                                 |
+--------------------------------------+
| a1dac193_4b86_11ec_a827_0a43f95f28a3 |
+--------------------------------------+
```

Migrations executed with `-postpone-completion` are visible on `show vitess_migrations` just as normal. They will present either as `queued`, `ready` or `running`, at the scheduler's discretion. But they will not actually make changes to affected tables. The column `postpone_completion` indicates that the migration will not auto-complete:

```sql
mysql> show vitess_migrations like 'a1dac193_4b86_11ec_a827_0a43f95f28a3' \G

                             id: 1
                 migration_uuid: a1dac193_4b86_11ec_a827_0a43f95f28a3
                       keyspace: commerce
                          shard: 0
                   mysql_schema: vt_commerce
                    mysql_table: my_table
            migration_statement: create table my_table (
	id int primary key
)
                       strategy: vitess
                        options: --postpone-completion --allow-zero-in-date
                added_timestamp: 2021-11-22 11:23:35
            requested_timestamp: 0000-00-00 00:00:00
                ready_timestamp: NULL
              started_timestamp: NULL
             liveness_timestamp: NULL
            completed_timestamp: NULL
              cleanup_timestamp: NULL
               migration_status: queued
                       log_path: 
                      artifacts: 
                        retries: 0
                         tablet: zone1-0000000100
                 tablet_failure: 0
                       progress: 0
              migration_context: vtgate:a1d8c5e0-4b86-11ec-a827-0a43f95f28a3
                     ddl_action: create
                        message: 
                    eta_seconds: -1
                    rows_copied: 0
                     table_rows: 0
              added_unique_keys: 0
            removed_unique_keys: 0
                       log_file: 
       retain_artifacts_seconds: 86400
            postpone_completion: 1
```

```sql
-- The migration is tracked, will start running when scheduler chooses, but will not cut-over
-- to replace the table with the new schema
mysql> alter table another_table add column ts timestamp not null;
+--------------------------------------+
| uuid                                 |
+--------------------------------------+
| b7d6e6fb_8a74_11eb_badd_f875a4d24e90 |
+--------------------------------------+

*************************** 1. row ***************************
                             id: 3
                 migration_uuid: 3091ef2a_4b87_11ec_a827_0a43f95f28a3
...                 
                       strategy: vitess
                        options: --postpone-completion
                added_timestamp: 2021-11-22 11:27:34
            requested_timestamp: 0000-00-00 00:00:00
                ready_timestamp: 2021-11-22 11:27:35
              started_timestamp: 2021-11-22 11:27:35
             liveness_timestamp: 2021-11-22 11:27:39
            completed_timestamp: NULL
              cleanup_timestamp: NULL
               migration_status: running
...
            postpone_completion: 1
```

## Completing a migration

Completing a postponed migration is achieved by:

```sql
mysql> alter vitess_migration 'b7d6e6fb_8a74_11eb_badd_f875a4d24e90' complete;
```

This command instructs Vitess that the migration should not kept waiting any further.
{{< info >}}
The command serves as a hint. It does not synchronously cut-over the migration. It is possible that the migration is not yet ready to cut-over (e.g. a long running `ALTER` may not be done copying all necessary data)
{{< /info >}}

After issuing the command, value of `postpone_completion` turns to `0`:

```sql
mysql> show vitess_migrations like '3091ef2a_4b87_11ec_a827_0a43f95f28a3' \G
*************************** 1. row ***************************
                             id: 3
                 migration_uuid: 3091ef2a_4b87_11ec_a827_0a43f95f28a3
...
                       strategy: vitess
                        options: --postpone-completion
                added_timestamp: 2021-11-22 11:27:34
            requested_timestamp: 0000-00-00 00:00:00
                ready_timestamp: 2021-11-22 11:27:35
              started_timestamp: 2021-11-22 11:27:35
             liveness_timestamp: 2021-11-22 11:29:32
            completed_timestamp: NULL
              cleanup_timestamp: NULL
               migration_status: running
...
            postpone_completion: 0
```

In the above the migration is still `running`. The scheduler has not determined yet that it is ready to cut-over. Continuing the example, two seconds later:
```sql
mysql> show vitess_migrations like '3091ef2a_4b87_11ec_a827_0a43f95f28a3' \G
*************************** 1. row ***************************
                             id: 3
                 migration_uuid: 3091ef2a_4b87_11ec_a827_0a43f95f28a3
...
                       strategy: vitess
                        options: --postpone-completion
                added_timestamp: 2021-11-22 11:27:34
            requested_timestamp: 0000-00-00 00:00:00
                ready_timestamp: 2021-11-22 11:27:35
              started_timestamp: 2021-11-22 11:27:35
             liveness_timestamp: 2021-11-22 11:29:32
            completed_timestamp: 2021-11-22 11:29:33
              cleanup_timestamp: NULL
               migration_status: complete
...
            postpone_completion: 0
```

## Supported migrations

Postponed completion is supported for:

- `CREATE` and `DROP` for all online strategies
- `ALTER` migrations in `vitess` (formerly known as `online`) strategy
- `ALTER` migrations in `gh-ost` strategy
- `REVERT` of any of the above, as well as further cascading `REVERT` operations

Postponed completion is not supported in:

- `direct` strategy
- `pt-osc` for `ALTER` migrations

[declarative migrations](../declarative-migrations) will remain `queued` when `-postpone-migration` is specified, until `alter vitess_migration ... complete` is issued. This is true whether the declarative migration implies an eventual `CREATE`, `DROP` or `ALTER`.

## Implementation details

The two strong cases for postponed migrations are `DROP` and log `ALTER`s. Both carry an amount of risk to production above other migrations.

Postponed `ALTER` migrations (in `vitess` and `gh-ost` strategies) are actually executed, and begin copying table data as well as track ongoing changes. But as they reach the point where cut-over is agreeable, they stall, and keep waiting until the user issues the `alter vitess_migration ... complete` statement. Assuming the user runs the statement when all data has already been copied, it is typically a matter of seconds until the migration completes and the new schema is instated.

For `CREATE` and `DROP` statements, there's no such backfill process as with `ALTER`, and the migrations are simply not scheduled, until the user issues the `complete` statement. Once the statement is issued, the migrations still need to be scheduled, and may be possibly delayed by an existing queue of migrations.
