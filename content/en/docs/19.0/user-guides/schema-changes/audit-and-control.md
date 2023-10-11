---
title: Applying, auditing, and controlling Online DDL
weight: 6
aliases: ['/docs/user-guides/managed-online-schema-changes/audit-and-control']
---

Vitess provides two interfaces to interacting with Online DDL:

- SQL commands, via `VTGate`
- Command line interface, via `vtctldclient`

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

## Running migrations

To run a managed schema migration, you should:

- Formulate your DDLs (`CREATE`, `ALTER`, `DROP`) queries
- Choose a [ddl-strategy](../ddl-strategies)

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
- If you run `vtgate` without `--ddl_strategy`, then `@@ddl_strategy` defaults to `'direct'`, which implies schema migrations are synchronous. You will need to `set @@ddl_strategy='gh-ost'` to run followup `ALTER TABLE` statements via `gh-ost`.
- If you run `vtgate --ddl_strategy "gh-ost"`, then `@@ddl_strategy` defaults to `'gh-ost'` in each new session. Any `ALTER TABLE` will run via `gh-ost`. You may `set @@ddl_strategy='pt-osc'` to make migrations run through `pt-online-schema-change`, or `set @@ddl_strategy='direct'` to run migrations synchronously.

#### Via vtctldclient/ApplySchema

You may use `vtctldclient` to apply schema changes. The `ApplySchema` command supports both synchronous and online schema migrations. To run an online schema migration you will supply the `--ddl-strategy` command line flag:

```shell
$ vtctldclient ApplySchema --ddl-strategy "vitess" --sql "ALTER TABLE demo MODIFY id bigint UNSIGNED" commerce
a2994c92_f1d4_11ea_afa3_f875a4d24e90
```

 You my run multiple migrations withing the same `ApplySchema` command:

```shell
$ vtctldclient ApplySchema --ddl-strategy "vitess" --sql "ALTER TABLE demo MODIFY id bigint UNSIGNED; CREATE TABLE sample (id int PRIMARY KEY); DROP TABLE another;" commerce
e1697214_688a_11ee_995e_920702940ee0
e16ab1e2_688a_11ee_995e_920702940ee0
e16bd0c2_688a_11ee_995e_920702940ee0
```

`ApplySchema` accepts the following flags:

- `--ddl-strategy`: by default migrations run directly via MySQL standard DDL. This flag must be aupplied to indicate an online strategy. See also [DDL strategies](../ddl-strategies) and [ddl-strategy flags](../ddl-strategy-flags).
- `--migration-context <unique-value>`: all migrations in a `ApplySchema` command are logically grouped via a unique _context_. A unique value will be supplied automatically. The user may choose to supply their own value, and it's their responsibility to provide with a unique value. Any string format is accepted.
  The context can then be used to search for migrations, via `SHOW VITESS_MIGRATIONS LIKE 'the-context'`. It is visible in `SHOW VITESS_MIGRATIONS ...` output as the `migration_context` column.

## Tracking migrations

You may track the status of a single or of multiple migrations. Since migrations run asycnhronously, it is the user's responsibility to audit the progress and state of submitted migrations. Users are likely to want to know when a migration is complete (or failed) so as to be able to deploy code changes or run other operations.

Common patterns are:

- Show state of a specific migration
- Show all `running`, `complete` or `failed` migrations
- Show recent migrations
- Show migrations ordered by most-recent first.
- Show n number of migrations, skipping m rows.

#### Via VTGate/SQL

Examples for a single shard cluster:

```sql
mysql> show vitess_migrations like 'bf4598ab_8d55_11eb_815f_f875a4d24e90' \G
*************************** 1. row ***************************
                 id: 23
     migration_uuid: bf4598ab_8d55_11eb_815f_f875a4d24e90
           keyspace: commerce
              shard: 0
       mysql_schema: vt_commerce
        mysql_table: corder
migration_statement: alter table corder add column ts timestamp not null default current_timestamp()
           strategy: vitess
            options: 
    added_timestamp: 2021-03-25 12:35:01
requested_timestamp: 2021-03-25 12:34:58
    ready_timestamp: 2021-03-25 12:35:04
  started_timestamp: 2021-03-25 12:35:04
 liveness_timestamp: 2021-03-25 12:35:06
completed_timestamp: 2021-03-25 12:35:06
  cleanup_timestamp: NULL
   migration_status: complete
           log_path: 
          artifacts: _bf4598ab_8d55_11eb_815f_f875a4d24e90_20210325123504_vrepl,
            retries: 0
             tablet: zone1-0000000100
     tablet_failure: 0
           progress: 100
  migration_context: vtgate:a8352418-8d55-11eb-815f-f875a4d24e90
         ddl_action: alter
            message: 
        eta_seconds: 0
```

```sql
mysql> show vitess_migrations like 'complete' \G
...
*************************** 21. row ***************************
                 id: 24
     migration_uuid: 6848c1a4_8d57_11eb_815f_f875a4d24e90
           keyspace: commerce
              shard: 0
       mysql_schema: vt_commerce
        mysql_table: customer
migration_statement: drop table customer
           strategy: vitess
            options: 
    added_timestamp: 2021-03-25 12:46:53
requested_timestamp: 2021-03-25 12:46:51
    ready_timestamp: 2021-03-25 12:46:57
  started_timestamp: 2021-03-25 12:46:57
 liveness_timestamp: 2021-03-25 12:46:57
completed_timestamp: 2021-03-25 12:46:57
  cleanup_timestamp: NULL
   migration_status: complete
           log_path: 
          artifacts: _vt_HOLD_6848c1a48d5711eb815ff875a4d24e90_20210326104657,
            retries: 0
             tablet: zone1-0000000100
     tablet_failure: 0
           progress: 100
  migration_context: vtgate:a8352418-8d55-11eb-815f-f875a4d24e90
         ddl_action: drop
            message: 
        eta_seconds: 0
```

```sql
mysql> show vitess_migrations where completed_timestamp > now() - interval 1 day;
+----+--------------------------------------+----------+-------+--------------+-------------+---------------------------------------------------------------------------------+----------+---------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+-------------------+------------------+----------+-------------------------------------------------------------+---------+------------------+----------------+----------+---------------------------------------------+------------+---------+-------------+
| id | migration_uuid                       | keyspace | shard | mysql_schema | mysql_table | migration_statement                                                             | strategy | options | added_timestamp     | requested_timestamp | ready_timestamp     | started_timestamp   | liveness_timestamp  | completed_timestamp | cleanup_timestamp | migration_status | log_path | artifacts                                                   | retries | tablet           | tablet_failure | progress | migration_context                           | ddl_action | message | eta_seconds |
+----+--------------------------------------+----------+-------+--------------+-------------+---------------------------------------------------------------------------------+----------+---------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+-------------------+------------------+----------+-------------------------------------------------------------+---------+------------------+----------------+----------+---------------------------------------------+------------+---------+-------------+
| 23 | bf4598ab_8d55_11eb_815f_f875a4d24e90 | commerce | 0     | vt_commerce  | corder      | alter table corder add column ts timestamp not null default current_timestamp() | online   |         | 2021-03-25 12:35:01 | 2021-03-25 12:34:58 | 2021-03-25 12:35:04 | 2021-03-25 12:35:04 | 2021-03-25 12:35:06 | 2021-03-25 12:35:06 | NULL              | complete         |          | _bf4598ab_8d55_11eb_815f_f875a4d24e90_20210325123504_vrepl, |       0 | zone1-0000000100 |              0 |      100 | vtgate:a8352418-8d55-11eb-815f-f875a4d24e90 | alter      |         |           0 |
| 24 | 6848c1a4_8d57_11eb_815f_f875a4d24e90 | commerce | 0     | vt_commerce  | customer    | drop table customer                                                             | online   |         | 2021-03-25 12:46:53 | 2021-03-25 12:46:51 | 2021-03-25 12:46:57 | 2021-03-25 12:46:57 | 2021-03-25 12:46:57 | 2021-03-25 12:46:57 | NULL              | complete         |          | _vt_HOLD_6848c1a48d5711eb815ff875a4d24e90_20210326104657,   |       0 | zone1-0000000100 |              0 |      100 | vtgate:a8352418-8d55-11eb-815f-f875a4d24e90 | drop       |         |           0 |
| 25 | 6fd57dd3_8d57_11eb_815f_f875a4d24e90 | commerce | 0     | vt_commerce  | customer    | revert 6848c1a4_8d57_11eb_815f_f875a4d24e90                                     | online   |         | 2021-03-25 12:47:08 | 2021-03-25 12:47:04 | 2021-03-25 12:47:12 | 2021-03-25 12:47:12 | 2021-03-25 12:47:12 | 2021-03-25 12:47:12 | NULL              | complete         |          | _vt_HOLD_6848c1a48d5711eb815ff875a4d24e90_20210326104657,   |       0 | zone1-0000000100 |              0 |      100 | vtgate:a8352418-8d55-11eb-815f-f875a4d24e90 | create     |         |           0 |
+----+--------------------------------------+----------+-------+--------------+-------------+---------------------------------------------------------------------------------+----------+---------+---------------------+---------------------+---------------------+---------------------+---------------------+---------------------+-------------------+------------------+----------+-------------------------------------------------------------+---------+------------------+----------------+----------+---------------------------------------------+------------+---------+-------------+
```

- `show vitess_migrations` shows the entire history of migrations.
- `show vitess_migrations like ...` filters migrations by `migration_uuid`, or `migration_context`, or `migration_status`.
- `show vitess_migrations where ...` lets the user specify arbitrary conditions.
- All commands return results for the keyspace (schema) in use.

#### Via vtctldclient/ApplySchema

Examples for a 4-shard cluster:

