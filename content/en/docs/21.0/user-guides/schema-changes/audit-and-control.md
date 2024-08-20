---
title: Applying, auditing, and controlling Online DDL
weight: 6
aliases: ['/docs/user-guides/managed-online-schema-changes/audit-and-control']
---

Vitess provides two interfaces to interacting with Online DDL:

- SQL commands, via `VTGate`
- Command line interface, via `vtctl`

Supported interactions are:

- [Running migrations](#running-migrations) (submitting Online DDL requests)
- [Tracking migrations](#tracking-migrations)
- [Launching a migration](#launching-a-migration) or all migrations, if explicitly set to postpone launch.
- [Completing a migration](#completing-a-migration) or all migrations, if explicitly set to postpone completion.
- [Cancelling a migration](#cancelling-a-migration)
- [Cancelling a migration](#cancelling-a-migration)
- [Cancelling all pending migrations](#cancelling-all-keyspace-migrations)
- [Retrying a migration](#retrying-a-migration)
- [Cleaning migration artifacts](#cleaning-migration-artifacts)
- [Reverting a migration](#reverting-a-migration)

## Running Migrations

To run a managed schema migration, you should:

- Formulate your DDLs (`CREATE`, `ALTER`, `DROP`) queries
- Choose a [ddl_strategy](../ddl-strategies)

When the user submits an online DDL, Vitess responds with a UUID, a job Id used to later track or control the migration. The migration does not start immediately. It is queued at the tablets and executed at some point in the future.

#### Via VTGate/SQL

```sql
mysql> set @@ddl_strategy='vitess';

mysql> alter table corder add column ts timestamp not null default current_timestamp;
+--------------------------------------+
| uuid                                 |
+--------------------------------------+
| bf4598ab_8d55_11eb_815f_f875a4d24e90 |
+--------------------------------------+

mysql> drop table customer;
+--------------------------------------+
| uuid                                 |
+--------------------------------------+
| 6848c1a4_8d57_11eb_815f_f875a4d24e90 |
+--------------------------------------+
```

- `@@ddl_strategy` behaves like a MySQL session variable, though is only recognized by `VTGate`. Setting `@@ddl_strategy` only applies to that same connection and does not affect other connections. The strategy applies to all migrations executed in that session. You may subsequently set `@@ddl_strategy` to different value.
- If you run `vtgate` without `--ddl_strategy`, then `@@ddl_strategy` defaults to `'direct'`, which implies schema migrations are synchronous. You will need to `set @@ddl_strategy='vitess'` to run followup `ALTER TABLE` statements via Vitess.
- If you run `vtgate --ddl_strategy "vitess"`, then `@@ddl_strategy` defaults to `'vitess'` in each new session. Any `ALTER TABLE` will run via Vitess online DDL. You may `set @@ddl_strategy='gh-ost'` to make migrations run through `gh-ost`, or `set @@ddl_strategy='direct'` to run migrations synchronously.

#### Via vtctldclient

You may use `vtctldclient` to apply schema changes. The `ApplySchema` command supports both synchronous and online schema migrations. To run an online schema migration you will supply the `--ddl-strategy` command line flag:

```shell
$ vtctldclient ApplySchema --ddl-strategy="vitess" --sql "alter table product add column ts_entry TIMESTAMP NOT NULL" commerce
c26f3b5e_6b50_11ee_808b_0a43f95f28a3
```

 You my run multiple migrations withing the same `ApplySchema` command:
```shell
$ vtctldclient ApplySchema --ddl-strategy="vitess" --sql "alter table corder modify price bigint unsigned default null; create table sample (id int primary key); drop table if exists some_other_table" customer
d729b47e_6b52_11ee_808b_0a43f95f28a3
d72b644f_6b52_11ee_808b_0a43f95f28a3
d72d230d_6b52_11ee_808b_0a43f95f28a3
```

`ApplySchema` accepts the following flags:

- `--ddl-strategy`: by default migrations run directly via MySQL standard DDL (aka `direct`). This flag must be aupplied to indicate an online strategy. See also [DDL strategies](../ddl-strategies) and [ddl_strategy flags](../ddl-strategy-flags).
- `--migration-context <unique-value>`: all migrations in a `ApplySchema` command are logically grouped via a unique _context_. A unique value will be supplied automatically. The user may choose to supply their own value, and it's their responsibility to provide with a unique value. Any string format is accepted.
  The context can then be used to search for migrations, via `SHOW VITESS_MIGRATIONS LIKE '<the-context>'`. It is visible in `SHOW VITESS_MIGRATIONS ...` output as the `migration_context` column.

## Tracking Migrations

You may track the status of a single or of multiple migrations. Since migrations run asycnhronously, it is the user's responsibility to audit the progress and state of submitted migrations. Users are likely to want to know when a migration is complete (or failed) so as to be able to deploy code changes or run other operations.

Common patterns are:

- Show state of a specific migration
- Show all `running`, `complete` or `failed` migrations
- Show recent migrations
- Show migrations ordered by most-recent first.
- Show n number of migrations, skipping m rows.

#### Via VTGate/SQL

Examples for a single shard cluster:

```sh
$ mysql commerce
```
```sql
mysql> show vitess_migrations like 'c26f3b5e_6b50_11ee_808b_0a43f95f28a3' \G
*************************** 1. row ***************************
                             id: 1
                 migration_uuid: c26f3b5e_6b50_11ee_808b_0a43f95f28a3
                       keyspace: commerce
                          shard: 0
                   mysql_schema: vt_commerce
                    mysql_table: product
            migration_statement: alter table product add column ts_entry TIMESTAMP not null
                       strategy: vitess
                        options:
                added_timestamp: 2023-10-15 11:48:29
            requested_timestamp: 2023-10-15 11:48:30
                ready_timestamp: NULL
              started_timestamp: 2023-10-15 11:48:31
             liveness_timestamp: 2023-10-15 11:48:37
            completed_timestamp: 2023-10-15 11:48:38.232430
              cleanup_timestamp: NULL
               migration_status: complete
                       log_path:
                      artifacts: _c26f3b5e_6b50_11ee_808b_0a43f95f28a3_20231015114830_vrepl,
                        retries: 0
                         tablet: zone1-0000000100
                 tablet_failure: 0
                       progress: 100
              migration_context: vtctl:c26e658d-6b50-11ee-808b-0a43f95f28a3
                     ddl_action: alter
                        message:
                    eta_seconds: 0
                    rows_copied: 0
                     table_rows: 0
              added_unique_keys: 0
            removed_unique_keys: 0
                       log_file:
       retain_artifacts_seconds: 86400
            postpone_completion: 0
       removed_unique_key_names:
dropped_no_default_column_names:
          expanded_column_names:
               revertible_notes:
               allow_concurrent: 0
                  reverted_uuid:
                        is_view: 0
              ready_to_complete: 1
      vitess_liveness_indicator: 1697370514
            user_throttle_ratio: 0
                   special_plan:
       last_throttled_timestamp: NULL
            component_throttled:
            cancelled_timestamp: NULL
                postpone_launch: 0
                          stage: re-enabling writes
               cutover_attempts: 1
         is_immediate_operation: 0
             reviewed_timestamp: 2023-10-15 11:48:31
    ready_to_complete_timestamp: 2023-10-15 11:48:35
```

```sql
mysql> show vitess_migrations like 'complete' \G
-- same output as above

mysql> show vitess_migrations like 'failed' \G
Empty set (0.01 sec)
```

Examples for a multi sharded cluster:

```sh
$ mysql customer
```

```sql
mysql> show vitess_migrations like 'complete';
+----+--------------------------------------+----------+-------+--------------+------------------+---------------------------------------------------------------------+----------+---------+---------------------+---------------------+-----------------+---------------------+---------------------+----------------------------+-------------------+------------------+----------+-------------------------------------------------------------+---------+------------------+----------------+----------+--------------------------------------------+------------+---------+-------------+-------------+------------+-------------------+---------------------+----------+--------------------------+---------------------+--------------------------+---------------------------------+-----------------------+-------------------------------------------+------------------+---------------+---------+-------------------+---------------------------+---------------------+--------------+--------------------------+---------------------+---------------------+-----------------+--------------------+------------------+------------------------+---------------------+-----------------------------+
| id | migration_uuid                       | keyspace | shard | mysql_schema | mysql_table      | migration_statement                                                 | strategy | options | added_timestamp     | requested_timestamp | ready_timestamp | started_timestamp   | liveness_timestamp  | completed_timestamp        | cleanup_timestamp | migration_status | log_path | artifacts                                                   | retries | tablet           | tablet_failure | progress | migration_context                          | ddl_action | message | eta_seconds | rows_copied | table_rows | added_unique_keys | removed_unique_keys | log_file | retain_artifacts_seconds | postpone_completion | removed_unique_key_names | dropped_no_default_column_names | expanded_column_names | revertible_notes                          | allow_concurrent | reverted_uuid | is_view | ready_to_complete | vitess_liveness_indicator | user_throttle_ratio | special_plan | last_throttled_timestamp | component_throttled | cancelled_timestamp | postpone_launch | stage              | cutover_attempts | is_immediate_operation | reviewed_timestamp  | ready_to_complete_timestamp |
+----+--------------------------------------+----------+-------+--------------+------------------+---------------------------------------------------------------------+----------+---------+---------------------+---------------------+-----------------+---------------------+---------------------+----------------------------+-------------------+------------------+----------+-------------------------------------------------------------+---------+------------------+----------------+----------+--------------------------------------------+------------+---------+-------------+-------------+------------+-------------------+---------------------+----------+--------------------------+---------------------+--------------------------+---------------------------------+-----------------------+-------------------------------------------+------------------+---------------+---------+-------------------+---------------------------+---------------------+--------------+--------------------------+---------------------+---------------------+-----------------+--------------------+------------------+------------------------+---------------------+-----------------------------+
|  7 | d729b47e_6b52_11ee_808b_0a43f95f28a3 | customer | 80-   | vt_customer  | corder           | alter table corder modify column price bigint unsigned default null | vitess   |         | 2023-10-15 12:03:23 | 2023-10-15 12:03:24 | NULL            | 2023-10-15 12:03:25 | 2023-10-15 12:03:31 | 2023-10-15 12:03:32.012778 | NULL              | complete         |          | _d729b47e_6b52_11ee_808b_0a43f95f28a3_20231015120324_vrepl, |       0 | zone1-0000000401 |              0 |      100 | vtctl:d7288b41-6b52-11ee-808b-0a43f95f28a3 | alter      |         |           0 |           0 |          0 |                 0 |                   0 |          |                    86400 |                   0 |                          |                                 | `price`               | column price: increased NUMERIC_PRECISION |                0 |               |       0 |                 1 |                1697371408 |                   0 |              | NULL                     |                     | NULL                |               0 | re-enabling writes |                1 |                      0 | 2023-10-15 12:03:25 | 2023-10-15 12:03:29         |
|  8 | d72b644f_6b52_11ee_808b_0a43f95f28a3 | customer | 80-   | vt_customer  | sample           | create table sample (
	id int primary key
)                         | vitess   |         | 2023-10-15 12:03:23 | 2023-10-15 12:03:24 | NULL            | 2023-10-15 12:03:34 | 2023-10-15 12:03:34 | 2023-10-15 12:03:33.701212 | NULL              | complete         |          | _vt_HOLD_dd2164646b5211eeba7c0a43f95f28a3_20231016120333,   |       0 | zone1-0000000401 |              0 |      100 | vtctl:d7288b41-6b52-11ee-808b-0a43f95f28a3 | create     |         |           0 |           0 |          0 |                 0 |                   0 |          |                    86400 |                   0 |                          |                                 |                       |                                           |                0 |               |       0 |                 1 |                         0 |                   0 |              | NULL                     |                     | NULL                |               0 |                    |                0 |                      1 | 2023-10-15 12:03:25 | 2023-10-15 12:03:25         |
|  9 | d72d230d_6b52_11ee_808b_0a43f95f28a3 | customer | 80-   | vt_customer  | some_other_table | drop table if exists some_other_table                               | vitess   |         | 2023-10-15 12:03:23 | 2023-10-15 12:03:24 | NULL            | 2023-10-15 12:03:35 | 2023-10-15 12:03:35 | 2023-10-15 12:03:34.710144 | NULL              | complete         |          |                                                             |       0 | zone1-0000000401 |              0 |      100 | vtctl:d7288b41-6b52-11ee-808b-0a43f95f28a3 | drop       |         |           0 |           0 |          0 |                 0 |                   0 |          |                    86400 |                   0 |                          |                                 |                       |                                           |                0 |               |       0 |                 1 |                         0 |                   0 |              | NULL                     |                     | NULL                |               0 |                    |                0 |                      1 | 2023-10-15 12:03:25 | 2023-10-15 12:03:25         |
|  7 | d729b47e_6b52_11ee_808b_0a43f95f28a3 | customer | -80   | vt_customer  | corder           | alter table corder modify column price bigint unsigned default null | vitess   |         | 2023-10-15 12:03:23 | 2023-10-15 12:03:24 | NULL            | 2023-10-15 12:03:25 | 2023-10-15 12:03:31 | 2023-10-15 12:03:32.034889 | NULL              | complete         |          | _d729b47e_6b52_11ee_808b_0a43f95f28a3_20231015120324_vrepl, |       0 | zone1-0000000301 |              0 |      100 | vtctl:d7288b41-6b52-11ee-808b-0a43f95f28a3 | alter      |         |           0 |           0 |          0 |                 0 |                   0 |          |                    86400 |                   0 |                          |                                 | `price`               | column price: increased NUMERIC_PRECISION |                0 |               |       0 |                 1 |                1697371408 |                   0 |              | NULL                     |                     | NULL                |               0 | re-enabling writes |                1 |                      0 | 2023-10-15 12:03:25 | 2023-10-15 12:03:29         |
|  8 | d72b644f_6b52_11ee_808b_0a43f95f28a3 | customer | -80   | vt_customer  | sample           | create table sample (
	id int primary key
)                         | vitess   |         | 2023-10-15 12:03:23 | 2023-10-15 12:03:24 | NULL            | 2023-10-15 12:03:34 | 2023-10-15 12:03:34 | 2023-10-15 12:03:33.701214 | NULL              | complete         |          | _vt_HOLD_dd21768e6b5211ee86cc0a43f95f28a3_20231016120333,   |       0 | zone1-0000000301 |              0 |      100 | vtctl:d7288b41-6b52-11ee-808b-0a43f95f28a3 | create     |         |           0 |           0 |          0 |                 0 |                   0 |          |                    86400 |                   0 |                          |                                 |                       |                                           |                0 |               |       0 |                 1 |                         0 |                   0 |              | NULL                     |                     | NULL                |               0 |                    |                0 |                      1 | 2023-10-15 12:03:25 | 2023-10-15 12:03:25         |
|  9 | d72d230d_6b52_11ee_808b_0a43f95f28a3 | customer | -80   | vt_customer  | some_other_table | drop table if exists some_other_table                               | vitess   |         | 2023-10-15 12:03:23 | 2023-10-15 12:03:24 | NULL            | 2023-10-15 12:03:35 | 2023-10-15 12:03:35 | 2023-10-15 12:03:34.710280 | NULL              | complete         |          |                                                             |       0 | zone1-0000000301 |              0 |      100 | vtctl:d7288b41-6b52-11ee-808b-0a43f95f28a3 | drop       |         |           0 |           0 |          0 |                 0 |                   0 |          |                    86400 |                   0 |                          |                                 |                       |                                           |                0 |               |       0 |                 1 |                         0 |                   0 |              | NULL                     |                     | NULL                |               0 |                    |                0 |                      1 | 2023-10-15 12:03:25 | 2023-10-15 12:03:25         |
+----+--------------------------------------+----------+-------+--------------+------------------+---------------------------------------------------------------------+----------+---------+---------------------+---------------------+-----------------+---------------------+---------------------+----------------------------+-------------------+------------------+----------+-------------------------------------------------------------+---------+------------------+----------------+----------+--------------------------------------------+------------+---------+-------------+-------------+------------+-------------------+---------------------+----------+--------------------------+---------------------+--------------------------+---------------------------------+-----------------------+-------------------------------------------+------------------+---------------+---------+-------------------+---------------------------+---------------------+--------------+--------------------------+---------------------+---------------------+-----------------+--------------------+------------------+------------------------+---------------------+-----------------------------+
```
```sh
$ vtctldclient OnlineDDL show customer cancelled --limit 1
+--------------------------------------+----------+-------+--------------+-------------+--------------------------------+----------+---------+---------------------+---------------------+-----------------+-------------------+--------------------+---------------------+-------------------+-----------+----------+-----------+---------+------------------+----------------+----------+--------------------------------------------+------------+---------------------------+-------------+-------------+------------+-------------------+---------------------+----------+----------------------------+---------------------+--------------------------+---------------------------------+-----------------------+------------------+------------------+---------------+---------+-------------------+---------------------------+---------------------+--------------+--------------------------+---------------------+---------------------+-----------------+-------+------------------+------------------------+--------------------+-----------------------------+
|            migration_uuid            | keyspace | shard | mysql_schema | mysql_table |      migration_statement       | strategy | options |   added_timestamp   | requested_timestamp | ready_timestamp | started_timestamp | liveness_timestamp | completed_timestamp | cleanup_timestamp |  status   | log_path | artifacts | retries |      tablet      | tablet_failure | progress |             migration_context              | ddl_action |          message          | eta_seconds | rows_copied | table_rows | added_unique_keys | removed_unique_keys | log_file | artifact_retention_seconds | postpone_completion | removed_unique_key_names | dropped_no_default_column_names | expanded_column_names | revertible_notes | allow_concurrent | reverted_uuid | is_view | ready_to_complete | vitess_liveness_indicator | user_throttle_ratio | special_plan | last_throttled_timestamp | component_throttled | cancelled_timestamp | postpone_launch | stage | cutover_attempts | is_immediate_operation | reviewed_timestamp | ready_to_complete_timestamp |
+--------------------------------------+----------+-------+--------------+-------------+--------------------------------+----------+---------+---------------------+---------------------+-----------------+-------------------+--------------------+---------------------+-------------------+-----------+----------+-----------+---------+------------------+----------------+----------+--------------------------------------------+------------+---------------------------+-------------+-------------+------------+-------------------+---------------------+----------+----------------------------+---------------------+--------------------------+---------------------------------+-----------------------+------------------+------------------+---------------+---------+-------------------+---------------------------+---------------------+--------------+--------------------------+---------------------+---------------------+-----------------+-------+------------------+------------------------+--------------------+-----------------------------+
| c919678a_6b50_11ee_808b_0a43f95f28a3 | customer |   -80 | vt_customer  | product     | alter table product modify     | vitess   |         | 2023-10-15 11:48:41 | 2023-10-15 11:48:41 |                 |                   |                    | 2023-10-15 12:00:26 |                   | cancelled |          |           |       0 | zone1-0000000301 |                |        0 | vtctl:c91857d2-6b50-11ee-808b-0a43f95f28a3 | alter      | CANCEL ALL issued by user |          -1 |           0 |          0 |                 0 |                   0 |          |                      86400 |                     |                          |                                 |                       |                  |                  |               |         |                   |                         0 |                   0 |              |                          |                     |                     |                 |       |                0 |                        |                    |                             |
|                                      |          |       |              |             | column price bigint unsigned   |          |         |                     |                     |                 |                   |                    |                     |                   |           |          |           |         |                  |                |          |                                            |            |                           |             |             |            |                   |                     |          |                            |                     |                          |                                 |                       |                  |                  |               |         |                   |                           |                     |              |                          |                     |                     |                 |       |                  |                        |                    |                             |
|                                      |          |       |              |             | default null                   |          |         |                     |                     |                 |                   |                    |                     |                   |           |          |           |         |                  |                |          |                                            |            |                           |             |             |            |                   |                     |          |                            |                     |                          |                                 |                       |                  |                  |               |         |                   |                           |                     |              |                          |                     |                     |                 |       |                  |                        |                    |                             |
| c919678a_6b50_11ee_808b_0a43f95f28a3 | customer | 80-   | vt_customer  | product     | alter table product modify     | vitess   |         | 2023-10-15 11:48:41 | 2023-10-15 11:48:41 |                 |                   |                    | 2023-10-15 12:00:26 |                   | cancelled |          |           |       0 | zone1-0000000401 |                |        0 | vtctl:c91857d2-6b50-11ee-808b-0a43f95f28a3 | alter      | CANCEL ALL issued by user |          -1 |           0 |          0 |                 0 |                   0 |          |                      86400 |                     |                          |                                 |                       |                  |                  |               |         |                   |                         0 |                   0 |              |                          |                     |                     |                 |       |                0 |                        |                    |                             |
|                                      |          |       |              |             | column price bigint unsigned   |          |         |                     |                     |                 |                   |                    |                     |                   |           |          |           |         |                  |                |          |                                            |            |                           |             |             |            |                   |                     |          |                            |                     |                          |                                 |                       |                  |                  |               |         |                   |                           |                     |              |                          |                     |                     |                 |       |                  |                        |                    |                             |
|                                      |          |       |              |             | default null                   |          |         |                     |                     |                 |                   |                    |                     |                   |           |          |           |         |                  |                |          |                                            |            |                           |             |             |            |                   |                     |          |                            |                     |                          |                                 |                       |                  |                  |               |         |                   |                           |                     |              |                          |                     |                     |                 |       |                  |                        |                    |                             |
+--------------------------------------+----------+-------+--------------+-------------+--------------------------------+----------+---------+---------------------+---------------------+-----------------+-------------------+--------------------+---------------------+-------------------+-----------+----------+-----------+---------+------------------+----------------+----------+--------------------------------------------+------------+---------------------------+-------------+-------------+------------+-------------------+---------------------+----------+----------------------------+---------------------+--------------------------+---------------------------------+-----------------------+------------------+------------------+---------------+---------+-------------------+---------------------------+---------------------+--------------+--------------------------+---------------------+---------------------+-----------------+-------+------------------+------------------------+--------------------+-----------------------------+
```

Note in the above each migration appears twice. For example, `d729b47e_6b52_11ee_808b_0a43f95f28a3` appears once for shard `-80` and once for shard `80-`. The two migrations run independently on each shard. It is possible to coordinate a near-atomic cut-over, aka [gated cut-over](../advanced-usage/#gated-cut-over).
- `show vitess_migrations` shows the entire history of migrations.
- `show vitess_migrations like ...` filters migrations by `migration_uuid`, or `migration_context`, or `migration_status`.
- `show vitess_migrations where ...` lets the user specify arbitrary conditions.
- All commands return results for the keyspace (schema) in use.

#### Via vtctldclient

```shell
$ vtctldclient OnlineDDL show customer d729b47e_6b52_11ee_808b_0a43f95f28a3
+--------------------------------------+----------+-------+--------------+-------------+--------------------------------+----------+---------+---------------------+---------------------+-----------------+---------------------+---------------------+---------------------+-------------------+----------+----------+-------------------------------------------------------------+---------+------------------+----------------+----------+--------------------------------------------+------------+---------+-------------+-------------+------------+-------------------+---------------------+----------+----------------------------+---------------------+--------------------------+---------------------------------+-----------------------+--------------------------------+------------------+---------------+---------+-------------------+---------------------------+---------------------+--------------+--------------------------+---------------------+---------------------+-----------------+--------------------+------------------+------------------------+---------------------+-----------------------------+
|            migration_uuid            | keyspace | shard | mysql_schema | mysql_table |      migration_statement       | strategy | options |   added_timestamp   | requested_timestamp | ready_timestamp |  started_timestamp  | liveness_timestamp  | completed_timestamp | cleanup_timestamp |  status  | log_path |                          artifacts                          | retries |      tablet      | tablet_failure | progress |             migration_context              | ddl_action | message | eta_seconds | rows_copied | table_rows | added_unique_keys | removed_unique_keys | log_file | artifact_retention_seconds | postpone_completion | removed_unique_key_names | dropped_no_default_column_names | expanded_column_names |        revertible_notes        | allow_concurrent | reverted_uuid | is_view | ready_to_complete | vitess_liveness_indicator | user_throttle_ratio | special_plan | last_throttled_timestamp | component_throttled | cancelled_timestamp | postpone_launch |       stage        | cutover_attempts | is_immediate_operation | reviewed_timestamp  | ready_to_complete_timestamp |
+--------------------------------------+----------+-------+--------------+-------------+--------------------------------+----------+---------+---------------------+---------------------+-----------------+---------------------+---------------------+---------------------+-------------------+----------+----------+-------------------------------------------------------------+---------+------------------+----------------+----------+--------------------------------------------+------------+---------+-------------+-------------+------------+-------------------+---------------------+----------+----------------------------+---------------------+--------------------------+---------------------------------+-----------------------+--------------------------------+------------------+---------------+---------+-------------------+---------------------------+---------------------+--------------+--------------------------+---------------------+---------------------+-----------------+--------------------+------------------+------------------------+---------------------+-----------------------------+
| d729b47e_6b52_11ee_808b_0a43f95f28a3 | customer | 80-   | vt_customer  | corder      | alter table corder modify      | vitess   |         | 2023-10-15 12:03:23 | 2023-10-15 12:03:24 |                 | 2023-10-15 12:03:25 | 2023-10-15 12:03:31 | 2023-10-15 12:03:32 |                   | complete |          | _d729b47e_6b52_11ee_808b_0a43f95f28a3_20231015120324_vrepl, |       0 | zone1-0000000401 |                |      100 | vtctl:d7288b41-6b52-11ee-808b-0a43f95f28a3 | alter      |         |           0 |           0 |          0 |                 0 |                   0 |          |                      86400 |                     |                          |                                 | `price`               | column price: increased        |                  |               |         |                   |                1697371408 |                   0 |              |                          |                     |                     |                 | re-enabling writes |                1 |                        | 2023-10-15 12:03:25 | 2023-10-15 12:03:29         |
|                                      |          |       |              |             | column price bigint unsigned   |          |         |                     |                     |                 |                     |                     |                     |                   |          |          |                                                             |         |                  |                |          |                                            |            |         |             |             |            |                   |                     |          |                            |                     |                          |                                 |                       | NUMERIC_PRECISION              |                  |               |         |                   |                           |                     |              |                          |                     |                     |                 |                    |                  |                        |                     |                             |
|                                      |          |       |              |             | default null                   |          |         |                     |                     |                 |                     |                     |                     |                   |          |          |                                                             |         |                  |                |          |                                            |            |         |             |             |            |                   |                     |          |                            |                     |                          |                                 |                       |                                |                  |               |         |                   |                           |                     |              |                          |                     |                     |                 |                    |                  |                        |                     |                             |
| d729b47e_6b52_11ee_808b_0a43f95f28a3 | customer |   -80 | vt_customer  | corder      | alter table corder modify      | vitess   |         | 2023-10-15 12:03:23 | 2023-10-15 12:03:24 |                 | 2023-10-15 12:03:25 | 2023-10-15 12:03:31 | 2023-10-15 12:03:32 |                   | complete |          | _d729b47e_6b52_11ee_808b_0a43f95f28a3_20231015120324_vrepl, |       0 | zone1-0000000301 |                |      100 | vtctl:d7288b41-6b52-11ee-808b-0a43f95f28a3 | alter      |         |           0 |           0 |          0 |                 0 |                   0 |          |                      86400 |                     |                          |                                 | `price`               | column price: increased        |                  |               |         |                   |                1697371408 |                   0 |              |                          |                     |                     |                 | re-enabling writes |                1 |                        | 2023-10-15 12:03:25 | 2023-10-15 12:03:29         |
|                                      |          |       |              |             | column price bigint unsigned   |          |         |                     |                     |                 |                     |                     |                     |                   |          |          |                                                             |         |                  |                |          |                                            |            |         |             |             |            |                   |                     |          |                            |                     |                          |                                 |                       | NUMERIC_PRECISION              |                  |               |         |                   |                           |                     |              |                          |                     |                     |                 |                    |                  |                        |                     |                             |
|                                      |          |       |              |             | default null                   |          |         |                     |                     |                 |                     |                     |                     |                   |          |          |                                                             |         |                  |                |          |                                            |            |         |             |             |            |                   |                     |          |                            |                     |                          |                                 |                       |                                |                  |               |         |                   |                           |                     |              |                          |                     |                     |                 |                    |                  |                        |                     |                             |
+--------------------------------------+----------+-------+--------------+-------------+--------------------------------+----------+---------+---------------------+---------------------+-----------------+---------------------+---------------------+---------------------+-------------------+----------+----------+-------------------------------------------------------------+---------+------------------+----------------+----------+--------------------------------------------+------------+---------+-------------+-------------+------------+-------------------+---------------------+----------+----------------------------+---------------------+--------------------------+---------------------------------+-----------------------+--------------------------------+------------------+---------------+---------+-------------------+---------------------------+---------------------+--------------+--------------------------+---------------------+---------------------+-----------------+--------------------+------------------+------------------------+---------------------+-----------------------------+

$ vtctldclient OnlineDDL show commerce recent
+--------------------------------------+----------+-------+--------------+-------------+--------------------------------+----------+---------+---------------------+---------------------+-----------------+---------------------+---------------------+---------------------+-------------------+----------+----------+-------------------------------------------------------------+---------+------------------+----------------+----------+--------------------------------------------+------------+---------+-------------+-------------+------------+-------------------+---------------------+----------+----------------------------+---------------------+--------------------------+---------------------------------+-----------------------+------------------+------------------+---------------+---------+-------------------+---------------------------+---------------------+--------------+--------------------------+---------------------+---------------------+-----------------+--------------------+------------------+------------------------+---------------------+-----------------------------+
|            migration_uuid            | keyspace | shard | mysql_schema | mysql_table |      migration_statement       | strategy | options |   added_timestamp   | requested_timestamp | ready_timestamp |  started_timestamp  | liveness_timestamp  | completed_timestamp | cleanup_timestamp |  status  | log_path |                          artifacts                          | retries |      tablet      | tablet_failure | progress |             migration_context              | ddl_action | message | eta_seconds | rows_copied | table_rows | added_unique_keys | removed_unique_keys | log_file | artifact_retention_seconds | postpone_completion | removed_unique_key_names | dropped_no_default_column_names | expanded_column_names | revertible_notes | allow_concurrent | reverted_uuid | is_view | ready_to_complete | vitess_liveness_indicator | user_throttle_ratio | special_plan | last_throttled_timestamp | component_throttled | cancelled_timestamp | postpone_launch |       stage        | cutover_attempts | is_immediate_operation | reviewed_timestamp  | ready_to_complete_timestamp |
+--------------------------------------+----------+-------+--------------+-------------+--------------------------------+----------+---------+---------------------+---------------------+-----------------+---------------------+---------------------+---------------------+-------------------+----------+----------+-------------------------------------------------------------+---------+------------------+----------------+----------+--------------------------------------------+------------+---------+-------------+-------------+------------+-------------------+---------------------+----------+----------------------------+---------------------+--------------------------+---------------------------------+-----------------------+------------------+------------------+---------------+---------+-------------------+---------------------------+---------------------+--------------+--------------------------+---------------------+---------------------+-----------------+--------------------+------------------+------------------------+---------------------+-----------------------------+
| c26f3b5e_6b50_11ee_808b_0a43f95f28a3 | commerce |     0 | vt_commerce  | product     | alter table product add column | vitess   |         | 2023-10-15 11:48:29 | 2023-10-15 11:48:30 |                 | 2023-10-15 11:48:31 | 2023-10-15 11:48:37 | 2023-10-15 11:48:38 |                   | complete |          | _c26f3b5e_6b50_11ee_808b_0a43f95f28a3_20231015114830_vrepl, |       0 | zone1-0000000100 |                |      100 | vtctl:c26e658d-6b50-11ee-808b-0a43f95f28a3 | alter      |         |           0 |           0 |          0 |                 0 |                   0 |          |                      86400 |                     |                          |                                 |                       |                  |                  |               |         |                   |                1697370514 |                   0 |              |                          |                     |                     |                 | re-enabling writes |                1 |                        | 2023-10-15 11:48:31 | 2023-10-15 11:48:35         |
|                                      |          |       |              |             | ts_entry TIMESTAMP not null    |          |         |                     |                     |                 |                     |                     |                     |                   |          |          |                                                             |         |                  |                |          |                                            |            |         |             |             |            |                   |                     |          |                            |                     |                          |                                 |                       |                  |                  |               |         |                   |                           |                     |              |                          |                     |                     |                 |                    |                  |                        |                     |                             |
+--------------------------------------+----------+-------+--------------+-------------+--------------------------------+----------+---------+---------------------+---------------------+-----------------+---------------------+---------------------+---------------------+-------------------+----------+----------+-------------------------------------------------------------+---------+------------------+----------------+----------+--------------------------------------------+------------+---------+-------------+-------------+------------+-------------------+---------------------+----------+----------------------------+---------------------+--------------------------+---------------------------------+-----------------------+------------------+------------------+---------------+---------+-------------------+---------------------------+---------------------+--------------+--------------------------+---------------------+---------------------+-----------------+--------------------+------------------+------------------------+---------------------+-----------------------------+

$ vtctldclient OnlineDDL show customer cancelled --limit 1
+--------------------------------------+----------+-------+--------------+-------------+--------------------------------+----------+---------+---------------------+---------------------+-----------------+-------------------+--------------------+---------------------+-------------------+-----------+----------+-----------+---------+------------------+----------------+----------+--------------------------------------------+------------+---------------------------+-------------+-------------+------------+-------------------+---------------------+----------+----------------------------+---------------------+--------------------------+---------------------------------+-----------------------+------------------+------------------+---------------+---------+-------------------+---------------------------+---------------------+--------------+--------------------------+---------------------+---------------------+-----------------+-------+------------------+------------------------+--------------------+-----------------------------+
|            migration_uuid            | keyspace | shard | mysql_schema | mysql_table |      migration_statement       | strategy | options |   added_timestamp   | requested_timestamp | ready_timestamp | started_timestamp | liveness_timestamp | completed_timestamp | cleanup_timestamp |  status   | log_path | artifacts | retries |      tablet      | tablet_failure | progress |             migration_context              | ddl_action |          message          | eta_seconds | rows_copied | table_rows | added_unique_keys | removed_unique_keys | log_file | artifact_retention_seconds | postpone_completion | removed_unique_key_names | dropped_no_default_column_names | expanded_column_names | revertible_notes | allow_concurrent | reverted_uuid | is_view | ready_to_complete | vitess_liveness_indicator | user_throttle_ratio | special_plan | last_throttled_timestamp | component_throttled | cancelled_timestamp | postpone_launch | stage | cutover_attempts | is_immediate_operation | reviewed_timestamp | ready_to_complete_timestamp |
+--------------------------------------+----------+-------+--------------+-------------+--------------------------------+----------+---------+---------------------+---------------------+-----------------+-------------------+--------------------+---------------------+-------------------+-----------+----------+-----------+---------+------------------+----------------+----------+--------------------------------------------+------------+---------------------------+-------------+-------------+------------+-------------------+---------------------+----------+----------------------------+---------------------+--------------------------+---------------------------------+-----------------------+------------------+------------------+---------------+---------+-------------------+---------------------------+---------------------+--------------+--------------------------+---------------------+---------------------+-----------------+-------+------------------+------------------------+--------------------+-----------------------------+
| c919678a_6b50_11ee_808b_0a43f95f28a3 | customer |   -80 | vt_customer  | product     | alter table product modify     | vitess   |         | 2023-10-15 11:48:41 | 2023-10-15 11:48:41 |                 |                   |                    | 2023-10-15 12:00:26 |                   | cancelled |          |           |       0 | zone1-0000000301 |                |        0 | vtctl:c91857d2-6b50-11ee-808b-0a43f95f28a3 | alter      | CANCEL ALL issued by user |          -1 |           0 |          0 |                 0 |                   0 |          |                      86400 |                     |                          |                                 |                       |                  |                  |               |         |                   |                         0 |                   0 |              |                          |                     |                     |                 |       |                0 |                        |                    |                             |
|                                      |          |       |              |             | column price bigint unsigned   |          |         |                     |                     |                 |                   |                    |                     |                   |           |          |           |         |                  |                |          |                                            |            |                           |             |             |            |                   |                     |          |                            |                     |                          |                                 |                       |                  |                  |               |         |                   |                           |                     |              |                          |                     |                     |                 |       |                  |                        |                    |                             |
|                                      |          |       |              |             | default null                   |          |         |                     |                     |                 |                   |                    |                     |                   |           |          |           |         |                  |                |          |                                            |            |                           |             |             |            |                   |                     |          |                            |                     |                          |                                 |                       |                  |                  |               |         |                   |                           |                     |              |                          |                     |                     |                 |       |                  |                        |                    |                             |
| c919678a_6b50_11ee_808b_0a43f95f28a3 | customer | 80-   | vt_customer  | product     | alter table product modify     | vitess   |         | 2023-10-15 11:48:41 | 2023-10-15 11:48:41 |                 |                   |                    | 2023-10-15 12:00:26 |                   | cancelled |          |           |       0 | zone1-0000000401 |                |        0 | vtctl:c91857d2-6b50-11ee-808b-0a43f95f28a3 | alter      | CANCEL ALL issued by user |          -1 |           0 |          0 |                 0 |                   0 |          |                      86400 |                     |                          |                                 |                       |                  |                  |               |         |                   |                         0 |                   0 |              |                          |                     |                     |                 |       |                0 |                        |                    |                             |
|                                      |          |       |              |             | column price bigint unsigned   |          |         |                     |                     |                 |                   |                    |                     |                   |           |          |           |         |                  |                |          |                                            |            |                           |             |             |            |                   |                     |          |                            |                     |                          |                                 |                       |                  |                  |               |         |                   |                           |                     |              |                          |                     |                     |                 |       |                  |                        |                    |                             |
|                                      |          |       |              |             | default null                   |          |         |                     |                     |                 |                   |                    |                     |                   |           |          |           |         |                  |                |          |                                            |            |                           |             |             |            |                   |                     |          |                            |                     |                          |                                 |                       |                  |                  |               |         |                   |                           |                     |              |                          |                     |                     |                 |       |                  |                        |                    |                             |
+--------------------------------------+----------+-------+--------------+-------------+--------------------------------+----------+---------+---------------------+---------------------+-----------------+-------------------+--------------------+---------------------+-------------------+-----------+----------+-----------+---------+------------------+----------------+----------+--------------------------------------------+------------+---------------------------+-------------+-------------+------------+-------------------+---------------------+----------+----------------------------+---------------------+--------------------------+---------------------------------+-----------------------+------------------+------------------+---------------+---------+-------------------+---------------------------+---------------------+--------------+--------------------------+---------------------+---------------------+-----------------+-------+------------------+------------------------+--------------------+-----------------------------+
```
The syntax for tracking migrations is: 
```
vtctldclient OnlineDDL show <keyspace> <all|recent|queued|ready|running|complete|failed|cancelled|<migration uuid>|<migration context>>
```

## Launching a migration

Migrations submitted with [`--postpone-launch`](../postponed-migrations) remain `queued` or `ready` until told to launch. The user may launch a specific migration or they may launch all postponed migrations:

#### Via VTGate/SQL

```sql
mysql> alter vitess_migration 'aa89f255_8d68_11eb_815f_f875a4d24e90' launch;
Query OK, 1 row affected (0.01 sec)
```

or

```sql
mysql> alter vitess_migration launch all;
Query OK, 1 row affected (0.01 sec)
```

#### Via vtctldclient

Launch a specific migration:

```shell
$ vtctldclient ApplySchema --sql "alter vitess_migration '9e8a9249_3976_11ed_9442_0a43f95f28a3' launch" commerce
```

Or launch a specific migration on a specific shard:

```shell
$ vtctldclient ApplySchema --sql "alter vitess_migration '9e8a9249_3976_11ed_9442_0a43f95f28a3' launch vitess_shards '-40,40-80'" commerce
```

Or launch all:

```shell
$ vtctldclient ApplySchema --sql "alter vitess_migration launch all" commerce
```

## Completing a Migration

Migrations submitted with [`--postpone-completion`](../postponed-migrations) remain `ready` or `running` until told to complete. The user may complete a specific migration or they may complete all postponed migrations:

#### Via VTGate/SQL

```sql
mysql> alter vitess_migration 'aa89f255_8d68_11eb_815f_f875a4d24e90' complete;
Query OK, 1 row affected (0.01 sec)
```

or

```sql
mysql> alter vitess_migration complete all;
Query OK, 1 row affected (0.01 sec)
```

#### Via vtctldclient

Complete a specific migration:

```shell
$ vtctldclient ApplySchema --sql "alter vitess_migration '9e8a9249_3976_11ed_9442_0a43f95f28a3' complete" commerce
```

Or complete all:

```shell
$ vtctldclient ApplySchema --sql "alter vitess_migration complete all" commerce
```

Also available via `vtctldclient OnlineDDL` command:

```sh
$ vtctldclient OnlineDDL complete commerce 9e8a9249_3976_11ed_9442_0a43f95f28a3
{
  "rows_affected_by_shard": {
    "0": "0"
  }
}
```

## Forcing a Migration cut-over

Applicable to `ALTER TABLE` migrations in `vitess` strategy and on MySQL `8.0`. The final step of the migration, the cut-over, involves acquiring locks on the migrated table. This operation can time out when the table is otherwise locked by the user or the app, in which case Vitess retries it later on, until successful. On very busy workloads, or in workloads where the app holds long running transactions locking the table, the migration may never be able to complete.

The user may instruct Vitess to force the upcoming cut-over(s) of a specific migration, or of all pending migrations. When Vitess cuts-over such a migration, it searches for, and `KILL`s all queries still pending on the mgirated table, as well as all transactions that are holding locks on the table (by `KILL`ing their connections). This has a high likelihood to succeed and to allow the cut-over process to pass. If the cut-over still fails, then Vitess retries it later on, and keeps on `KILL`ing queries and connections on each such attempt.

Notes:

- The command merely marks the migration for forced cut-over.
- Actual cut-over expected to take place within a few seconds of issuing this command.
- Normally, migration cut-over intervals have an increasing backoff intervals. Once marked for forced cut-over, the migration ignores any such intervals and attempts at the earliest opportunity.
- It is possible to mark a migration for forced cut-over even before it completes, or before it even starts. The migration will still run normally until the point of cut-over, at which time it will attempt `KILL`ing queries and transactions.
- Not to be confused with `COMPLETE` command, above. This command does not compelte a `--postpone-completion` migration.

See also `--force-cut-over-after=<duration>` [DDL strategy flag](../ddl-strategy-flags).

#### Via VTGate/SQL

```sql
mysql> alter vitess_migration 'aa89f255_8d68_11eb_815f_f875a4d24e90' force_cutover;
Query OK, 1 row affected (0.01 sec)
```

or

```sql
mysql> alter vitess_migration force_cutover all;
Query OK, 1 row affected (0.01 sec)
```

#### Via vtctldclient

Mark a specific migration for forced cut-over:

```shell
$ vtctldclient ApplySchema --sql "alter vitess_migration '9e8a9249_3976_11ed_9442_0a43f95f28a3' force_cutover" commerce
```

Or mark all pending migrations:

```shell
$ vtctldclient ApplySchema --sql "alter vitess_migration force_cutover all" commerce
```

Also available via `vtctldclient OnlineDDL` command:

```sh
$ vtctldclient OnlineDDL force-cutover commerce 9e8a9249_3976_11ed_9442_0a43f95f28a3
{
  "rows_affected_by_shard": {
    "0": "1"
  }
}
$ vtctldclient OnlineDDL force-cutover commerce all
{
  "rows_affected_by_shard": {
    "0": "4"
  }
}
```

## Cancelling a Migration

The user may cancel a migration, as follows:

- If the migration hasn't started yet (it is `queued` or `ready`), then it transitions into `cancelled` state and doesn't get executed.
- If the migration is `running`, then it is forcibly interrupted. The migration transitions to `cancelled` state.
- In all other cases, cancelling a migration has no effect.

#### Via VTGate/SQL

In this illustrative flow we also glimpse into some further control over migrations.

```sql

mysql> set @@ddl_strategy='vitess --postpone-completion';

mysql> alter table product engine=innodb;
+--------------------------------------+
| uuid                                 |
+--------------------------------------+
| f9e4dbaa_6b54_11ee_b0cf_0a43f95f28a3 |
+--------------------------------------+

mysql> show vitess_migrations like 'f9e4dbaa_6b54_11ee_b0cf_0a43f95f28a3' \G
*************************** 1. row ***************************
                             id: 3
                 migration_uuid: f9e4dbaa_6b54_11ee_b0cf_0a43f95f28a3
                       keyspace: commerce
                          shard: 0
                   mysql_schema: vt_commerce
                    mysql_table: product
            migration_statement: alter table product engine innodb
                       strategy: vitess
                        options: --postpone-completion
                added_timestamp: 2023-10-15 12:18:40
            requested_timestamp: 2023-10-15 12:18:41
                ready_timestamp: NULL
              started_timestamp: 2023-10-15 12:18:42
             liveness_timestamp: 2023-10-15 12:18:52
            completed_timestamp: NULL
              cleanup_timestamp: NULL
               migration_status: running
...


mysql> alter vitess_migration 'f9e4dbaa_6b54_11ee_b0cf_0a43f95f28a3' cancel;
Query OK, 1 row affected (0.04 sec)

mysql> show vitess_migrations like 'f9e4dbaa_6b54_11ee_b0cf_0a43f95f28a3' \G
*************************** 1. row ***************************
                             id: 3
                 migration_uuid: f9e4dbaa_6b54_11ee_b0cf_0a43f95f28a3
                       keyspace: commerce
                          shard: 0
                   mysql_schema: vt_commerce
                    mysql_table: product
            migration_statement: alter table product engine innodb
                       strategy: vitess
                        options: --postpone-completion
                added_timestamp: 2023-10-15 12:18:40
            requested_timestamp: 2023-10-15 12:18:41
                ready_timestamp: NULL
              started_timestamp: 2023-10-15 12:18:42
             liveness_timestamp: 2023-10-15 12:19:02
            completed_timestamp: 2023-10-15 12:19:42.347196
              cleanup_timestamp: NULL
               migration_status: cancelled
                       log_path:
                      artifacts: _f9e4dbaa_6b54_11ee_b0cf_0a43f95f28a3_20231015121841_vrepl,
                        retries: 0
                         tablet: zone1-0000000100
                 tablet_failure: 0
                       progress: 100
              migration_context: vtgate:cc06e24a-6b54-11ee-b0cf-0a43f95f28a3
                     ddl_action: alter
                        message: CANCEL issued by user
...
```

- `alter vitess_migration ... cancel` takes exactly one migration's UUID.
- `alter vitess_migration cancel all` takes no arguments and affects all pending migrations.
- `alter vitess_migration ... cancel` or `alter vitess_migration cancel all` respond with number of affected migrations across all shards.

#### Via vtctldclient

Illustrating yet another flow where we can control the progress of migrations:

```sh

$ vtctldclient UpdateThrottlerConfig --enable customer

$ vtctldclient ApplySchema --sql "alter vitess_migration throttle all" customer

$ vtctldclient ApplySchema --ddl-strategy="vitess" --sql "alter table corder engine=innodb" customer
075088b9_6b56_11ee_808b_0a43f95f28a3

$ vtctldclient OnlineDDL show customer 075088b9_6b56_11ee_808b_0a43f95f28a3
+--------------------------------------+----------+-------+--------------+-------------+--------------------------------+----------+---------+---------------------+---------------------+-----------------+---------------------+---------------------+---------------------+-------------------+---------+----------+-------------------------------------------------------------+---------+------------------+----------------+----------+--------------------------------------------+------------+---------+-------------+-------------+------------+-------------------+---------------------+----------+----------------------------+---------------------+--------------------------+---------------------------------+-----------------------+------------------+------------------+---------------+---------+-------------------+---------------------------+---------------------+--------------+--------------------------+---------------------+---------------------+-----------------+-------+------------------+------------------------+---------------------+-----------------------------+
|            migration_uuid            | keyspace | shard | mysql_schema | mysql_table |      migration_statement       | strategy | options |   added_timestamp   | requested_timestamp | ready_timestamp |  started_timestamp  | liveness_timestamp  | completed_timestamp | cleanup_timestamp | status  | log_path |                          artifacts                          | retries |      tablet      | tablet_failure | progress |             migration_context              | ddl_action | message | eta_seconds | rows_copied | table_rows | added_unique_keys | removed_unique_keys | log_file | artifact_retention_seconds | postpone_completion | removed_unique_key_names | dropped_no_default_column_names | expanded_column_names | revertible_notes | allow_concurrent | reverted_uuid | is_view | ready_to_complete | vitess_liveness_indicator | user_throttle_ratio | special_plan | last_throttled_timestamp | component_throttled | cancelled_timestamp | postpone_launch | stage | cutover_attempts | is_immediate_operation | reviewed_timestamp  | ready_to_complete_timestamp |
+--------------------------------------+----------+-------+--------------+-------------+--------------------------------+----------+---------+---------------------+---------------------+-----------------+---------------------+---------------------+---------------------+-------------------+---------+----------+-------------------------------------------------------------+---------+------------------+----------------+----------+--------------------------------------------+------------+---------+-------------+-------------+------------+-------------------+---------------------+----------+----------------------------+---------------------+--------------------------+---------------------------------+-----------------------+------------------+------------------+---------------+---------+-------------------+---------------------------+---------------------+--------------+--------------------------+---------------------+---------------------+-----------------+-------+------------------+------------------------+---------------------+-----------------------------+
| 075088b9_6b56_11ee_808b_0a43f95f28a3 | customer |   -80 | vt_customer  | corder      | alter table corder engine      | vitess   |         | 2023-10-15 12:26:12 | 2023-10-15 12:26:13 |                 | 2023-10-15 12:26:14 | 2023-10-15 12:26:23 |                     |                   | running |          | _075088b9_6b56_11ee_808b_0a43f95f28a3_20231015122613_vrepl, |       0 | zone1-0000000301 |                |      100 | vtctl:074f5fd7-6b56-11ee-808b-0a43f95f28a3 | alter      |         |           0 |           0 |          0 |                 0 |                   0 |          |                      86400 |                     |                          |                                 |                       |                  |                  |               |         |                   |                1697372782 |                   1 |              | 2023-10-15 12:26:22      | vcopier             |                     |                 |       |                0 |                        | 2023-10-15 12:26:14 |                             |
|                                      |          |       |              |             | innodb                         |          |         |                     |                     |                 |                     |                     |                     |                   |         |          |                                                             |         |                  |                |          |                                            |            |         |             |             |            |                   |                     |          |                            |                     |                          |                                 |                       |                  |                  |               |         |                   |                           |                     |              |                          |                     |                     |                 |       |                  |                        |                     |                             |
| 075088b9_6b56_11ee_808b_0a43f95f28a3 | customer | 80-   | vt_customer  | corder      | alter table corder engine      | vitess   |         | 2023-10-15 12:26:12 | 2023-10-15 12:26:13 |                 | 2023-10-15 12:26:14 | 2023-10-15 12:26:23 |                     |                   | running |          | _075088b9_6b56_11ee_808b_0a43f95f28a3_20231015122613_vrepl, |       0 | zone1-0000000401 |                |      100 | vtctl:074f5fd7-6b56-11ee-808b-0a43f95f28a3 | alter      |         |           0 |           0 |          0 |                 0 |                   0 |          |                      86400 |                     |                          |                                 |                       |                  |                  |               |         |                   |                1697372782 |                   1 |              | 2023-10-15 12:26:22      | vcopier             |                     |                 |       |                0 |                        | 2023-10-15 12:26:14 |                             |
|                                      |          |       |              |             | innodb                         |          |         |                     |                     |                 |                     |                     |                     |                   |         |          |                                                             |         |                  |                |          |                                            |            |         |             |             |            |                   |                     |          |                            |                     |                          |                                 |                       |                  |                  |               |         |                   |                           |                     |              |                          |                     |                     |                 |       |                  |                        |                     |                             |
+--------------------------------------+----------+-------+--------------+-------------+--------------------------------+----------+---------+---------------------+---------------------+-----------------+---------------------+---------------------+---------------------+-------------------+---------+----------+-------------------------------------------------------------+---------+------------------+----------------+----------+--------------------------------------------+------------+---------+-------------+-------------+------------+-------------------+---------------------+----------+----------------------------+---------------------+--------------------------+---------------------------------+-----------------------+------------------+------------------+---------------+---------+-------------------+---------------------------+---------------------+--------------+--------------------------+---------------------+---------------------+-----------------+-------+------------------+------------------------+---------------------+-----------------------------+

$ vtctldclient OnlineDDL cancel customer 075088b9_6b56_11ee_808b_0a43f95f28a3
{
  "rows_affected_by_shard": {
    "-80": "1",
    "80-": "1"
  }
}

$ vtctldclient OnlineDDL show customer 075088b9_6b56_11ee_808b_0a43f95f28a3
+--------------------------------------+----------+-------+--------------+-------------+--------------------------------+----------+---------+---------------------+---------------------+-----------------+---------------------+---------------------+---------------------+-------------------+-----------+----------+-------------------------------------------------------------+---------+------------------+----------------+----------+--------------------------------------------+------------+-----------------------+-------------+-------------+------------+-------------------+---------------------+----------+----------------------------+---------------------+--------------------------+---------------------------------+-----------------------+------------------+------------------+---------------+---------+-------------------+---------------------------+---------------------+--------------+--------------------------+---------------------+---------------------+-----------------+-------+------------------+------------------------+---------------------+-----------------------------+
|            migration_uuid            | keyspace | shard | mysql_schema | mysql_table |      migration_statement       | strategy | options |   added_timestamp   | requested_timestamp | ready_timestamp |  started_timestamp  | liveness_timestamp  | completed_timestamp | cleanup_timestamp |  status   | log_path |                          artifacts                          | retries |      tablet      | tablet_failure | progress |             migration_context              | ddl_action |        message        | eta_seconds | rows_copied | table_rows | added_unique_keys | removed_unique_keys | log_file | artifact_retention_seconds | postpone_completion | removed_unique_key_names | dropped_no_default_column_names | expanded_column_names | revertible_notes | allow_concurrent | reverted_uuid | is_view | ready_to_complete | vitess_liveness_indicator | user_throttle_ratio | special_plan | last_throttled_timestamp | component_throttled | cancelled_timestamp | postpone_launch | stage | cutover_attempts | is_immediate_operation | reviewed_timestamp  | ready_to_complete_timestamp |
+--------------------------------------+----------+-------+--------------+-------------+--------------------------------+----------+---------+---------------------+---------------------+-----------------+---------------------+---------------------+---------------------+-------------------+-----------+----------+-------------------------------------------------------------+---------+------------------+----------------+----------+--------------------------------------------+------------+-----------------------+-------------+-------------+------------+-------------------+---------------------+----------+----------------------------+---------------------+--------------------------+---------------------------------+-----------------------+------------------+------------------+---------------+---------+-------------------+---------------------------+---------------------+--------------+--------------------------+---------------------+---------------------+-----------------+-------+------------------+------------------------+---------------------+-----------------------------+
| 075088b9_6b56_11ee_808b_0a43f95f28a3 | customer |   -80 | vt_customer  | corder      | alter table corder engine      | vitess   |         | 2023-10-15 12:26:12 | 2023-10-15 12:26:13 |                 | 2023-10-15 12:26:14 | 2023-10-15 12:26:34 | 2023-10-15 12:26:54 |                   | cancelled |          | _075088b9_6b56_11ee_808b_0a43f95f28a3_20231015122613_vrepl, |       0 | zone1-0000000301 |                |      100 | vtctl:074f5fd7-6b56-11ee-808b-0a43f95f28a3 | alter      | CANCEL issued by user |           0 |           0 |          0 |                 0 |                   0 |          |                      86400 |                     |                          |                                 |                       |                  |                  |               |         |                   |                1697372793 |                   1 |              | 2023-10-15 12:26:33      | vcopier             |                     |                 |       |                0 |                        | 2023-10-15 12:26:14 |                             |
|                                      |          |       |              |             | innodb                         |          |         |                     |                     |                 |                     |                     |                     |                   |           |          |                                                             |         |                  |                |          |                                            |            |                       |             |             |            |                   |                     |          |                            |                     |                          |                                 |                       |                  |                  |               |         |                   |                           |                     |              |                          |                     |                     |                 |       |                  |                        |                     |                             |
| 075088b9_6b56_11ee_808b_0a43f95f28a3 | customer | 80-   | vt_customer  | corder      | alter table corder engine      | vitess   |         | 2023-10-15 12:26:12 | 2023-10-15 12:26:13 |                 | 2023-10-15 12:26:14 | 2023-10-15 12:26:34 | 2023-10-15 12:26:54 |                   | cancelled |          | _075088b9_6b56_11ee_808b_0a43f95f28a3_20231015122613_vrepl, |       0 | zone1-0000000401 |                |      100 | vtctl:074f5fd7-6b56-11ee-808b-0a43f95f28a3 | alter      | CANCEL issued by user |           0 |           0 |          0 |                 0 |                   0 |          |                      86400 |                     |                          |                                 |                       |                  |                  |               |         |                   |                1697372793 |                   1 |              | 2023-10-15 12:26:33      | vcopier             |                     |                 |       |                0 |                        | 2023-10-15 12:26:14 |                             |
|                                      |          |       |              |             | innodb                         |          |         |                     |                     |                 |                     |                     |                     |                   |           |          |                                                             |         |                  |                |          |                                            |            |                       |             |             |            |                   |                     |          |                            |                     |                          |                                 |                       |                  |                  |               |         |                   |                           |                     |              |                          |                     |                     |                 |       |                  |                        |                     |                             |
+--------------------------------------+----------+-------+--------------+-------------+--------------------------------+----------+---------+---------------------+---------------------+-----------------+---------------------+---------------------+---------------------+-------------------+-----------+----------+-------------------------------------------------------------+---------+------------------+----------------+----------+--------------------------------------------+------------+-----------------------+-------------+-------------+------------+-------------------+---------------------+----------+----------------------------+---------------------+--------------------------+---------------------------------+-----------------------+------------------+------------------+---------------+---------+-------------------+---------------------------+---------------------+--------------+--------------------------+---------------------+---------------------+-----------------+-------+------------------+------------------------+---------------------+-----------------------------+
```

## Cancelling all keyspace migrations

The user may cancel all migrations in a keyspace. A migration is cancellable if it is in `queued`, `ready` or `running` states, as described previously. It is a high impact operation and should be used with care.

#### Via VTGate/SQL

Examples for a single shard cluster:

```sql
mysql> alter vitess_migration cancel all;
Query OK, 1 row affected (0.02 sec)
```

#### Via vtctldclient

```shell
$ vtctldclient ApplySchema --sql "alter vitess_migration cancel all" commerce
```

Also available via `vtctldclient OnlineDDL` command:

```sh
$ vtctldclient OnlineDDL cancel commerce all
{
  "rows_affected_by_shard": {
    "0": "0"
  }
}
```

## Retrying a Migration

The user may retry running a migration. If the migration is in `failed` or in `cancelled` state, Vitess will re-run the migration, with exact same arguments as previously intended. If the migration is in any other state, `retry` does nothing.

It is not possible to retry a migration with different options. e.g. if the user initially runs `ALTER TABLE demo MODIFY id BIGINT` with `@@ddl_strategy='gh-ost --max-load Threads_running=200'` and the migration fails, retrying it will use exact same options. It is not possible to retry with `@@ddl_strategy='gh-ost --max-load Threads_running=500'`.

#### Via VTGate/SQL

```sql
mysql> alter vitess_migration '075088b9_6b56_11ee_808b_0a43f95f28a3' retry;
Query OK, 2 rows affected (0.01 sec)

mysql> show vitess_migrations like '075088b9_6b56_11ee_808b_0a43f95f28a3' \G
*************************** 1. row ***************************
                             id: 12
                 migration_uuid: 075088b9_6b56_11ee_808b_0a43f95f28a3
                       keyspace: customer
                          shard: -80
                   mysql_schema: vt_customer
                    mysql_table: corder
            migration_statement: alter table corder engine innodb
                       strategy: vitess
                        options:
                added_timestamp: 2023-10-15 12:26:12
            requested_timestamp: 2023-10-15 12:26:13
                ready_timestamp: NULL
              started_timestamp: 2023-10-15 12:30:09
             liveness_timestamp: 2023-10-15 12:30:18
            completed_timestamp: NULL
              cleanup_timestamp: NULL
               migration_status: running
...
*************************** 2. row ***************************
                             id: 12
                 migration_uuid: 075088b9_6b56_11ee_808b_0a43f95f28a3
                       keyspace: customer
                          shard: 80-
                   mysql_schema: vt_customer
                    mysql_table: corder
            migration_statement: alter table corder engine innodb
                       strategy: vitess
                        options:
                added_timestamp: 2023-10-15 12:26:12
            requested_timestamp: 2023-10-15 12:26:13
                ready_timestamp: NULL
              started_timestamp: 2023-10-15 12:30:09
             liveness_timestamp: 2023-10-15 12:30:18
            completed_timestamp: NULL
              cleanup_timestamp: NULL
               migration_status: running
...
```

#### Via vtctldclient

The above migrations are running again, but still throttled. By way of illustration, let's cancel and retry them yet again:

```shell
$ vtctldclient ApplySchema --sql "alter vitess_migration '075088b9_6b56_11ee_808b_0a43f95f28a3' cancel" customer
$ vtctldclient ApplySchema --sql "alter vitess_migration '075088b9_6b56_11ee_808b_0a43f95f28a3' retry" customer
```

Also available via `vtctldclient OnlineDDL` command:


```sh
$ vtctldclient OnlineDDL cancel customer 075088b9_6b56_11ee_808b_0a43f95f28a3
{
  "rows_affected_by_shard": {
    "-80": "1",
    "80-": "1"
  }
}
$ vtctldclient OnlineDDL retry customer 075088b9_6b56_11ee_808b_0a43f95f28a3
{
  "rows_affected_by_shard": {
    "-80": "1",
    "80-": "1"
  }
}
```

## Cleaning Migration Artifacts

Migrations yield artifacts: these are leftover tables, such as the ghost or shadow tables in an `ALTER` DDL. These tables are audited and collected as part of [table lifecycle](../table-lifecycle/).

The artifacts are essential to [Reverting a migration](../revertible-migrations/), and are kept intact for a while before destroyed.

However, the artifacts also consume disk space. If the user is convinced they will not need the artifacts, they may explicitly request that the artifacts are dropped sooner.

{{< warning >}}
Once cleanup is requested, the migration cannot be reverted.
{{< /warning >}}
{{< info >}}
The artifact tables are not purged immediately. Rather, they are sent for processing into the lifecycle mechanism.
{{< /info >}}

#### Via VTGate/SQL

Per migration, request artifact cleanup via:

```sql
mysql> alter vitess_migration 'aa89f255_8d68_11eb_815f_f875a4d24e90' cleanup;
Query OK, 1 row affected (0.00 sec)
```


#### Via vtctldclient

Execute via `vtctldclient ApplySchema --sql "..." <keyspace>` like previous commands, or use `OnlineDDL` command:


```shell
$ $ vtctldclient OnlineDDL cancel customer all
{
  "rows_affected_by_shard": {
    "-80": "1",
    "80-": "1"
  }
}
$ vtctldclient OnlineDDL cleanup customer 075088b9_6b56_11ee_808b_0a43f95f28a3
{
  "rows_affected_by_shard": {
    "-80": "1",
    "80-": "1"
  }
}
```

## Reverting a Migration

Vitess offers _lossless revert_ for online schema migrations: the user may regret a table migration after completion, and roll back the table's schema to previous state _without loss of data_. See [Revertible Migrations](../revertible-migrations/).

#### Via VTGate/SQL

Examples for a single shard cluster:

```sql
mysql> show create table corder\G

Create Table: CREATE TABLE `corder` (
  `order_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `customer_id` bigint(20) DEFAULT NULL,
  `sku` varbinary(128) DEFAULT NULL,
  `price` bigint(20) DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8
1 row in set (0.01 sec)

mysql> set @@ddl_strategy='vitess';

mysql> alter table corder drop column ts, add key customer_idx(customer_id);
+--------------------------------------+
| uuid                                 |
+--------------------------------------+
| 1a689113_8d77_11eb_815f_f875a4d24e90 |
+--------------------------------------+

mysql> show create table corder\G

Create Table: CREATE TABLE `corder` (
  `order_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `customer_id` bigint(20) DEFAULT NULL,
  `sku` varbinary(128) DEFAULT NULL,
  `price` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`order_id`),
  KEY `customer_idx` (`customer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8
1 row in set (0.00 sec)

mysql> revert vitess_migration '1a689113_8d77_11eb_815f_f875a4d24e90';
+--------------------------------------+
| uuid                                 |
+--------------------------------------+
| a02e6612_8d79_11eb_815f_f875a4d24e90 |
+--------------------------------------+

mysql> show create table corder\G

Create Table: CREATE TABLE `corder` (
  `order_id` bigint(20) NOT NULL AUTO_INCREMENT,
  `customer_id` bigint(20) DEFAULT NULL,
  `sku` varbinary(128) DEFAULT NULL,
  `price` bigint(20) DEFAULT NULL,
  `ts` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8
```

- A `revert` is its own migration, hence has its own UUID

#### Via vtctldclient

```sh
$ vtctldclient ApplySchema --ddl-strategy "vitess" --sql "revert vitess_migration '1a689113_8d77_11eb_815f_f875a4d24e90'" commerce
```

## Controlling Throttling

Managed migrations [use](../managed-online-schema-changes/#throttling) the [tablet throttler](../../../reference/features/tablet-throttler/) to ensure a sustainable impact to the MySQL servers and replication stream. Normally, the user doesn't need to get involved, as the throttler auto-identifies load scenarios, and pushes back on migration progress. However, Vitess makes available these commands for additional control over migration throttling:

```sql
alter vitess_migration '<uuid>' throttle [expire '<duration>'] [ratio <ratio>];
alter vitess_migration throttle all [expire '<duration>'] [ratio <ratio>];
alter vitess_migration '<uuid>' unthrottle;
alter vitess_migration unthrottle all;
show vitess_throttled_apps;
```

**Note:** the tablet throttler must be enabled for these command to run.

### Throttling a Migration

To fully throttle a migration, run:

```sql
mysql> alter vitess_migration 'aa89f255_8d68_11eb_815f_f875a4d24e90' throttle;
Query OK, 1 row affected (0.00 sec)
```

From this point on, the migration will not make row copy progress and will not apply binary logs. By default, this command does not expire, and it takes an explicit `unthrottle` command to resume migration progress. Because MySQL binary logs are rotated, a migration may only survive a full throttling up to the point where the binary log it last processed is purged.

You may supply either or both these options: `expire`, `ratio`:

- `alter vitess_migration 'aa89f255_8d68_11eb_815f_f875a4d24e90' throttle expire '2h'` will fully throttle the migration for the next `2` hours, after which the migration resumes normal work. You may specify these units: `s` (seconds), `m` (minutes), `h` (hours) or combinations. Example values: `90s`, `30m`, `1h`, `1h30m`, etc.
- `alter vitess_migration 'aa89f255_8d68_11eb_815f_f875a4d24e90' throttle ratio 0.7` will partially throttle the migration. This instructs the throttler to reject, on average, `7` migration throttling check requests out of `10`. Any value between `0` (no throttling at all) and `1.0` (fully throttled) are allowed. This is a fine tune way to slow down a migration.

### Throttling All Migrations

It's likely that you will want to throttle migrations in general, and not a specific migration. Use:

- `alter vitess_migration throttle all` to fully throttle any and all migrations from this point on
- `alter vitess_migration throttle all expire '90m'` to fully throttle any and all migrations from this point on and for the next `90` minutes.
- `alter vitess_migration throttle all ratio 0.8` to severely slow down all migrations from this point on (4 out of 5 migrations requests to the throttler are denied)
- `alter vitess_migration throttle all duration '10m' ratio 0.2` to lightly slow down all migrations from this point on (1 out of 5 migrations requests to the throttler are denied) for the next `10` minutes.

### Unthrottling

Use:

- `alter vitess_migration 'aa89f255_8d68_11eb_815f_f875a4d24e90' unthrottle` to allow the specified migration to resume working as normal
- `alter vitess_migration unthrottle all` to unthrottle all migrations.

**Note** that this does not disable throttling altogether. If, for example, replication lag grows on replicas, the throttler may still throttle the migration until replication is caught up. Unthrottling only cancels an explicit throttling request as described above.

### Showing Throttled Apps

The command `show vitess_throttled_apps` is a general purpose throttler command, and shows all apps for which there are throttling rules. It will list any specific or general migration throttling status.

#### Via vtctldclient

Execute via `vtctldclient ApplySchema --sql "..." <keyspace>` like previous commands, or use `OnlineDDL` commands:

```shell
$ vtctldclient OnlineDDL throttle customer 075088b9_6b56_11ee_808b_0a43f95f28a3
$ vtctldclient OnlineDDL throttle customer all
$ vtctldclient OnlineDDL unthrottle customer 075088b9_6b56_11ee_808b_0a43f95f28a3
$ vtctldclient OnlineDDL unthrottle customer all
```