```shell
$ vtctldclient OnlineDDL show commerce e1697214_688a_11ee_995e_920702940ee0
+--------------------------------------+----------+-------+--------------+-------------+--------------------------------+----------+---------+---------------------+---------------------+-----------------+-------------------+--------------------+---------------------+-------------------+--------+----------+-----------+---------+------------------+----------------+----------+--------------------------------------------+------------+---------+-------------+-------------+------------+-------------------+---------------------+----------+----------------------------+---------------------+--------------------------+---------------------------------+-----------------------+------------------+------------------+---------------+---------+-------------------+---------------------------+---------------------+--------------+--------------------------+---------------------+---------------------+-----------------+-------+------------------+------------------------+--------------------+-----------------------------+
|            migration_uuid            | keyspace | shard | mysql_schema | mysql_table |      migration_statement       | strategy | options |   added_timestamp   | requested_timestamp | ready_timestamp | started_timestamp | liveness_timestamp | completed_timestamp | cleanup_timestamp | status | log_path | artifacts | retries |      tablet      | tablet_failure | progress |             migration_context              | ddl_action | message | eta_seconds | rows_copied | table_rows | added_unique_keys | removed_unique_keys | log_file | artifact_retention_seconds | postpone_completion | removed_unique_key_names | dropped_no_default_column_names | expanded_column_names | revertible_notes | allow_concurrent | reverted_uuid | is_view | ready_to_complete | vitess_liveness_indicator | user_throttle_ratio | special_plan | last_throttled_timestamp | component_throttled | cancelled_timestamp | postpone_launch | stage | cutover_attempts | is_immediate_operation | reviewed_timestamp | ready_to_complete_timestamp |
+--------------------------------------+----------+-------+--------------+-------------+--------------------------------+----------+---------+---------------------+---------------------+-----------------+-------------------+--------------------+---------------------+-------------------+--------+----------+-----------+---------+------------------+----------------+----------+--------------------------------------------+------------+---------+-------------+-------------+------------+-------------------+---------------------+----------+----------------------------+---------------------+--------------------------+---------------------------------+-----------------------+------------------+------------------+---------------+---------+-------------------+---------------------------+---------------------+--------------+--------------------------+---------------------+---------------------+-----------------+-------+------------------+------------------------+--------------------+-----------------------------+
| e1697214_688a_11ee_995e_920702940ee0 | commerce |     0 | vt_commerce  | demo        | alter table demo modify column | vitess   |         | 2023-10-11 19:06:59 | 2023-10-11 19:06:59 |                 |                   |                    |                     |                   | queued |          |           |       0 | zone1-0000000101 |                |        0 | vtctl:e1670c86-688a-11ee-995e-920702940ee0 | alter      |         |          -1 |           0 |          0 |                 0 |                   0 |          |                      86400 |                     |                          |                                 |                       |                  |                  |               |         |                   |                         0 |                   0 |              |                          |                     |                     |                 |       |                0 |                        |                    |                             |
|                                      |          |       |              |             | id bigint unsigned             |          |         |                     |                     |                 |                   |                    |                     |                   |        |          |           |         |                  |                |          |                                            |            |         |             |             |            |                   |                     |          |                            |                     |                          |                                 |                       |                  |                  |               |         |                   |                           |                     |              |                          |                     |                     |                 |       |                  |                        |                    |                             |
+--------------------------------------+----------+-------+--------------+-------------+--------------------------------+----------+---------+---------------------+---------------------+-----------------+-------------------+--------------------+---------------------+-------------------+--------+----------+-----------+---------+------------------+----------------+----------+--------------------------------------------+------------+---------+-------------+-------------+------------+-------------------+---------------------+----------+----------------------------+---------------------+--------------------------+---------------------------------+-----------------------+------------------+------------------+---------------+---------+-------------------+---------------------------+---------------------+--------------+--------------------------+---------------------+---------------------+-----------------+-------+------------------+------------------------+--------------------+-----------------------------+

$ vtctldclient OnlineDDL show commerce recent
+--------------------------------------+----------+-------+--------------+-------------+--------------------------------+----------+---------+---------------------+---------------------+-----------------+---------------------+---------------------+---------------------+-------------------+----------+----------+-------------------------------------------------------------+---------+------------------+----------------+----------+---------------------------------------------+------------+---------+-------------+-------------+------------+-------------------+---------------------+----------+----------------------------+---------------------+--------------------------+---------------------------------+-----------------------+------------------+------------------+---------------+---------+-------------------+---------------------------+---------------------+--------------+--------------------------+---------------------+---------------------+-----------------+--------------------+------------------+------------------------+---------------------+-----------------------------+
|            migration_uuid            | keyspace | shard | mysql_schema | mysql_table |      migration_statement       | strategy | options |   added_timestamp   | requested_timestamp | ready_timestamp |  started_timestamp  | liveness_timestamp  | completed_timestamp | cleanup_timestamp |  status  | log_path |                          artifacts                          | retries |      tablet      | tablet_failure | progress |              migration_context              | ddl_action | message | eta_seconds | rows_copied | table_rows | added_unique_keys | removed_unique_keys | log_file | artifact_retention_seconds | postpone_completion | removed_unique_key_names | dropped_no_default_column_names | expanded_column_names | revertible_notes | allow_concurrent | reverted_uuid | is_view | ready_to_complete | vitess_liveness_indicator | user_throttle_ratio | special_plan | last_throttled_timestamp | component_throttled | cancelled_timestamp | postpone_launch |       stage        | cutover_attempts | is_immediate_operation | reviewed_timestamp  | ready_to_complete_timestamp |
+--------------------------------------+----------+-------+--------------+-------------+--------------------------------+----------+---------+---------------------+---------------------+-----------------+---------------------+---------------------+---------------------+-------------------+----------+----------+-------------------------------------------------------------+---------+------------------+----------------+----------+---------------------------------------------+------------+---------+-------------+-------------+------------+-------------------+---------------------+----------+----------------------------+---------------------+--------------------------+---------------------------------+-----------------------+------------------+------------------+---------------+---------+-------------------+---------------------------+---------------------+--------------+--------------------------+---------------------+---------------------+-----------------+--------------------+------------------+------------------------+---------------------+-----------------------------+
| d506b874_688a_11ee_8585_920702940ee0 | commerce |     0 | vt_commerce  | corder      | alter table corder add column  | vitess   |         | 2023-10-11 19:06:38 | 2023-10-11 19:06:38 |                 | 2023-10-11 19:06:39 | 2023-10-11 19:06:43 | 2023-10-11 19:06:44 |                   | complete |          | _d506b874_688a_11ee_8585_920702940ee0_20231011190639_vrepl, |       0 | zone1-0000000101 |                |      100 | vtgate:d416e16e-688a-11ee-8585-920702940ee0 | alter      |         |           0 |           0 |          0 |                 0 |                   0 |          |                      86400 |                     |                          |                                 |                       |                  |                  |               |         |                   |                1697065600 |                   0 |              |                          |                     |                     |                 | re-enabling writes |                1 |                        | 2023-10-11 19:06:39 | 2023-10-11 19:06:41         |
|                                      |          |       |              |             | ts timestamp not null default  |          |         |                     |                     |                 |                     |                     |                     |                   |          |          |                                                             |         |                  |                |          |                                             |            |         |             |             |            |                   |                     |          |                            |                     |                          |                                 |                       |                  |                  |               |         |                   |                           |                     |              |                          |                     |                     |                 |                    |                  |                        |                     |                             |
|                                      |          |       |              |             | current_timestamp()            |          |         |                     |                     |                 |                     |                     |                     |                   |          |          |                                                             |         |                  |                |          |                                             |            |         |             |             |            |                   |                     |          |                            |                     |                          |                                 |                       |                  |                  |               |         |                   |                           |                     |              |                          |                     |                     |                 |                    |                  |                        |                     |                             |
| d6089b8e_688a_11ee_8585_920702940ee0 | commerce |     0 | vt_commerce  | customer    | drop table customer            | vitess   |         | 2023-10-11 19:06:40 | 2023-10-11 19:06:40 |                 | 2023-10-11 19:06:46 | 2023-10-11 19:06:46 | 2023-10-11 19:06:46 |                   | complete |          | _vt_HOLD_d6089b8e688a11ee8585920702940ee0_20231012230646,   |       0 | zone1-0000000101 |                |      100 | vtgate:d416e16e-688a-11ee-8585-920702940ee0 | drop       |         |           0 |           0 |          0 |                 0 |                   0 |          |                      86400 |                     |                          |                                 |                       |                  |                  |               |         |                   |                         0 |                   0 |              |                          |                     |                     |                 |                    |                0 |                        | 2023-10-11 19:06:41 | 2023-10-11 19:06:41         |
| d7b265f0_688a_11ee_995e_920702940ee0 | commerce |     0 | vt_commerce  | demo        | alter table demo modify column | vitess   |         | 2023-10-11 19:06:42 | 2023-10-11 19:06:43 |                 |                     |                     |                     |                   | queued   |          |                                                             |       0 | zone1-0000000101 |                |        0 | vtctl:d7afce30-688a-11ee-995e-920702940ee0  | alter      |         |          -1 |           0 |          0 |                 0 |                   0 |          |                      86400 |                     |                          |                                 |                       |                  |                  |               |         |                   |                         0 |                   0 |              |                          |                     |                     |                 |                    |                0 |                        |                     |                             |
|                                      |          |       |              |             | id bigint unsigned             |          |         |                     |                     |                 |                     |                     |                     |                   |          |          |                                                             |         |                  |                |          |                                             |            |         |             |             |            |                   |                     |          |                            |                     |                          |                                 |                       |                  |                  |               |         |                   |                           |                     |              |                          |                     |                     |                 |                    |                  |                        |                     |                             |
| e1697214_688a_11ee_995e_920702940ee0 | commerce |     0 | vt_commerce  | demo        | alter table demo modify column | vitess   |         | 2023-10-11 19:06:59 | 2023-10-11 19:06:59 |                 |                     |                     |                     |                   | queued   |          |                                                             |       0 | zone1-0000000101 |                |        0 | vtctl:e1670c86-688a-11ee-995e-920702940ee0  | alter      |         |          -1 |           0 |          0 |                 0 |                   0 |          |                      86400 |                     |                          |                                 |                       |                  |                  |               |         |                   |                         0 |                   0 |              |                          |                     |                     |                 |                    |                0 |                        |                     |                             |
|                                      |          |       |              |             | id bigint unsigned             |          |         |                     |                     |                 |                     |                     |                     |                   |          |          |                                                             |         |                  |                |          |                                             |            |         |             |             |            |                   |                     |          |                            |                     |                          |                                 |                       |                  |                  |               |         |                   |                           |                     |              |                          |                     |                     |                 |                    |                  |                        |                     |                             |
| e16ab1e2_688a_11ee_995e_920702940ee0 | commerce |     0 | vt_commerce  | sample      | create table sample (          | vitess   |         | 2023-10-11 19:06:59 | 2023-10-11 19:06:59 |                 |                     |                     |                     |                   | queued   |          |                                                             |       0 | zone1-0000000101 |                |        0 | vtctl:e1670c86-688a-11ee-995e-920702940ee0  | create     |         |          -1 |           0 |          0 |                 0 |                   0 |          |                      86400 |                     |                          |                                 |                       |                  |                  |               |         |                   |                         0 |                   0 |              |                          |                     |                     |                 |                    |                0 |                        |                     |                             |
|                                      |          |       |              |             | 	id int primary key )           |          |         |                     |                     |                 |                     |                     |                     |                   |          |          |                                                             |         |                  |                |          |                                             |            |         |             |             |            |                   |                     |          |                            |                     |                          |                                 |                       |                  |                  |               |         |                   |                           |                     |              |                          |                     |                     |                 |                    |                  |                        |                     |                             |
| e16bd0c2_688a_11ee_995e_920702940ee0 | commerce |     0 | vt_commerce  | another     | drop table another             | vitess   |         | 2023-10-11 19:06:59 | 2023-10-11 19:06:59 |                 |                     |                     |                     |                   | queued   |          |                                                             |       0 | zone1-0000000101 |                |        0 | vtctl:e1670c86-688a-11ee-995e-920702940ee0  | drop       |         |          -1 |           0 |          0 |                 0 |                   0 |          |                      86400 |                     |                          |                                 |                       |                  |                  |               |         |                   |                         0 |                   0 |              |                          |                     |                     |                 |                    |                0 |                        |                     |                             |
+--------------------------------------+----------+-------+--------------+-------------+--------------------------------+----------+---------+---------------------+---------------------+-----------------+---------------------+---------------------+---------------------+-------------------+----------+----------+-------------------------------------------------------------+---------+------------------+----------------+----------+---------------------------------------------+------------+---------+-------------+-------------+------------+-------------------+---------------------+----------+----------------------------+---------------------+--------------------------+---------------------------------+-----------------------+------------------+------------------+---------------+---------+-------------------+---------------------------+---------------------+--------------+--------------------------+---------------------+---------------------+-----------------+--------------------+------------------+------------------------+---------------------+-----------------------------+

$ vtctldclient OnlineDDL show commerce all --order descending
+--------------------------------------+----------+-------+--------------+-------------+--------------------------------+----------+---------+---------------------+---------------------+-----------------+---------------------+---------------------+---------------------+-------------------+----------+----------+-------------------------------------------------------------+---------+------------------+----------------+----------+---------------------------------------------+------------+---------+-------------+-------------+------------+-------------------+---------------------+----------+----------------------------+---------------------+--------------------------+---------------------------------+-----------------------+------------------+------------------+---------------+---------+-------------------+---------------------------+---------------------+--------------+--------------------------+---------------------+---------------------+-----------------+--------------------+------------------+------------------------+---------------------+-----------------------------+
|            migration_uuid            | keyspace | shard | mysql_schema | mysql_table |      migration_statement       | strategy | options |   added_timestamp   | requested_timestamp | ready_timestamp |  started_timestamp  | liveness_timestamp  | completed_timestamp | cleanup_timestamp |  status  | log_path |                          artifacts                          | retries |      tablet      | tablet_failure | progress |              migration_context              | ddl_action | message | eta_seconds | rows_copied | table_rows | added_unique_keys | removed_unique_keys | log_file | artifact_retention_seconds | postpone_completion | removed_unique_key_names | dropped_no_default_column_names | expanded_column_names | revertible_notes | allow_concurrent | reverted_uuid | is_view | ready_to_complete | vitess_liveness_indicator | user_throttle_ratio | special_plan | last_throttled_timestamp | component_throttled | cancelled_timestamp | postpone_launch |       stage        | cutover_attempts | is_immediate_operation | reviewed_timestamp  | ready_to_complete_timestamp |
+--------------------------------------+----------+-------+--------------+-------------+--------------------------------+----------+---------+---------------------+---------------------+-----------------+---------------------+---------------------+---------------------+-------------------+----------+----------+-------------------------------------------------------------+---------+------------------+----------------+----------+---------------------------------------------+------------+---------+-------------+-------------+------------+-------------------+---------------------+----------+----------------------------+---------------------+--------------------------+---------------------------------+-----------------------+------------------+------------------+---------------+---------+-------------------+---------------------------+---------------------+--------------+--------------------------+---------------------+---------------------+-----------------+--------------------+------------------+------------------------+---------------------+-----------------------------+
| e16bd0c2_688a_11ee_995e_920702940ee0 | commerce |     0 | vt_commerce  | another     | drop table another             | vitess   |         | 2023-10-11 19:06:59 | 2023-10-11 19:06:59 |                 |                     |                     |                     |                   | queued   |          |                                                             |       0 | zone1-0000000101 |                |        0 | vtctl:e1670c86-688a-11ee-995e-920702940ee0  | drop       |         |          -1 |           0 |          0 |                 0 |                   0 |          |                      86400 |                     |                          |                                 |                       |                  |                  |               |         |                   |                         0 |                   0 |              |                          |                     |                     |                 |                    |                0 |                        |                     |                             |
| e16ab1e2_688a_11ee_995e_920702940ee0 | commerce |     0 | vt_commerce  | sample      | create table sample (          | vitess   |         | 2023-10-11 19:06:59 | 2023-10-11 19:06:59 |                 |                     |                     |                     |                   | queued   |          |                                                             |       0 | zone1-0000000101 |                |        0 | vtctl:e1670c86-688a-11ee-995e-920702940ee0  | create     |         |          -1 |           0 |          0 |                 0 |                   0 |          |                      86400 |                     |                          |                                 |                       |                  |                  |               |         |                   |                         0 |                   0 |              |                          |                     |                     |                 |                    |                0 |                        |                     |                             |
|                                      |          |       |              |             | 	id int primary key )           |          |         |                     |                     |                 |                     |                     |                     |                   |          |          |                                                             |         |                  |                |          |                                             |            |         |             |             |            |                   |                     |          |                            |                     |                          |                                 |                       |                  |                  |               |         |                   |                           |                     |              |                          |                     |                     |                 |                    |                  |                        |                     |                             |
| e1697214_688a_11ee_995e_920702940ee0 | commerce |     0 | vt_commerce  | demo        | alter table demo modify column | vitess   |         | 2023-10-11 19:06:59 | 2023-10-11 19:06:59 |                 |                     |                     |                     |                   | queued   |          |                                                             |       0 | zone1-0000000101 |                |        0 | vtctl:e1670c86-688a-11ee-995e-920702940ee0  | alter      |         |          -1 |           0 |          0 |                 0 |                   0 |          |                      86400 |                     |                          |                                 |                       |                  |                  |               |         |                   |                         0 |                   0 |              |                          |                     |                     |                 |                    |                0 |                        |                     |                             |
|                                      |          |       |              |             | id bigint unsigned             |          |         |                     |                     |                 |                     |                     |                     |                   |          |          |                                                             |         |                  |                |          |                                             |            |         |             |             |            |                   |                     |          |                            |                     |                          |                                 |                       |                  |                  |               |         |                   |                           |                     |              |                          |                     |                     |                 |                    |                  |                        |                     |                             |
| d7b265f0_688a_11ee_995e_920702940ee0 | commerce |     0 | vt_commerce  | demo        | alter table demo modify column | vitess   |         | 2023-10-11 19:06:42 | 2023-10-11 19:06:43 |                 |                     |                     |                     |                   | queued   |          |                                                             |       0 | zone1-0000000101 |                |        0 | vtctl:d7afce30-688a-11ee-995e-920702940ee0  | alter      |         |          -1 |           0 |          0 |                 0 |                   0 |          |                      86400 |                     |                          |                                 |                       |                  |                  |               |         |                   |                         0 |                   0 |              |                          |                     |                     |                 |                    |                0 |                        |                     |                             |
|                                      |          |       |              |             | id bigint unsigned             |          |         |                     |                     |                 |                     |                     |                     |                   |          |          |                                                             |         |                  |                |          |                                             |            |         |             |             |            |                   |                     |          |                            |                     |                          |                                 |                       |                  |                  |               |         |                   |                           |                     |              |                          |                     |                     |                 |                    |                  |                        |                     |                             |
| d6089b8e_688a_11ee_8585_920702940ee0 | commerce |     0 | vt_commerce  | customer    | drop table customer            | vitess   |         | 2023-10-11 19:06:40 | 2023-10-11 19:06:40 |                 | 2023-10-11 19:06:46 | 2023-10-11 19:06:46 | 2023-10-11 19:06:46 |                   | complete |          | _vt_HOLD_d6089b8e688a11ee8585920702940ee0_20231012230646,   |       0 | zone1-0000000101 |                |      100 | vtgate:d416e16e-688a-11ee-8585-920702940ee0 | drop       |         |           0 |           0 |          0 |                 0 |                   0 |          |                      86400 |                     |                          |                                 |                       |                  |                  |               |         |                   |                         0 |                   0 |              |                          |                     |                     |                 |                    |                0 |                        | 2023-10-11 19:06:41 | 2023-10-11 19:06:41         |
| d506b874_688a_11ee_8585_920702940ee0 | commerce |     0 | vt_commerce  | corder      | alter table corder add column  | vitess   |         | 2023-10-11 19:06:38 | 2023-10-11 19:06:38 |                 | 2023-10-11 19:06:39 | 2023-10-11 19:06:43 | 2023-10-11 19:06:44 |                   | complete |          | _d506b874_688a_11ee_8585_920702940ee0_20231011190639_vrepl, |       0 | zone1-0000000101 |                |      100 | vtgate:d416e16e-688a-11ee-8585-920702940ee0 | alter      |         |           0 |           0 |          0 |                 0 |                   0 |          |                      86400 |                     |                          |                                 |                       |                  |                  |               |         |                   |                1697065600 |                   0 |              |                          |                     |                     |                 | re-enabling writes |                1 |                        | 2023-10-11 19:06:39 | 2023-10-11 19:06:41         |
|                                      |          |       |              |             | ts timestamp not null default  |          |         |                     |                     |                 |                     |                     |                     |                   |          |          |                                                             |         |                  |                |          |                                             |            |         |             |             |            |                   |                     |          |                            |                     |                          |                                 |                       |                  |                  |               |         |                   |                           |                     |              |                          |                     |                     |                 |                    |                  |                        |                     |                             |
|                                      |          |       |              |             | current_timestamp()            |          |         |                     |                     |                 |                     |                     |                     |                   |          |          |                                                             |         |                  |                |          |                                             |            |         |             |             |            |                   |                     |          |                            |                     |                          |                                 |                       |                  |                  |               |         |                   |                           |                     |              |                          |                     |                     |                 |                    |                  |                        |                     |                             |
+--------------------------------------+----------+-------+--------------+-------------+--------------------------------+----------+---------+---------------------+---------------------+-----------------+---------------------+---------------------+---------------------+-------------------+----------+----------+-------------------------------------------------------------+---------+------------------+----------------+----------+---------------------------------------------+------------+---------+-------------+-------------+------------+-------------------+---------------------+----------+----------------------------+---------------------+--------------------------+---------------------------------+-----------------------+------------------+------------------+---------------+---------+-------------------+---------------------------+---------------------+--------------+--------------------------+---------------------+---------------------+-----------------+--------------------+------------------+------------------------+---------------------+-----------------------------+ 

$ vtctldclient OnlineDDL show commerce failed

$ vtctldclient OnlineDDL show commerce recent --limit 5                                                                                     ─╯
+--------------------------------------+----------+-------+--------------+-------------+--------------------------------+----------+---------+---------------------+---------------------+-----------------+---------------------+---------------------+---------------------+-------------------+----------+----------+-------------------------------------------------------------+---------+------------------+----------------+----------+---------------------------------------------+------------+---------+-------------+-------------+------------+-------------------+---------------------+----------+----------------------------+---------------------+--------------------------+---------------------------------+-----------------------+------------------+------------------+---------------+---------+-------------------+---------------------------+---------------------+--------------+--------------------------+---------------------+---------------------+-----------------+--------------------+------------------+------------------------+---------------------+-----------------------------+
|            migration_uuid            | keyspace | shard | mysql_schema | mysql_table |      migration_statement       | strategy | options |   added_timestamp   | requested_timestamp | ready_timestamp |  started_timestamp  | liveness_timestamp  | completed_timestamp | cleanup_timestamp |  status  | log_path |                          artifacts                          | retries |      tablet      | tablet_failure | progress |              migration_context              | ddl_action | message | eta_seconds | rows_copied | table_rows | added_unique_keys | removed_unique_keys | log_file | artifact_retention_seconds | postpone_completion | removed_unique_key_names | dropped_no_default_column_names | expanded_column_names | revertible_notes | allow_concurrent | reverted_uuid | is_view | ready_to_complete | vitess_liveness_indicator | user_throttle_ratio | special_plan | last_throttled_timestamp | component_throttled | cancelled_timestamp | postpone_launch |       stage        | cutover_attempts | is_immediate_operation | reviewed_timestamp  | ready_to_complete_timestamp |
+--------------------------------------+----------+-------+--------------+-------------+--------------------------------+----------+---------+---------------------+---------------------+-----------------+---------------------+---------------------+---------------------+-------------------+----------+----------+-------------------------------------------------------------+---------+------------------+----------------+----------+---------------------------------------------+------------+---------+-------------+-------------+------------+-------------------+---------------------+----------+----------------------------+---------------------+--------------------------+---------------------------------+-----------------------+------------------+------------------+---------------+---------+-------------------+---------------------------+---------------------+--------------+--------------------------+---------------------+---------------------+-----------------+--------------------+------------------+------------------------+---------------------+-----------------------------+
| d506b874_688a_11ee_8585_920702940ee0 | commerce |     0 | vt_commerce  | corder      | alter table corder add column  | vitess   |         | 2023-10-11 19:06:38 | 2023-10-11 19:06:38 |                 | 2023-10-11 19:06:39 | 2023-10-11 19:06:43 | 2023-10-11 19:06:44 |                   | complete |          | _d506b874_688a_11ee_8585_920702940ee0_20231011190639_vrepl, |       0 | zone1-0000000101 |                |      100 | vtgate:d416e16e-688a-11ee-8585-920702940ee0 | alter      |         |           0 |           0 |          0 |                 0 |                   0 |          |                      86400 |                     |                          |                                 |                       |                  |                  |               |         |                   |                1697065600 |                   0 |              |                          |                     |                     |                 | re-enabling writes |                1 |                        | 2023-10-11 19:06:39 | 2023-10-11 19:06:41         |
|                                      |          |       |              |             | ts timestamp not null default  |          |         |                     |                     |                 |                     |                     |                     |                   |          |          |                                                             |         |                  |                |          |                                             |            |         |             |             |            |                   |                     |          |                            |                     |                          |                                 |                       |                  |                  |               |         |                   |                           |                     |              |                          |                     |                     |                 |                    |                  |                        |                     |                             |
|                                      |          |       |              |             | current_timestamp()            |          |         |                     |                     |                 |                     |                     |                     |                   |          |          |                                                             |         |                  |                |          |                                             |            |         |             |             |            |                   |                     |          |                            |                     |                          |                                 |                       |                  |                  |               |         |                   |                           |                     |              |                          |                     |                     |                 |                    |                  |                        |                     |                             |
| d6089b8e_688a_11ee_8585_920702940ee0 | commerce |     0 | vt_commerce  | customer    | drop table customer            | vitess   |         | 2023-10-11 19:06:40 | 2023-10-11 19:06:40 |                 | 2023-10-11 19:06:46 | 2023-10-11 19:06:46 | 2023-10-11 19:06:46 |                   | complete |          | _vt_HOLD_d6089b8e688a11ee8585920702940ee0_20231012230646,   |       0 | zone1-0000000101 |                |      100 | vtgate:d416e16e-688a-11ee-8585-920702940ee0 | drop       |         |           0 |           0 |          0 |                 0 |                   0 |          |                      86400 |                     |                          |                                 |                       |                  |                  |               |         |                   |                         0 |                   0 |              |                          |                     |                     |                 |                    |                0 |                        | 2023-10-11 19:06:41 | 2023-10-11 19:06:41         |
| d7b265f0_688a_11ee_995e_920702940ee0 | commerce |     0 | vt_commerce  | demo        | alter table demo modify column | vitess   |         | 2023-10-11 19:06:42 | 2023-10-11 19:06:43 |                 |                     |                     |                     |                   | queued   |          |                                                             |       0 | zone1-0000000101 |                |        0 | vtctl:d7afce30-688a-11ee-995e-920702940ee0  | alter      |         |          -1 |           0 |          0 |                 0 |                   0 |          |                      86400 |                     |                          |                                 |                       |                  |                  |               |         |                   |                         0 |                   0 |              |                          |                     |                     |                 |                    |                0 |                        |                     |                             |
|                                      |          |       |              |             | id bigint unsigned             |          |         |                     |                     |                 |                     |                     |                     |                   |          |          |                                                             |         |                  |                |          |                                             |            |         |             |             |            |                   |                     |          |                            |                     |                          |                                 |                       |                  |                  |               |         |                   |                           |                     |              |                          |                     |                     |                 |                    |                  |                        |                     |                             |
| e1697214_688a_11ee_995e_920702940ee0 | commerce |     0 | vt_commerce  | demo        | alter table demo modify column | vitess   |         | 2023-10-11 19:06:59 | 2023-10-11 19:06:59 |                 |                     |                     |                     |                   | queued   |          |                                                             |       0 | zone1-0000000101 |                |        0 | vtctl:e1670c86-688a-11ee-995e-920702940ee0  | alter      |         |          -1 |           0 |          0 |                 0 |                   0 |          |                      86400 |                     |                          |                                 |                       |                  |                  |               |         |                   |                         0 |                   0 |              |                          |                     |                     |                 |                    |                0 |                        |                     |                             |
|                                      |          |       |              |             | id bigint unsigned             |          |         |                     |                     |                 |                     |                     |                     |                   |          |          |                                                             |         |                  |                |          |                                             |            |         |             |             |            |                   |                     |          |                            |                     |                          |                                 |                       |                  |                  |               |         |                   |                           |                     |              |                          |                     |                     |                 |                    |                  |                        |                     |                             |
| e16ab1e2_688a_11ee_995e_920702940ee0 | commerce |     0 | vt_commerce  | sample      | create table sample (          | vitess   |         | 2023-10-11 19:06:59 | 2023-10-11 19:06:59 |                 |                     |                     |                     |                   | queued   |          |                                                             |       0 | zone1-0000000101 |                |        0 | vtctl:e1670c86-688a-11ee-995e-920702940ee0  | create     |         |          -1 |           0 |          0 |                 0 |                   0 |          |                      86400 |                     |                          |                                 |                       |                  |                  |               |         |                   |                         0 |                   0 |              |                          |                     |                     |                 |                    |                0 |                        |                     |                             |
|                                      |          |       |              |             | 	id int primary key )           |          |         |                     |                     |                 |                     |                     |                     |                   |          |          |                                                             |         |                  |                |          |                                             |            |         |             |             |            |                   |                     |          |                            |                     |                          |                                 |                       |                  |                  |               |         |                   |                           |                     |              |                          |                     |                     |                 |                    |                  |                        |                     |                             |
+--------------------------------------+----------+-------+--------------+-------------+--------------------------------+----------+---------+---------------------+---------------------+-----------------+---------------------+---------------------+---------------------+-------------------+----------+----------+-------------------------------------------------------------+---------+------------------+----------------+----------+---------------------------------------------+------------+---------+-------------+-------------+------------+-------------------+---------------------+----------+----------------------------+---------------------+--------------------------+---------------------------------+-----------------------+------------------+------------------+---------------+---------+-------------------+---------------------------+---------------------+--------------+--------------------------+---------------------+---------------------+-----------------+--------------------+------------------+------------------------+---------------------+-----------------------------+ 

$ vtctldclient OnlineDDL show commerce recent --skip 5 --limit 5
+--------------------------------------+----------+-------+--------------+-------------+---------------------+----------+---------+---------------------+---------------------+-----------------+-------------------+--------------------+---------------------+-------------------+--------+----------+-----------+---------+------------------+----------------+----------+--------------------------------------------+------------+---------+-------------+-------------+------------+-------------------+---------------------+----------+----------------------------+---------------------+--------------------------+---------------------------------+-----------------------+------------------+------------------+---------------+---------+-------------------+---------------------------+---------------------+--------------+--------------------------+---------------------+---------------------+-----------------+-------+------------------+------------------------+--------------------+-----------------------------+
|            migration_uuid            | keyspace | shard | mysql_schema | mysql_table | migration_statement | strategy | options |   added_timestamp   | requested_timestamp | ready_timestamp | started_timestamp | liveness_timestamp | completed_timestamp | cleanup_timestamp | status | log_path | artifacts | retries |      tablet      | tablet_failure | progress |             migration_context              | ddl_action | message | eta_seconds | rows_copied | table_rows | added_unique_keys | removed_unique_keys | log_file | artifact_retention_seconds | postpone_completion | removed_unique_key_names | dropped_no_default_column_names | expanded_column_names | revertible_notes | allow_concurrent | reverted_uuid | is_view | ready_to_complete | vitess_liveness_indicator | user_throttle_ratio | special_plan | last_throttled_timestamp | component_throttled | cancelled_timestamp | postpone_launch | stage | cutover_attempts | is_immediate_operation | reviewed_timestamp | ready_to_complete_timestamp |
+--------------------------------------+----------+-------+--------------+-------------+---------------------+----------+---------+---------------------+---------------------+-----------------+-------------------+--------------------+---------------------+-------------------+--------+----------+-----------+---------+------------------+----------------+----------+--------------------------------------------+------------+---------+-------------+-------------+------------+-------------------+---------------------+----------+----------------------------+---------------------+--------------------------+---------------------------------+-----------------------+------------------+------------------+---------------+---------+-------------------+---------------------------+---------------------+--------------+--------------------------+---------------------+---------------------+-----------------+-------+------------------+------------------------+--------------------+-----------------------------+
| e16bd0c2_688a_11ee_995e_920702940ee0 | commerce |     0 | vt_commerce  | another     | drop table another  | vitess   |         | 2023-10-11 19:06:59 | 2023-10-11 19:06:59 |                 |                   |                    |                     |                   | queued |          |           |       0 | zone1-0000000101 |                |        0 | vtctl:e1670c86-688a-11ee-995e-920702940ee0 | drop       |         |          -1 |           0 |          0 |                 0 |                   0 |          |                      86400 |                     |                          |                                 |                       |                  |                  |               |         |                   |                         0 |                   0 |              |                          |                     |                     |                 |       |                0 |                        |                    |                             |
+--------------------------------------+----------+-------+--------------+-------------+---------------------+----------+---------+---------------------+---------------------+-----------------+-------------------+--------------------+---------------------+-------------------+--------+----------+-----------+---------+------------------+----------------+----------+--------------------------------------------+------------+---------+-------------+-------------+------------+-------------------+---------------------+----------+----------------------------+---------------------+--------------------------+---------------------------------+-----------------------+------------------+------------------+---------------+---------+-------------------+---------------------------+---------------------+--------------+--------------------------+---------------------+---------------------+-----------------+-------+------------------+------------------------+--------------------+-----------------------------+
```

The syntax for tracking migrations can be seen in [the reference docs](../../../reference/programs/vtctldclient/vtctldclient_onlineddl/vtctldclient_onlineddl_show/).


## Showing migration logs

`gh-ost` and `pt-osc` tools generate logs files, which are retrievable for `24` hours after migration completion/failure.

#### Via VTGate/SQL

```sql
mysql> show vitess_migration '3a273866_e867_11eb_ab12_0a43f95f28a3' logs \G
*************************** 1. row ***************************
migration_log: 2021-07-19 07:59:23 INFO starting gh-ost 261355426d8fc31b590733ca8ff8e79012103c18
2021-07-19 07:59:23 INFO Migrating `vt_commerce`.`corder`
2021-07-19 07:59:23 INFO executing gh-ost-on-startup hook: /tmp/online-ddl-3a273866_e867_11eb_ab12_0a43f95f28a3-943208852/gh-ost-on-startup
ok
2021-07-19 07:59:23 INFO inspector connection validated on ip-REDACTED:17100
2021-07-19 07:59:23 INFO User has SUPER, REPLICATION SLAVE privileges, and has ALL privileges on `vt_commerce`.*
2021-07-19 07:59:23 INFO binary logs validated on ip-REDACTED:17100
2021-07-19 07:59:23 INFO Restarting replication on ip-REDACTED:17100 to make sure binlog settings apply to replication thread
2021-07-19 07:59:23 INFO Inspector initiated on ip-REDACTED:17100, version 5.7.30-log
2021-07-19 07:59:23 INFO Table found. Engine=InnoDB
...
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

#### Via vtctldclient/ApplySchema

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

## Completing a migration

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

#### Via vtctldclient/ApplySchema

Complete a specific migration:

```shell
$ vtctldclient ApplySchema --sql "alter vitess_migration '9e8a9249_3976_11ed_9442_0a43f95f28a3' complete" commerce
```

Or complete all:

```shell
$ vtctldclient ApplySchema --sql "alter vitess_migration complete all" commerce
```

## Cancelling a migration

The user may cancel a migration, as follows:

- If the migration hasn't started yet (it is `queued` or `ready`), then it transitions into `cancelled` state and doesn't get executed.
- If the migration is `running`, then it is forcibly interrupted. The migration transitions to `cancelled` state.
- In all other cases, cancelling a migration has no effect.

#### Via VTGate/SQL

Examples for a single shard cluster:


```sql
                 id: 28
     migration_uuid: aa89f255_8d68_11eb_815f_f875a4d24e90
           keyspace: commerce
              shard: 0
       mysql_schema: vt_commerce
        mysql_table: corder
migration_statement: alter table corder add column handler_id int not null
           strategy: gh-ost
            options: 
    added_timestamp: 2021-03-25 14:50:27
requested_timestamp: 2021-03-25 14:50:24
    ready_timestamp: 2021-03-25 14:50:31
  started_timestamp: 2021-03-25 14:50:32
 liveness_timestamp: 2021-03-25 14:50:32
completed_timestamp: NULL
  cleanup_timestamp: NULL
   migration_status: running
...

mysql> alter vitess_migration 'aa89f255_8d68_11eb_815f_f875a4d24e90' cancel;
Query OK, 1 row affected (0.01 sec)

mysql> show vitess_migrations like 'aa89f255_8d68_11eb_815f_f875a4d24e90' \G
*************************** 1. row ***************************
                 id: 28
     migration_uuid: aa89f255_8d68_11eb_815f_f875a4d24e90
           keyspace: commerce
              shard: 0
       mysql_schema: vt_commerce
        mysql_table: corder
migration_statement: alter table corder add column handler_id int not null
           strategy: gh-ost
            options: --throttle-flag-file=/tmp/throttle.flag
    added_timestamp: 2021-03-25 14:50:27
requested_timestamp: 2021-03-25 14:50:24
    ready_timestamp: 2021-03-25 14:50:31
  started_timestamp: 2021-03-25 14:50:32
 liveness_timestamp: 2021-03-25 14:50:32
completed_timestamp: NULL
  cleanup_timestamp: NULL
   migration_status: cancelled
...
```

- `alter vitess_migration ... cancel` takes exactly one migration's UUID.
- `alter vitess_migration ... cancel` responds with number of affected migrations.

#### Via vtctldclient/ApplySchema

Examples for a 4-shard cluster:

```
vtctldclient OnlineDDL cancel <keyspace> <migration_id>
```

Example:

```shell
$ vtctldclient OnlineDDL show commerce e16bd0c2_688a_11ee_995e_920702940ee0
+--------------------------------------+----------+-------+--------------+-------------+---------------------+----------+---------+---------------------+---------------------+-----------------+-------------------+--------------------+---------------------+-------------------+--------+----------+-----------+---------+------------------+----------------+----------+--------------------------------------------+------------+---------+-------------+-------------+------------+-------------------+---------------------+----------+----------------------------+---------------------+--------------------------+---------------------------------+-----------------------+------------------+------------------+---------------+---------+-------------------+---------------------------+---------------------+--------------+--------------------------+---------------------+---------------------+-----------------+-------+------------------+------------------------+--------------------+-----------------------------+
|            migration_uuid            | keyspace | shard | mysql_schema | mysql_table | migration_statement | strategy | options |   added_timestamp   | requested_timestamp | ready_timestamp | started_timestamp | liveness_timestamp | completed_timestamp | cleanup_timestamp | status | log_path | artifacts | retries |      tablet      | tablet_failure | progress |             migration_context              | ddl_action | message | eta_seconds | rows_copied | table_rows | added_unique_keys | removed_unique_keys | log_file | artifact_retention_seconds | postpone_completion | removed_unique_key_names | dropped_no_default_column_names | expanded_column_names | revertible_notes | allow_concurrent | reverted_uuid | is_view | ready_to_complete | vitess_liveness_indicator | user_throttle_ratio | special_plan | last_throttled_timestamp | component_throttled | cancelled_timestamp | postpone_launch | stage | cutover_attempts | is_immediate_operation | reviewed_timestamp | ready_to_complete_timestamp |
+--------------------------------------+----------+-------+--------------+-------------+---------------------+----------+---------+---------------------+---------------------+-----------------+-------------------+--------------------+---------------------+-------------------+--------+----------+-----------+---------+------------------+----------------+----------+--------------------------------------------+------------+---------+-------------+-------------+------------+-------------------+---------------------+----------+----------------------------+---------------------+--------------------------+---------------------------------+-----------------------+------------------+------------------+---------------+---------+-------------------+---------------------------+---------------------+--------------+--------------------------+---------------------+---------------------+-----------------+-------+------------------+------------------------+--------------------+-----------------------------+
| e16bd0c2_688a_11ee_995e_920702940ee0 | commerce |     0 | vt_commerce  | another     | drop table another  | vitess   |         | 2023-10-11 19:06:59 | 2023-10-11 19:06:59 |                 |                   |                    |                     |                   | queued |          |           |       0 | zone1-0000000101 |                |        0 | vtctl:e1670c86-688a-11ee-995e-920702940ee0 | drop       |         |          -1 |           0 |          0 |                 0 |                   0 |          |                      86400 |                     |                          |                                 |                       |                  |                  |               |         |                   |                         0 |                   0 |              |                          |                     |                     |                 |       |                0 |                        |                    |                             |
+--------------------------------------+----------+-------+--------------+-------------+---------------------+----------+---------+---------------------+---------------------+-----------------+-------------------+--------------------+---------------------+-------------------+--------+----------+-----------+---------+------------------+----------------+----------+--------------------------------------------+------------+---------+-------------+-------------+------------+-------------------+---------------------+----------+----------------------------+---------------------+--------------------------+---------------------------------+-----------------------+------------------+------------------+---------------+---------+-------------------+---------------------------+---------------------+--------------+--------------------------+---------------------+---------------------+-----------------+-------+------------------+------------------------+--------------------+-----------------------------+

$ vtctldclient OnlineDDL cancel commerce e16bd0c2_688a_11ee_995e_920702940ee0
{
  "rows_affected_by_shard": {
    "0": "1"
  }
}

$ vtctldclient OnlineDDL show commerce e16bd0c2_688a_11ee_995e_920702940ee0
+--------------------------------------+----------+-------+--------------+-------------+---------------------+----------+---------+---------------------+---------------------+-----------------+-------------------+--------------------+---------------------+-------------------+-----------+----------+-----------+---------+------------------+----------------+----------+--------------------------------------------+------------+-----------------------+-------------+-------------+------------+-------------------+---------------------+----------+----------------------------+---------------------+--------------------------+---------------------------------+-----------------------+------------------+------------------+---------------+---------+-------------------+---------------------------+---------------------+--------------+--------------------------+---------------------+---------------------+-----------------+-------+------------------+------------------------+--------------------+-----------------------------+
|            migration_uuid            | keyspace | shard | mysql_schema | mysql_table | migration_statement | strategy | options |   added_timestamp   | requested_timestamp | ready_timestamp | started_timestamp | liveness_timestamp | completed_timestamp | cleanup_timestamp |  status   | log_path | artifacts | retries |      tablet      | tablet_failure | progress |             migration_context              | ddl_action |        message        | eta_seconds | rows_copied | table_rows | added_unique_keys | removed_unique_keys | log_file | artifact_retention_seconds | postpone_completion | removed_unique_key_names | dropped_no_default_column_names | expanded_column_names | revertible_notes | allow_concurrent | reverted_uuid | is_view | ready_to_complete | vitess_liveness_indicator | user_throttle_ratio | special_plan | last_throttled_timestamp | component_throttled | cancelled_timestamp | postpone_launch | stage | cutover_attempts | is_immediate_operation | reviewed_timestamp | ready_to_complete_timestamp |
+--------------------------------------+----------+-------+--------------+-------------+---------------------+----------+---------+---------------------+---------------------+-----------------+-------------------+--------------------+---------------------+-------------------+-----------+----------+-----------+---------+------------------+----------------+----------+--------------------------------------------+------------+-----------------------+-------------+-------------+------------+-------------------+---------------------+----------+----------------------------+---------------------+--------------------------+---------------------------------+-----------------------+------------------+------------------+---------------+---------+-------------------+---------------------------+---------------------+--------------+--------------------------+---------------------+---------------------+-----------------+-------+------------------+------------------------+--------------------+-----------------------------+
| e16bd0c2_688a_11ee_995e_920702940ee0 | commerce |     0 | vt_commerce  | another     | drop table another  | vitess   |         | 2023-10-11 19:06:59 | 2023-10-11 19:06:59 |                 |                   |                    | 2023-10-11 19:22:19 |                   | cancelled |          |           |       0 | zone1-0000000101 |                |        0 | vtctl:e1670c86-688a-11ee-995e-920702940ee0 | drop       | CANCEL issued by user |          -1 |           0 |          0 |                 0 |                   0 |          |                      86400 |                     |                          |                                 |                       |                  |                  |               |         |                   |                         0 |                   0 |              |                          |                     |                     |                 |       |                0 |                        |                    |                             |
+--------------------------------------+----------+-------+--------------+-------------+---------------------+----------+---------+---------------------+---------------------+-----------------+-------------------+--------------------+---------------------+-------------------+-----------+----------+-----------+---------+------------------+----------------+----------+--------------------------------------------+------------+-----------------------+-------------+-------------+------------+-------------------+---------------------+----------+----------------------------+---------------------+--------------------------+---------------------------------+-----------------------+------------------+------------------+---------------+---------+-------------------+---------------------------+---------------------+--------------+--------------------------+---------------------+---------------------+-----------------+-------+------------------+------------------------+--------------------+-----------------------------+
```


## Cancelling all keyspace migrations

The user may cancel all migrations in a keyspace. A migration is cancellable if it is in `queued`, `ready` or `running` states, as described previously. It is a high impact operation and should be used with care.

#### Via VTGate/SQL

Examples for a single shard cluster:

```sql
mysql> alter vitess_migration cancel all;
Query OK, 1 row affected (0.02 sec)
```

#### Via vtctldclient/ApplySchema

Examples for a 4-shard cluster:


```shell
$ vtctldclient ApplySchema --sql "alter vitess_migration cancel all" commerce
```

Also available via `vtctldclient OnlineDDL` command:

```
vtctldclient OnlineDDL cancel <keyspace> all
```

Example:

```shell
$ vtctldclient OnlineDDL show commerce all
+--------------------------------------+----------+-------+--------------+-------------+--------------------------------+----------+---------+---------------------+---------------------+-----------------+---------------------+---------------------+---------------------+-------------------+-----------+----------+-------------------------------------------------------------+---------+------------------+----------------+----------+---------------------------------------------+------------+---------------------------+-------------+-------------+------------+-------------------+---------------------+----------+----------------------------+---------------------+--------------------------+---------------------------------+-----------------------+------------------+------------------+---------------+---------+-------------------+---------------------------+---------------------+--------------+--------------------------+---------------------+---------------------+-----------------+--------------------+------------------+------------------------+---------------------+-----------------------------+
|            migration_uuid            | keyspace | shard | mysql_schema | mysql_table |      migration_statement       | strategy | options |   added_timestamp   | requested_timestamp | ready_timestamp |  started_timestamp  | liveness_timestamp  | completed_timestamp | cleanup_timestamp |  status   | log_path |                          artifacts                          | retries |      tablet      | tablet_failure | progress |              migration_context              | ddl_action |          message          | eta_seconds | rows_copied | table_rows | added_unique_keys | removed_unique_keys | log_file | artifact_retention_seconds | postpone_completion | removed_unique_key_names | dropped_no_default_column_names | expanded_column_names | revertible_notes | allow_concurrent | reverted_uuid | is_view | ready_to_complete | vitess_liveness_indicator | user_throttle_ratio | special_plan | last_throttled_timestamp | component_throttled | cancelled_timestamp | postpone_launch |       stage        | cutover_attempts | is_immediate_operation | reviewed_timestamp  | ready_to_complete_timestamp |
+--------------------------------------+----------+-------+--------------+-------------+--------------------------------+----------+---------+---------------------+---------------------+-----------------+---------------------+---------------------+---------------------+-------------------+-----------+----------+-------------------------------------------------------------+---------+------------------+----------------+----------+---------------------------------------------+------------+---------------------------+-------------+-------------+------------+-------------------+---------------------+----------+----------------------------+---------------------+--------------------------+---------------------------------+-----------------------+------------------+------------------+---------------+---------+-------------------+---------------------------+---------------------+--------------+--------------------------+---------------------+---------------------+-----------------+--------------------+------------------+------------------------+---------------------+-----------------------------+
| d506b874_688a_11ee_8585_920702940ee0 | commerce |     0 | vt_commerce  | corder      | alter table corder add column  | vitess   |         | 2023-10-11 19:06:38 | 2023-10-11 19:06:38 |                 | 2023-10-11 19:06:39 | 2023-10-11 19:06:43 | 2023-10-11 19:06:44 |                   | complete  |          | _d506b874_688a_11ee_8585_920702940ee0_20231011190639_vrepl, |       0 | zone1-0000000101 |                |      100 | vtgate:d416e16e-688a-11ee-8585-920702940ee0 | alter      |                           |           0 |           0 |          0 |                 0 |                   0 |          |                      86400 |                     |                          |                                 |                       |                  |                  |               |         |                   |                1697065600 |                   0 |              |                          |                     |                     |                 | re-enabling writes |                1 |                        | 2023-10-11 19:06:39 | 2023-10-11 19:06:41         |
|                                      |          |       |              |             | ts timestamp not null default  |          |         |                     |                     |                 |                     |                     |                     |                   |           |          |                                                             |         |                  |                |          |                                             |            |                           |             |             |            |                   |                     |          |                            |                     |                          |                                 |                       |                  |                  |               |         |                   |                           |                     |              |                          |                     |                     |                 |                    |                  |                        |                     |                             |
|                                      |          |       |              |             | current_timestamp()            |          |         |                     |                     |                 |                     |                     |                     |                   |           |          |                                                             |         |                  |                |          |                                             |            |                           |             |             |            |                   |                     |          |                            |                     |                          |                                 |                       |                  |                  |               |         |                   |                           |                     |              |                          |                     |                     |                 |                    |                  |                        |                     |                             |
| d6089b8e_688a_11ee_8585_920702940ee0 | commerce |     0 | vt_commerce  | customer    | drop table customer            | vitess   |         | 2023-10-11 19:06:40 | 2023-10-11 19:06:40 |                 | 2023-10-11 19:06:46 | 2023-10-11 19:06:46 | 2023-10-11 19:06:46 |                   | complete  |          | _vt_HOLD_d6089b8e688a11ee8585920702940ee0_20231012230646,   |       0 | zone1-0000000101 |                |      100 | vtgate:d416e16e-688a-11ee-8585-920702940ee0 | drop       |                           |           0 |           0 |          0 |                 0 |                   0 |          |                      86400 |                     |                          |                                 |                       |                  |                  |               |         |                   |                         0 |                   0 |              |                          |                     |                     |                 |                    |                0 |                        | 2023-10-11 19:06:41 | 2023-10-11 19:06:41         |
| d7b265f0_688a_11ee_995e_920702940ee0 | commerce |     0 | vt_commerce  | demo        | alter table demo modify column | vitess   |         | 2023-10-11 19:06:42 | 2023-10-11 19:06:43 |                 |                     |                     | 2023-10-11 19:23:44 |                   | cancelled |          |                                                             |       0 | zone1-0000000101 |                |        0 | vtctl:d7afce30-688a-11ee-995e-920702940ee0  | alter      | CANCEL ALL issued by user |          -1 |           0 |          0 |                 0 |                   0 |          |                      86400 |                     |                          |                                 |                       |                  |                  |               |         |                   |                         0 |                   0 |              |                          |                     |                     |                 |                    |                0 |                        |                     |                             |
|                                      |          |       |              |             | id bigint unsigned             |          |         |                     |                     |                 |                     |                     |                     |                   |           |          |                                                             |         |                  |                |          |                                             |            |                           |             |             |            |                   |                     |          |                            |                     |                          |                                 |                       |                  |                  |               |         |                   |                           |                     |              |                          |                     |                     |                 |                    |                  |                        |                     |                             |
| e1697214_688a_11ee_995e_920702940ee0 | commerce |     0 | vt_commerce  | demo        | alter table demo modify column | vitess   |         | 2023-10-11 19:06:59 | 2023-10-11 19:06:59 |                 |                     |                     | 2023-10-11 19:23:44 |                   | cancelled |          |                                                             |       0 | zone1-0000000101 |                |        0 | vtctl:e1670c86-688a-11ee-995e-920702940ee0  | alter      | CANCEL ALL issued by user |          -1 |           0 |          0 |                 0 |                   0 |          |                      86400 |                     |                          |                                 |                       |                  |                  |               |         |                   |                         0 |                   0 |              |                          |                     |                     |                 |                    |                0 |                        |                     |                             |
|                                      |          |       |              |             | id bigint unsigned             |          |         |                     |                     |                 |                     |                     |                     |                   |           |          |                                                             |         |                  |                |          |                                             |            |                           |             |             |            |                   |                     |          |                            |                     |                          |                                 |                       |                  |                  |               |         |                   |                           |                     |              |                          |                     |                     |                 |                    |                  |                        |                     |                             |
| e16ab1e2_688a_11ee_995e_920702940ee0 | commerce |     0 | vt_commerce  | sample      | create table sample (          | vitess   |         | 2023-10-11 19:06:59 | 2023-10-11 19:06:59 |                 |                     |                     | 2023-10-11 19:23:44 |                   | cancelled |          |                                                             |       0 | zone1-0000000101 |                |        0 | vtctl:e1670c86-688a-11ee-995e-920702940ee0  | create     | CANCEL ALL issued by user |          -1 |           0 |          0 |                 0 |                   0 |          |                      86400 |                     |                          |                                 |                       |                  |                  |               |         |                   |                         0 |                   0 |              |                          |                     |                     |                 |                    |                0 |                        |                     |                             |
|                                      |          |       |              |             | 	id int primary key )           |          |         |                     |                     |                 |                     |                     |                     |                   |           |          |                                                             |         |                  |                |          |                                             |            |                           |             |             |            |                   |                     |          |                            |                     |                          |                                 |                       |                  |                  |               |         |                   |                           |                     |              |                          |                     |                     |                 |                    |                  |                        |                     |                             |
| e16bd0c2_688a_11ee_995e_920702940ee0 | commerce |     0 | vt_commerce  | another     | drop table another             | vitess   |         | 2023-10-11 19:06:59 | 2023-10-11 19:06:59 |                 |                     |                     | 2023-10-11 19:22:19 |                   | cancelled |          |                                                             |       0 | zone1-0000000101 |                |        0 | vtctl:e1670c86-688a-11ee-995e-920702940ee0  | drop       | CANCEL issued by user     |          -1 |           0 |          0 |                 0 |                   0 |          |                      86400 |                     |                          |                                 |                       |                  |                  |               |         |                   |                         0 |                   0 |              |                          |                     |                     |                 |                    |                0 |                        |                     |                             |
+--------------------------------------+----------+-------+--------------+-------------+--------------------------------+----------+---------+---------------------+---------------------+-----------------+---------------------+---------------------+---------------------+-------------------+-----------+----------+-------------------------------------------------------------+---------+------------------+----------------+----------+---------------------------------------------+------------+---------------------------+-------------+-------------+------------+-------------------+---------------------+----------+----------------------------+---------------------+--------------------------+---------------------------------+-----------------------+------------------+------------------+---------------+---------+-------------------+---------------------------+---------------------+--------------+--------------------------+---------------------+---------------------+-----------------+--------------------+------------------+------------------------+---------------------+-----------------------------+

$ vtctldclient OnlineDDL cancel commerce all
{
  "rows_affected_by_shard": {
    "0": "0"
  }
}

$ vtctldclient OnlineDDL show commerce all
+--------------------------------------+----------+-------+--------------+-------------+--------------------------------+----------+---------+---------------------+---------------------+-----------------+---------------------+---------------------+---------------------+-------------------+-----------+----------+-------------------------------------------------------------+---------+------------------+----------------+----------+---------------------------------------------+------------+---------------------------+-------------+-------------+------------+-------------------+---------------------+----------+----------------------------+---------------------+--------------------------+---------------------------------+-----------------------+------------------+------------------+---------------+---------+-------------------+---------------------------+---------------------+--------------+--------------------------+---------------------+---------------------+-----------------+--------------------+------------------+------------------------+---------------------+-----------------------------+
|            migration_uuid            | keyspace | shard | mysql_schema | mysql_table |      migration_statement       | strategy | options |   added_timestamp   | requested_timestamp | ready_timestamp |  started_timestamp  | liveness_timestamp  | completed_timestamp | cleanup_timestamp |  status   | log_path |                          artifacts                          | retries |      tablet      | tablet_failure | progress |              migration_context              | ddl_action |          message          | eta_seconds | rows_copied | table_rows | added_unique_keys | removed_unique_keys | log_file | artifact_retention_seconds | postpone_completion | removed_unique_key_names | dropped_no_default_column_names | expanded_column_names | revertible_notes | allow_concurrent | reverted_uuid | is_view | ready_to_complete | vitess_liveness_indicator | user_throttle_ratio | special_plan | last_throttled_timestamp | component_throttled | cancelled_timestamp | postpone_launch |       stage        | cutover_attempts | is_immediate_operation | reviewed_timestamp  | ready_to_complete_timestamp |
+--------------------------------------+----------+-------+--------------+-------------+--------------------------------+----------+---------+---------------------+---------------------+-----------------+---------------------+---------------------+---------------------+-------------------+-----------+----------+-------------------------------------------------------------+---------+------------------+----------------+----------+---------------------------------------------+------------+---------------------------+-------------+-------------+------------+-------------------+---------------------+----------+----------------------------+---------------------+--------------------------+---------------------------------+-----------------------+------------------+------------------+---------------+---------+-------------------+---------------------------+---------------------+--------------+--------------------------+---------------------+---------------------+-----------------+--------------------+------------------+------------------------+---------------------+-----------------------------+
| d506b874_688a_11ee_8585_920702940ee0 | commerce |     0 | vt_commerce  | corder      | alter table corder add column  | vitess   |         | 2023-10-11 19:06:38 | 2023-10-11 19:06:38 |                 | 2023-10-11 19:06:39 | 2023-10-11 19:06:43 | 2023-10-11 19:06:44 |                   | complete  |          | _d506b874_688a_11ee_8585_920702940ee0_20231011190639_vrepl, |       0 | zone1-0000000101 |                |      100 | vtgate:d416e16e-688a-11ee-8585-920702940ee0 | alter      |                           |           0 |           0 |          0 |                 0 |                   0 |          |                      86400 |                     |                          |                                 |                       |                  |                  |               |         |                   |                1697065600 |                   0 |              |                          |                     |                     |                 | re-enabling writes |                1 |                        | 2023-10-11 19:06:39 | 2023-10-11 19:06:41         |
|                                      |          |       |              |             | ts timestamp not null default  |          |         |                     |                     |                 |                     |                     |                     |                   |           |          |                                                             |         |                  |                |          |                                             |            |                           |             |             |            |                   |                     |          |                            |                     |                          |                                 |                       |                  |                  |               |         |                   |                           |                     |              |                          |                     |                     |                 |                    |                  |                        |                     |                             |
|                                      |          |       |              |             | current_timestamp()            |          |         |                     |                     |                 |                     |                     |                     |                   |           |          |                                                             |         |                  |                |          |                                             |            |                           |             |             |            |                   |                     |          |                            |                     |                          |                                 |                       |                  |                  |               |         |                   |                           |                     |              |                          |                     |                     |                 |                    |                  |                        |                     |                             |
| d6089b8e_688a_11ee_8585_920702940ee0 | commerce |     0 | vt_commerce  | customer    | drop table customer            | vitess   |         | 2023-10-11 19:06:40 | 2023-10-11 19:06:40 |                 | 2023-10-11 19:06:46 | 2023-10-11 19:06:46 | 2023-10-11 19:06:46 |                   | complete  |          | _vt_HOLD_d6089b8e688a11ee8585920702940ee0_20231012230646,   |       0 | zone1-0000000101 |                |      100 | vtgate:d416e16e-688a-11ee-8585-920702940ee0 | drop       |                           |           0 |           0 |          0 |                 0 |                   0 |          |                      86400 |                     |                          |                                 |                       |                  |                  |               |         |                   |                         0 |                   0 |              |                          |                     |                     |                 |                    |                0 |                        | 2023-10-11 19:06:41 | 2023-10-11 19:06:41         |
| d7b265f0_688a_11ee_995e_920702940ee0 | commerce |     0 | vt_commerce  | demo        | alter table demo modify column | vitess   |         | 2023-10-11 19:06:42 | 2023-10-11 19:06:43 |                 |                     |                     | 2023-10-11 19:23:44 |                   | cancelled |          |                                                             |       0 | zone1-0000000101 |                |        0 | vtctl:d7afce30-688a-11ee-995e-920702940ee0  | alter      | CANCEL ALL issued by user |          -1 |           0 |          0 |                 0 |                   0 |          |                      86400 |                     |                          |                                 |                       |                  |                  |               |         |                   |                         0 |                   0 |              |                          |                     |                     |                 |                    |                0 |                        |                     |                             |
|                                      |          |       |              |             | id bigint unsigned             |          |         |                     |                     |                 |                     |                     |                     |                   |           |          |                                                             |         |                  |                |          |                                             |            |                           |             |             |            |                   |                     |          |                            |                     |                          |                                 |                       |                  |                  |               |         |                   |                           |                     |              |                          |                     |                     |                 |                    |                  |                        |                     |                             |
| e1697214_688a_11ee_995e_920702940ee0 | commerce |     0 | vt_commerce  | demo        | alter table demo modify column | vitess   |         | 2023-10-11 19:06:59 | 2023-10-11 19:06:59 |                 |                     |                     | 2023-10-11 19:23:44 |                   | cancelled |          |                                                             |       0 | zone1-0000000101 |                |        0 | vtctl:e1670c86-688a-11ee-995e-920702940ee0  | alter      | CANCEL ALL issued by user |          -1 |           0 |          0 |                 0 |                   0 |          |                      86400 |                     |                          |                                 |                       |                  |                  |               |         |                   |                         0 |                   0 |              |                          |                     |                     |                 |                    |                0 |                        |                     |                             |
|                                      |          |       |              |             | id bigint unsigned             |          |         |                     |                     |                 |                     |                     |                     |                   |           |          |                                                             |         |                  |                |          |                                             |            |                           |             |             |            |                   |                     |          |                            |                     |                          |                                 |                       |                  |                  |               |         |                   |                           |                     |              |                          |                     |                     |                 |                    |                  |                        |                     |                             |
| e16ab1e2_688a_11ee_995e_920702940ee0 | commerce |     0 | vt_commerce  | sample      | create table sample (          | vitess   |         | 2023-10-11 19:06:59 | 2023-10-11 19:06:59 |                 |                     |                     | 2023-10-11 19:23:44 |                   | cancelled |          |                                                             |       0 | zone1-0000000101 |                |        0 | vtctl:e1670c86-688a-11ee-995e-920702940ee0  | create     | CANCEL ALL issued by user |          -1 |           0 |          0 |                 0 |                   0 |          |                      86400 |                     |                          |                                 |                       |                  |                  |               |         |                   |                         0 |                   0 |              |                          |                     |                     |                 |                    |                0 |                        |                     |                             |
|                                      |          |       |              |             | 	id int primary key )           |          |         |                     |                     |                 |                     |                     |                     |                   |           |          |                                                             |         |                  |                |          |                                             |            |                           |             |             |            |                   |                     |          |                            |                     |                          |                                 |                       |                  |                  |               |         |                   |                           |                     |              |                          |                     |                     |                 |                    |                  |                        |                     |                             |
| e16bd0c2_688a_11ee_995e_920702940ee0 | commerce |     0 | vt_commerce  | another     | drop table another             | vitess   |         | 2023-10-11 19:06:59 | 2023-10-11 19:06:59 |                 |                     |                     | 2023-10-11 19:22:19 |                   | cancelled |          |                                                             |       0 | zone1-0000000101 |                |        0 | vtctl:e1670c86-688a-11ee-995e-920702940ee0  | drop       | CANCEL issued by user     |          -1 |           0 |          0 |                 0 |                   0 |          |                      86400 |                     |                          |                                 |                       |                  |                  |               |         |                   |                         0 |                   0 |              |                          |                     |                     |                 |                    |                0 |                        |                     |                             |
+--------------------------------------+----------+-------+--------------+-------------+--------------------------------+----------+---------+---------------------+---------------------+-----------------+---------------------+---------------------+---------------------+-------------------+-----------+----------+-------------------------------------------------------------+---------+------------------+----------------+----------+---------------------------------------------+------------+---------------------------+-------------+-------------+------------+-------------------+---------------------+----------+----------------------------+---------------------+--------------------------+---------------------------------+-----------------------+------------------+------------------+---------------+---------+-------------------+---------------------------+---------------------+--------------+--------------------------+---------------------+---------------------+-----------------+--------------------+------------------+------------------------+---------------------+-----------------------------+
```

## Retrying a migration

The user may retry running a migration. If the migration is in `failed` or in `cancelled` state, Vitess will re-run the migration, with exact same arguments as previously intended. If the migration is in any other state, `retry` does nothing.

It is not possible to retry a migration with different options. e.g. if the user initially runs `ALTER TABLE demo MODIFY id BIGINT` with `@@ddl_strategy='gh-ost --max-load Threads_running=200'` and the migration fails, retrying it will use exact same options. It is not possible to retry with `@@ddl_strategy='gh-ost --max-load Threads_running=500'`.

#### Via VTGate/SQL

Examples for a single shard cluster:

```sql
*************************** 1. row ***************************
                 id: 28
     migration_uuid: aa89f255_8d68_11eb_815f_f875a4d24e90
           keyspace: commerce
              shard: 0
       mysql_schema: vt_commerce
        mysql_table: corder
migration_statement: alter table corder add column handler_id int not null
           strategy: gh-ost
            options: --throttle-flag-file=/tmp/throttle.flag
    added_timestamp: 2021-03-25 14:50:27
requested_timestamp: 2021-03-25 14:50:24
    ready_timestamp: 2021-03-25 14:56:22
  started_timestamp: 2021-03-25 14:56:22
 liveness_timestamp: 2021-03-25 14:56:22
completed_timestamp: NULL
  cleanup_timestamp: NULL
   migration_status: failed
...

mysql> alter vitess_migration 'aa89f255_8d68_11eb_815f_f875a4d24e90' retry;
Query OK, 1 row affected (0.00 sec)

mysql> show vitess_migrations like 'aa89f255_8d68_11eb_815f_f875a4d24e90' \G
*************************** 1. row ***************************
                 id: 28
     migration_uuid: aa89f255_8d68_11eb_815f_f875a4d24e90
           keyspace: commerce
              shard: 0
       mysql_schema: vt_commerce
        mysql_table: corder
migration_statement: alter table corder add column handler_id int not null
           strategy: gh-ost
            options: --throttle-flag-file=/tmp/throttle.flag
    added_timestamp: 2021-03-25 14:50:27
requested_timestamp: 2021-03-25 14:50:24
    ready_timestamp: 2021-03-25 14:56:42
  started_timestamp: 2021-03-25 14:56:42
 liveness_timestamp: 2021-03-25 14:56:42
completed_timestamp: NULL
  cleanup_timestamp: NULL
   migration_status: running
...
```
- `alter vitess_migration ... retry` takes exactly one migration's UUID.
- `alter vitess_migration ... retry` responds with number of affected migrations.

#### Via vtctldclient/ApplySchema


```shell
$ vtctldclient ApplySchema --sql "alter vitess_migration '2201058f_f266_11ea_bab4_0242c0a8b007' retry" commerce
```

Also available via `vtctldclient OnlineDDL` command:

Examples for a 4-shard cluster:

```shell
$ vtctldclient OnlineDDL show commerce 2201058f_f266_11ea_bab4_0242c0a8b007
+-----------------+-------+--------------+-------------+------------+--------------------------------------+----------+---------------------+---------------------+------------------+
|     Tablet      | shard | mysql_schema | mysql_table | ddl_action |            migration_uuid            | strategy |  started_timestamp  | completed_timestamp | migration_status |
+-----------------+-------+--------------+-------------+------------+--------------------------------------+----------+---------------------+---------------------+------------------+
| test-0000000401 | c0-   | vt_commerce  | demo        | alter      | 2201058f_f266_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 06:32:31 |                     | failed           |
| test-0000000301 | 80-c0 | vt_commerce  | demo        | alter      | 2201058f_f266_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 06:32:31 |                     | failed           |
| test-0000000201 | 40-80 | vt_commerce  | demo        | alter      | 2201058f_f266_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 06:32:31 |                     | failed           |
| test-0000000101 |   -40 | vt_commerce  | demo        | alter      | 2201058f_f266_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 06:32:31 |                     | failed           |
+-----------------+-------+--------------+-------------+------------+--------------------------------------+----------+---------------------+---------------------+------------------+

$ vtctldclient OnlineDDL retry commerce 2201058f_f266_11ea_bab4_0242c0a8b007

$ vtctldclient OnlineDDL show commerce 2201058f_f266_11ea_bab4_0242c0a8b007
+-----------------+-------+--------------+-------------+------------+--------------------------------------+----------+-------------------+---------------------+------------------+
|     Tablet      | shard | mysql_schema | mysql_table | ddl_action |            migration_uuid            | strategy | started_timestamp | completed_timestamp | migration_status |
+-----------------+-------+--------------+-------------+------------+--------------------------------------+----------+-------------------+---------------------+------------------+
| test-0000000201 | 40-80 | vt_commerce  | demo        | alter      | 2201058f_f266_11ea_bab4_0242c0a8b007 | online   |                   |                     | queued           |
| test-0000000101 |   -40 | vt_commerce  | demo        | alter      | 2201058f_f266_11ea_bab4_0242c0a8b007 | online   |                   |                     | queued           |
| test-0000000301 | 80-c0 | vt_commerce  | demo        | alter      | 2201058f_f266_11ea_bab4_0242c0a8b007 | online   |                   |                     | queued           |
| test-0000000401 | c0-   | vt_commerce  | demo        | alter      | 2201058f_f266_11ea_bab4_0242c0a8b007 | online   |                   |                     | queued           |
+-----------------+-------+--------------+-------------+------------+--------------------------------------+----------+-------------------+---------------------+------------------+

$ vtctldclient OnlineDDL show commerce 2201058f_f266_11ea_bab4_0242c0a8b007
+-----------------+-------+--------------+-------------+------------+--------------------------------------+----------+---------------------+---------------------+------------------+
|     Tablet      | shard | mysql_schema | mysql_table | ddl_action |            migration_uuid            | strategy |  started_timestamp  | completed_timestamp | migration_status |
+-----------------+-------+--------------+-------------+------------+--------------------------------------+----------+---------------------+---------------------+------------------+
| test-0000000101 |   -40 | vt_commerce  | demo        | alter      | 2201058f_f266_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 06:37:33 |                     | running          |
| test-0000000401 | c0-   | vt_commerce  | demo        | alter      | 2201058f_f266_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 06:37:33 |                     | running          |
| test-0000000201 | 40-80 | vt_commerce  | demo        | alter      | 2201058f_f266_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 06:37:33 |                     | running          |
| test-0000000301 | 80-c0 | vt_commerce  | demo        | alter      | 2201058f_f266_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 06:37:33 |                     | running          |
+-----------------+-------+--------------+-------------+------------+--------------------------------------+----------+---------------------+---------------------+------------------+
```

## Cleaning migration artifacts

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


#### Via vtctldclient/ApplySchema

Execute via `vtctldclient ApplySchema --sql "..." <keyspace>` like previous commands, or use `OnlineDDL` command:


```shell
$ vtctldclient OnlineDDL cleanup commerce 2201058f_f266_11ea_bab4_0242c0a8b007
```

## Reverting a migration

Vitess offers _lossless revert_ for online schema migrations: the user may regret a table migration after completion, and roll back the table's schema to previous state _without loss of data_. See [Revertible Migrations](../revertible-migrations/).

### Via VTGate/SQL

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

### Via vtctldclient/ApplySchema

```sh
$ vtctldclient ApplySchema --ddl-strategy "vitess" --sql "revert vitess_migration '1a689113_8d77_11eb_815f_f875a4d24e90'" commerce
```

## Controlling throttling

Managed migrations [use](../managed-online-schema-changes/#throttling) the [tablet throttler](../../../reference/features/tablet-throttler/) to ensure a sustainable impact to the MySQL servers and replication stream. Normally, the user doesn't need to get involved, as the throttler auto-identifies load scenarios, and pushes back on migration progress. However, Vitess makes available these commands for additional control over migration throttling:

```sql
alter vitess_migration '<uuid>' throttle [expire '<duration>'] [ratio <ratio>];
alter vitess_migration throttle all [expire '<duration>'] [ratio <ratio>];
alter vitess_migration '<uuid>' unthrottle;
alter vitess_migration unthrottle all;
show vitess_throttled_apps;
```

**Note:** the tablet throttler must be enabled for these command to run.

### Throttling a migration

To fully throttle a migration, run:

```sql
mysql> alter vitess_migration 'aa89f255_8d68_11eb_815f_f875a4d24e90' throttle;
Query OK, 1 row affected (0.00 sec)
```

From this point on, the migration will not make row copy progress and will not apply binary logs. By default, this command does not expire, and it takes an explicit `unthrottle` command to resume migration progress. Because MySQL binary logs are rotated, a migration may only survive a full throttling up to the point where the binary log it last processed is purged.

You may supply either or both these options: `expire`, `ratio`:

- `alter vitess_migration 'aa89f255_8d68_11eb_815f_f875a4d24e90' throttle expire '2h'` will fully throttle the migration for the next `2` hours, after which the migration resumes normal work. You may specify these units: `s` (seconds), `m` (minutes), `h` (hours) or combinations. Example values: `90s`, `30m`, `1h`, `1h30m`, etc.
- `alter vitess_migration 'aa89f255_8d68_11eb_815f_f875a4d24e90' throttle ratio 0.7` will partially throttle the migration. This instructs the throttler to reject, on average, `7` migration throttling check requests out of `10`. Any value between `0` (no throttling at all) and `1.0` (fully throttled) are allowed. This is a fine tune way to slow down a migration.

### Throttling all migrations

It's likely that you will want to throttle migrations in general, and not a specific migration. Use:

- `alter vitess_migration throttle all;` to fully throttle any and all migrations from this point on
- `alter vitess_migration throttle all expire '90m';` to fully throttle any and all migrations from this point on and for the next `90` minutes.
- `alter vitess_migration throttle all ratio 0.8;` to severely slow down all migrations from this point on (4 out of 5 migrations requests to the throttler are denied)
- `alter vitess_migration throttle all duration '10m' ratio 0.2;` to lightly slow down all migrations from this point on (1 out of 5 migrations requests to the throttler are denied) for the next `10` minutes.

### Unthrottling

Use:

- `alter vitess_migration 'aa89f255_8d68_11eb_815f_f875a4d24e90' unthrottle;` to allow the specified migration to resume working as normal
- `alter vitess_migration unthrottle all;` to unthrottle all migrations.

**Note** that this does not disable throttling altogether. If, for example, replication lag grows on replicas, the throttler may still throttle the migration until replication is caught up. Unthrottling only cancels an explicit throttling request as described above.

### Showing throttled apps

The command `show vitess_throttled_apps;` is a general purpose throttler command, and shows all apps for which there are throttling rules. It will list any specific or general migration throttling status.

### Via vtctldclient/ApplySchema

Execute via `vtctldclient ApplySchema --sql "..." <keyspace>` like previous commands, or use `OnlineDDL` commands:


```shell
$ vtctldclient OnlineDDL throttle commerce 2201058f_f266_11ea_bab4_0242c0a8b007
$ vtctldclient OnlineDDL throttle commerce all
$ vtctldclient OnlineDDL unthrottle commerce 2201058f_f266_11ea_bab4_0242c0a8b007
$ vtctldclient OnlineDDL unthrottle commerce all
```
