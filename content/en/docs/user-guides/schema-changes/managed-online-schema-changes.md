---
title: Managed, Online Schema Changes
weight: 2
aliases: ['/docs/user-guides/managed-online-schema-changes/']
---

**Note:** this feature is **EXPERIMENTAL**.

Vitess offers managed, online schema migrations (aka Online DDL), transparently to the user. Vitess supports `CREATE`, `ALTER` and `DROP` statements, all non-blocking, auto scheduled and auditable. As general overview:

- User chooses a [strategy](../ddl-strategies) for online DDL (online DDL is opt in)
- User submits one or more schema change queries, using the standard MySQL `CREATE TABLE`, `ALTER TABLE` and `DROP TABLE` syntax.
- Vitess responds with a Job ID for each schema change query.
- Vitess resolves affected shards.
- A shard's `primary` tablet schedules the migration to run when possible.
- Tablets will independently run schema migrations:
  - `ALTER TABLE` statements run via `VReplication`, `gh-ost` or `pt-online-schema-change`, as per selected [strategy](../ddl-strategies)
  - `CREATE TABLE` statements run directly.
  - `DROP TABLE` statements run [safely and lazily](../../../reference/features/table-lifecycle/).
- Vitess provides the user a mechanism to view migration status, cancel or retry migrations, based on the job ID.

## Syntax

The standard MySQL syntax for `CREATE`, `ALTER` and `DROP` is supported.

### ALTER TABLE

Use the standard MySQL `ALTER TABLE` syntax to run online DDL. Whether your schema migration runs synchronously (the default MySQL behavior) or asynchronously (aka online), is determined by the value of command line flags or a session variable.

We assume we have a keyspace (schema) called `commerce`, with a table called `demo`, that has the following definition:

```sql
CREATE TABLE `demo` (
  `id` int NOT NULL,
  `status` varchar(32) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB
```

Consider the following schema migration statement:
```sql
ALTER TABLE demo MODIFY id bigint UNSIGNED;
```

This statement can be executed as:

- a `VReplication`, managed online migration
- a `gh-ost`, managed online migration
- a `pt-online-schema-change`, managed online migration
- a synchronous, [unmanaged schema change](../unmanaged-schema-changes/)

See [DDL Strategies](../ddl-strategies) for discussion around the different options.

### CREATE TABLE

Use the standard MySQL `CREATE TABLE` syntax. The query goes through the same [migration flow](#migration-flow-and-states) as `ALTER TABLE` does. The tablets eventually run the query directly on the MySQL backends.

### DROP TABLE

Use the standard MySQL `DROP TABLE` syntax. The query goes through the same [migration flow](#migration-flow-and-states) as `ALTER TABLE` does. Tables are not immediately dropped. Instead, they are renamed into special names, recognizable by the table lifecycle mechanism, to then slowly and safely transition through lifecycle states into finally getting dropped.

### Statement transformations

Vitess may modify your queries to qualify for online DDL statement. Modifications include:

- A multi-table `DROP` statement is replaced by multiple `DROP` statements, each operating on a single table (and each tracked by its own job ID).
- A `CREATE INDEX` statement is replaced by the equivalent `ALTER TABLE` statement.

## ddl_strategy

You will set either `@@ddl_strategy` session variable, or `-ddl_strategy` command line flag, to control your schema migration strategy, and specifically, to enable and configure online DDL. Details in [DDL Strategies](../ddl-strategies). As quick overview:

- The value `"direct"`, means not an online DDL. The empty value (`""`) is also interpreted as `direct`. A query is immediately pushed and applied on backend servers.
- The value `"online"` instructs Vitess to run an `ALTER TABLE` online DDL via `VReplication`.
- The value `"gh-ost"` instructs Vitess to run an `ALTER TABLE` online DDL via `gh-ost`.
- The value `"pt-osc"` instructs Vitess to run an `ALTER TABLE` online DDL via `pt-online-schema-change`.
- You may specify arguments for your tool of choice, e.g. `"gh-ost --max-load Threads_running=200"`. Details follow.

`CREATE` and `DROP` statements run in the same way for `"online"`, `"gh-ost"` and `"pt-osc"` strategies, and we consider them all to be _online_.

## ApplySchema

You may use `vtctl` or `vtctlclient` (the two are interchangeable for the purpose of this document) to apply schema changes. The `ApplySchema` command supports both synchronous and online schema migrations. To run an online schema migration you will supply the `-ddl_strategy` command line flag:

```shell
$ vtctlclient ApplySchema -ddl_strategy "online" -sql "ALTER TABLE demo MODIFY id bigint UNSIGNED" commerce
a2994c92_f1d4_11ea_afa3_f875a4d24e90
```

Notice how `ApplySchema` responds to an online DDL request with a UUID output. When the user indicates online schema change (aka online DDL), `vtctl` registers an online-DDL request with global `topo`. This generates a job ID for tracking. `vtctl` does not try to resolve the shards nor the `primary` tablets. The command returns immediately, without waiting for the migration(s) to start.

The command prints a job ID for each of the DDL statements. In the above we issue a single DDL statemnt, and `vtctl` responds with a single job ID (`a2994c92_f1d4_11ea_afa3_f875a4d24e90`)

If we immediately run `SHOW CREATE TABLE`, we are likely to still see the old schema:
```sql
SHOW CREATE TABLE demo;

CREATE TABLE `demo` (
  `id` int NOT NULL,
  `status` varchar(32) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB
```

That's because the migration is to be processed and executed in the future. We discuss how the migration jobs get scheduled and executed shortly. We will use the job ID for tracking.

`ApplySchema` will have Vitess run some validations:

```shell
$ vtctlclient ApplySchema -ddl_strategy "gh-ost" -sql "ALTER TABLE demo add column status int" commerce
E0908 16:17:07.651284 3739130 main.go:67] remote error: rpc error: code = Unknown desc = schema change failed, ExecuteResult: {
  "FailedShards": null,
  "SuccessShards": null,
  "CurSQLIndex": 0,
  "Sqls": [
    "ALTER TABLE demo add column status int"
  ],
  "ExecutorErr": "rpc error: code = Unknown desc = TabletManager.PreflightSchema on zone1-0000000100 error: /usr/bin/mysql: exit status 1, output: ERROR 1060 (42S21) at line 3: Duplicate column name 'status'\n: /usr/bin/mysql: exit status 1, output: ERROR 1060 (42S21) at line 3: Duplicate column name 'status'\n",
  "TotalTimeSpent": 144283260
}
```

Vitess was able to determine that the migration is invalid because a column named `status` already exists. `vtctld` generates no job ID, and does not persist any migration request.

## VTGate

When connected to `VTGate`, your schema migration strategy is determined by:

- `-ddl_strategy` command line flag, or:
- `@@ddl_strategy` session variable.

As a simple example, you may control the execution of a migration as follows:

```shell
$ mysql -h 127.0.0.1 -P 15306 commerce
Welcome to the MySQL monitor.  Commands end with ; or \g.

mysql> SET @@ddl_strategy='pt-osc';
Query OK, 0 rows affected (0.00 sec)

mysql> ALTER TABLE demo ADD COLUMN sample INT;
+--------------------------------------+
| uuid                                 |
+--------------------------------------+
| fa2fb689_f1d5_11ea_859e_f875a4d24e90 |
+--------------------------------------+
1 row in set (0.00 sec)
```

Just like in the `ApplySchema` example, `VTGate` identifies that this is an online schema change request, and persists it in global `topo`, returning a job ID for tracking. Migration does not start immediately.

`@@ddl_strategy` behaves like a MySQL session variable, though is only recognized by `VTGate`. Setting `@@ddl_strategy` only applies to that same connection and does not affect other connections. You may subsequently set `@@ddl_strategy` to different value.

The initial value for `@@ddl_strategy` is derived from the `vtgate -ddl_strategy` command line flag. Examples:

- If you run `vtgate` without `-ddl_strategy`, then `@@ddl_strategy` defaults to `'direct'`, which implies schema migrations are synchronous. You will need to `set @@ddl_strategy='gh-ost'` to run followup `ALTER TABLE` statements via `gh-ost`.
- If you run `vtgate -ddl_strategy "gh-ost"`, then `@@ddl_strategy` defaults to `'gh-ost'` in each new session. Any `ALTER TABLE` will run via `gh-ost`. You may `set @@ddl_strategy='pt-osc'` to make migrations run through `pt-online-schema-change`, or `set @@ddl_strategy='direct'` to run migrations synchronously.
 
## Migration flow and states

We highlight how Vitess manages migrations internally, and explain what states a migration goes through.

- Whether via `vtctlclient ApplySchema` or via `VTGate` as described above, a migration request entry is persisted in global `topo` (e.g. the global `etcd` cluster).
- `vtctld` periodically checks on new migration requests.
- `vtctld` resolves the relevant shards, and the `primary` tablet for each shard.
- `vtctld` pushes the request to all relevant `primary` tablets.
- If not all shards confirm receipt, `vtctld` periodically keeps retrying pushing the request to the shards until all approve.
- Internally, tablets persist the request in a designated table in the `_vt` schema. **Do not** manipulate that table directly as that can cause inconsistencies.
- A shard's `primary` tablet owns running the migration. It is independent of other shards. It will schedule the migration to run when possible. A tablet will not run two migrations at the same time.
- A migration is first created in `queued` state.
- If the tablet sees queued migration, and assuming there's no reason to wait, it picks the oldest requested migration in `queued` state, and moves it to `ready` state.
- For `ALTER TABLE` statements:
  - Tablet prepares for the migration. It creates a MySQL account with a random password, to be used by this migration only. It creates the command line invocation, and extra scripts if possible.
  - The tablet then runs the migration. Whether `gh-ost` or `pt-online-schema-change`, it first runs in _dry run_ mode, and, if successful, in actual _execute_ mode. The migration is then in `running` state.
  - The migration will either run to completion, fail, or be interrupted. If successful, it transitions into `complete` state, which is the end of the road for that migration. If failed or interrupted, it transitions to `failed` state. The user may choose to _retry_ failed migrations (see below).
  - The user is able to _cancel_ a migration (details below). If the migration hasn't started yet, it transitions to `cancelled` state. If the migration is `running`, then it is interrupted, and is expected to transition into `failed` state.
- For `CREATE TABLE` statements:
  - Tablet runs the statement directly on the MySQL backend
- For `DROP TABLE` statements:
  - A multi-table `DROP TABLE` statement is converted to multiple single-table `DROP TABLE` statements
  - Each `DROP TABLE` is internally replaced with a `RENAME TABLE`
  - Table is renamed using a special naming convention, identified by the [Table Lifecycle](../../../reference/features/table-lifecycle/) mechanism
  - As result, a single `DROP TABLE` statement may generate multiple distinct migrations with distinct migration UUIDs.

By way of illustration, suppose a migration is now in `running` state, and is expected to keep on running for the next few hours. The user may initiate a new `ALTER TABLE...` statement. It will persist in global `topo`. `vtctld` will pick it up and advertise it to the relevant tablets. Each will persist the migration request in `queued` state. None will run the migration yet, since another migration is already in progress. In due time, and when the executing migration completes (whether successfully or not), and assuming no other migrations are `queued`, the `primary` tablets, each in its own good time, will execute the new migration. 

At this time, the user is responsible to track the state of all migrations. VTTablet does not report back to `vtctld`. This may change in the future.

At this time, there are no automated retries. For example, a failover on a shard causes the migration to fail, and Vitess will not try to re-run the migration on the new `primary`. It is the user's responsibility to issue a `retry`. This may change in the future.


## Tracking migrations

You may track the status of a single migration, of all or recent migrations, or of migrations in a specific state. Examples:

```shell
-$ vtctlclient OnlineDDL commerce show ab3ffdd5_f25c_11ea_bab4_0242c0a8b007
+-----------------+-------+--------------+-------------+------------+--------------------------------------+----------+---------------------+---------------------+------------------+
|     Tablet      | shard | mysql_schema | mysql_table | ddl_action |            migration_uuid            | strategy |  started_timestamp  | completed_timestamp | migration_status |
+-----------------+-------+--------------+-------------+------------+--------------------------------------+----------+---------------------+---------------------+------------------+
| test-0000000201 | 40-80 | vt_commerce  | demo        | alter      | ab3ffdd5_f25c_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 05:24:33 | 2020-09-09 05:24:34 | complete         |
| test-0000000301 | 80-c0 | vt_commerce  | demo        | alter      | ab3ffdd5_f25c_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 05:25:13 | 2020-09-09 05:25:14 | complete         |
| test-0000000401 | c0-   | vt_commerce  | demo        | alter      | ab3ffdd5_f25c_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 05:25:13 | 2020-09-09 05:25:14 | complete         |
| test-0000000101 |   -40 | vt_commerce  | demo        | alter      | ab3ffdd5_f25c_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 05:25:13 | 2020-09-09 05:25:14 | complete         |
+-----------------+-------+--------------+-------------+------------+--------------------------------------+----------+---------------------+---------------------+------------------+

$ vtctlclient OnlineDDL commerce show 8a797518_f25c_11ea_bab4_0242c0a8b007
+-----------------+-------+--------------+-------------+------------+--------------------------------------+----------+---------------------+---------------------+------------------+
|     Tablet      | shard | mysql_schema | mysql_table | ddl_action |            migration_uuid            | strategy |  started_timestamp  | completed_timestamp | migration_status |
+-----------------+-------+--------------+-------------+------------+--------------------------------------+----------+---------------------+---------------------+------------------+
| test-0000000401 | c0-   | vt_commerce  | demo        | alter      | 8a797518_f25c_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 05:23:32 |                     | running          |
| test-0000000201 | 40-80 | vt_commerce  | demo        | alter      | 8a797518_f25c_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 05:23:32 | 2020-09-09 05:23:33 | complete         |
| test-0000000301 | 80-c0 | vt_commerce  | demo        | alter      | 8a797518_f25c_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 05:23:32 |                     | running          |
| test-0000000101 |   -40 | vt_commerce  | demo        | alter      | 8a797518_f25c_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 05:23:32 |                     | running          |
+-----------------+-------+--------------+-------------+------------+--------------------------------------+----------+---------------------+---------------------+------------------+

$ vtctlclient OnlineDDL commerce show 8a797518_f25c_11ea_bab4_0242c0a8b007
+-----------------+-------+--------------+-------------+------------+--------------------------------------+----------+---------------------+---------------------+------------------+
|     Tablet      | shard | mysql_schema | mysql_table | ddl_action |            migration_uuid            | strategy |  started_timestamp  | completed_timestamp | migration_status |
+-----------------+-------+--------------+-------------+------------+--------------------------------------+----------+---------------------+---------------------+------------------+
| test-0000000401 | c0-   | vt_commerce  | demo        | alter      | 8a797518_f25c_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 05:23:32 |                     | failed           |
| test-0000000101 |   -40 | vt_commerce  | demo        | alter      | 8a797518_f25c_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 05:23:32 |                     | failed           |
| test-0000000301 | 80-c0 | vt_commerce  | demo        | alter      | 8a797518_f25c_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 05:23:32 |                     | failed           |
| test-0000000201 | 40-80 | vt_commerce  | demo        | alter      | 8a797518_f25c_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 05:23:32 | 2020-09-09 05:23:33 | complete         |
+-----------------+-------+--------------+-------------+------------+--------------------------------------+----------+---------------------+---------------------+------------------+

$ vtctlclient OnlineDDL commerce show recent
+-----------------+-------+--------------+-------------+------------+--------------------------------------+----------+---------------------+---------------------+------------------+
|     Tablet      | shard | mysql_schema | mysql_table | ddl_action |            migration_uuid            | strategy |  started_timestamp  | completed_timestamp | migration_status |
+-----------------+-------+--------------+-------------+------------+--------------------------------------+----------+---------------------+---------------------+------------------+
| test-0000000201 | 40-80 | vt_commerce  | demo        | alter      | 63b5db0c_f25c_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 05:22:41 | 2020-09-09 05:22:42 | complete         |
| test-0000000201 | 40-80 | vt_commerce  | demo        | alter      | 8a797518_f25c_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 05:23:32 | 2020-09-09 05:23:33 | complete         |
| test-0000000201 | 40-80 | vt_commerce  | demo        | alter      | ab3ffdd5_f25c_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 05:24:33 | 2020-09-09 05:24:34 | complete         |
| test-0000000301 | 80-c0 | vt_commerce  | demo        | alter      | 63b5db0c_f25c_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 05:22:41 | 2020-09-09 05:22:42 | complete         |
| test-0000000301 | 80-c0 | vt_commerce  | demo        | alter      | 8a797518_f25c_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 05:23:32 |                     | failed           |
| test-0000000301 | 80-c0 | vt_commerce  | demo        | alter      | ab3ffdd5_f25c_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 05:25:13 | 2020-09-09 05:25:14 | complete         |
| test-0000000401 | c0-   | vt_commerce  | demo        | alter      | 63b5db0c_f25c_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 05:22:41 | 2020-09-09 05:22:42 | complete         |
| test-0000000401 | c0-   | vt_commerce  | demo        | alter      | 8a797518_f25c_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 05:23:32 |                     | failed           |
| test-0000000401 | c0-   | vt_commerce  | demo        | alter      | ab3ffdd5_f25c_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 05:25:13 | 2020-09-09 05:25:14 | complete         |
| test-0000000101 |   -40 | vt_commerce  | demo        | alter      | 63b5db0c_f25c_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 05:22:41 | 2020-09-09 05:22:42 | complete         |
| test-0000000101 |   -40 | vt_commerce  | demo        | alter      | 8a797518_f25c_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 05:23:32 |                     | failed           |
| test-0000000101 |   -40 | vt_commerce  | demo        | alter      | ab3ffdd5_f25c_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 05:25:13 | 2020-09-09 05:25:14 | complete         |
+-----------------+-------+--------------+-------------+------------+--------------------------------------+----------+---------------------+---------------------+------------------+

$ vtctlclient OnlineDDL commerce show failed
+-----------------+-------+--------------+-------------+------------+--------------------------------------+----------+---------------------+---------------------+------------------+
|     Tablet      | shard | mysql_schema | mysql_table | ddl_action |            migration_uuid            | strategy |  started_timestamp  | completed_timestamp | migration_status |
+-----------------+-------+--------------+-------------+------------+--------------------------------------+----------+---------------------+---------------------+------------------+
| test-0000000301 | 80-c0 | vt_commerce  | demo        | alter      | 8a797518_f25c_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 05:23:32 |                     | failed           |
| test-0000000401 | c0-   | vt_commerce  | demo        | alter      | 8a797518_f25c_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 05:23:32 |                     | failed           |
| test-0000000101 |   -40 | vt_commerce  | demo        | alter      | 8a797518_f25c_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 05:23:32 |                     | failed           |
+-----------------+-------+--------------+-------------+------------+--------------------------------------+----------+---------------------+---------------------+------------------+
```

The syntax for tracking migrations is: 
```
vtctlclient OnlineDDL <keyspace> show <migration_id|all|recent|queued|ready|running|complete|failed|cancelled>
```

## Cancelling a migration

The user may cancel a migration, as follows:

- If the migration hasn't started yet (it is `queued` or `ready`), then it is removed from queue and will not be executed.
- If the migration is `running`, then it is forcibly interrupted. The migration is expected to transition to `failed` state.
- In all other cases, cancelling a migration has no effect.

The syntax to cancelling a migration is:

```
vtctlclient OnlineDDL cancel <migration_id>
```

Example:

```shell
$ vtctlclient OnlineDDL commerce show 2201058f_f266_11ea_bab4_0242c0a8b007
+-----------------+-------+--------------+-------------+------------+--------------------------------------+----------+---------------------+---------------------+------------------+
|     Tablet      | shard | mysql_schema | mysql_table | ddl_action |            migration_uuid            | strategy |  started_timestamp  | completed_timestamp | migration_status |
+-----------------+-------+--------------+-------------+------------+--------------------------------------+----------+---------------------+---------------------+------------------+
| test-0000000301 | 80-c0 | vt_commerce  | demo        | alter      | 2201058f_f266_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 06:32:31 |                     | running          |
| test-0000000101 |   -40 | vt_commerce  | demo        | alter      | 2201058f_f266_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 06:32:31 |                     | running          |
| test-0000000401 | c0-   | vt_commerce  | demo        | alter      | 2201058f_f266_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 06:32:31 |                     | running          |
| test-0000000201 | 40-80 | vt_commerce  | demo        | alter      | 2201058f_f266_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 06:32:31 |                     | running          |
+-----------------+-------+--------------+-------------+------------+--------------------------------------+----------+---------------------+---------------------+------------------+

$ vtctlclient OnlineDDL commerce cancel 2201058f_f266_11ea_bab4_0242c0a8b007
+-----------------+--------------+
|     Tablet      | RowsAffected |
+-----------------+--------------+
| test-0000000401 |            1 |
| test-0000000101 |            1 |
| test-0000000201 |            1 |
| test-0000000301 |            1 |
+-----------------+--------------+

$ vtctlclient OnlineDDL commerce show 2201058f_f266_11ea_bab4_0242c0a8b007
+-----------------+-------+--------------+-------------+------------+--------------------------------------+----------+---------------------+---------------------+------------------+
|     Tablet      | shard | mysql_schema | mysql_table | ddl_action |            migration_uuid            | strategy |  started_timestamp  | completed_timestamp | migration_status |
+-----------------+-------+--------------+-------------+------------+--------------------------------------+----------+---------------------+---------------------+------------------+
| test-0000000401 | c0-   | vt_commerce  | demo        | alter      | 2201058f_f266_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 06:32:31 |                     | failed           |
| test-0000000301 | 80-c0 | vt_commerce  | demo        | alter      | 2201058f_f266_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 06:32:31 |                     | failed           |
| test-0000000201 | 40-80 | vt_commerce  | demo        | alter      | 2201058f_f266_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 06:32:31 |                     | failed           |
| test-0000000101 |   -40 | vt_commerce  | demo        | alter      | 2201058f_f266_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 06:32:31 |                     | failed           |
+-----------------+-------+--------------+-------------+------------+--------------------------------------+----------+---------------------+---------------------+------------------+
```


## Cancelling all keyspace migrations

The user may cancel all migrations in a keyspace. A migration is cancellable if it is in `queued`, `ready` or `running` states, as described previously. It is a high impact operation and should be used with care.

The syntax to cancelling all keyspace migrations is:

```
vtctlclient OnlineDDL cancel-all
```

Example:

```shell
$ vtctlclient OnlineDDL commerce show all
+------------------+-------+--------------+-------------+--------------------------------------+----------+-------------------+---------------------+------------------+
|      Tablet      | shard | mysql_schema | mysql_table |            migration_uuid            | strategy | started_timestamp | completed_timestamp | migration_status |
+------------------+-------+--------------+-------------+--------------------------------------+----------+-------------------+---------------------+------------------+
| zone1-0000000100 |     0 | vt_commerce  | corder      | 2c581994_353a_11eb_8b72_f875a4d24e90 | online   |                   |                     | queued           |
| zone1-0000000100 |     0 | vt_commerce  | corder      | 2c6420c9_353a_11eb_8b72_f875a4d24e90 | online   |                   |                     | queued           |
| zone1-0000000100 |     0 | vt_commerce  | corder      | 2c7040df_353a_11eb_8b72_f875a4d24e90 | online   |                   |                     | queued           |
| zone1-0000000100 |     0 | vt_commerce  | corder      | 2c7c0572_353a_11eb_8b72_f875a4d24e90 | online   |                   |                     | queued           |
| zone1-0000000100 |     0 | vt_commerce  | corder      | 2c87f7cd_353a_11eb_8b72_f875a4d24e90 | online   |                   |                     | queued           |
+------------------+-------+--------------+-------------+--------------------------------------+----------+-------------------+---------------------+------------------+

$  vtctlclient OnlineDDL commerce cancel-all
+------------------+--------------+
|      Tablet      | RowsAffected |
+------------------+--------------+
| zone1-0000000100 |            5 |
+------------------+--------------+

 vtctlclient OnlineDDL commerce show all
+------------------+-------+--------------+-------------+--------------------------------------+----------+-------------------+---------------------+------------------+
|      Tablet      | shard | mysql_schema | mysql_table |            migration_uuid            | strategy | started_timestamp | completed_timestamp | migration_status |
+------------------+-------+--------------+-------------+--------------------------------------+----------+-------------------+---------------------+------------------+
| zone1-0000000100 |     0 | vt_commerce  | corder      | 2c581994_353a_11eb_8b72_f875a4d24e90 | online   |                   |                     | cancelled        |
| zone1-0000000100 |     0 | vt_commerce  | corder      | 2c6420c9_353a_11eb_8b72_f875a4d24e90 | online   |                   |                     | cancelled        |
| zone1-0000000100 |     0 | vt_commerce  | corder      | 2c7040df_353a_11eb_8b72_f875a4d24e90 | online   |                   |                     | cancelled        |
| zone1-0000000100 |     0 | vt_commerce  | corder      | 2c7c0572_353a_11eb_8b72_f875a4d24e90 | online   |                   |                     | cancelled        |
| zone1-0000000100 |     0 | vt_commerce  | corder      | 2c87f7cd_353a_11eb_8b72_f875a4d24e90 | online   |                   |                     | cancelled        |
+------------------+-------+--------------+-------------+--------------------------------------+----------+-------------------+---------------------+------------------+
```

## Retrying a migration

The user may retry running a migration. If the migration is in `failed` or in `cancelled` state, Vitess will re-run the migration, with exact same arguments as previously intended. If the migration is in any other state, `retry` does nothing.

It is not possible to retry a migration with different options. e.g. if the user initially runs `ALTER TABLE demo MODIFY id BIGINT` with `@@ddl_strategy='gh-ost --max-load Threads_running=200'` and the migration fails, retrying it will use exact same options. It is not possible to retry with `@@ddl_strategy='gh-ost --max-load Threads_running=500'`.

Continuing the above example, where we cancelled a migration while running, we now retry it:

```shell
$ vtctlclient OnlineDDL commerce show 2201058f_f266_11ea_bab4_0242c0a8b007
+-----------------+-------+--------------+-------------+------------+--------------------------------------+----------+---------------------+---------------------+------------------+
|     Tablet      | shard | mysql_schema | mysql_table | ddl_action |            migration_uuid            | strategy |  started_timestamp  | completed_timestamp | migration_status |
+-----------------+-------+--------------+-------------+------------+--------------------------------------+----------+---------------------+---------------------+------------------+
| test-0000000401 | c0-   | vt_commerce  | demo        | alter      | 2201058f_f266_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 06:32:31 |                     | failed           |
| test-0000000301 | 80-c0 | vt_commerce  | demo        | alter      | 2201058f_f266_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 06:32:31 |                     | failed           |
| test-0000000201 | 40-80 | vt_commerce  | demo        | alter      | 2201058f_f266_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 06:32:31 |                     | failed           |
| test-0000000101 |   -40 | vt_commerce  | demo        | alter      | 2201058f_f266_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 06:32:31 |                     | failed           |
+-----------------+-------+--------------+-------------+------------+--------------------------------------+----------+---------------------+---------------------+------------------+

$ vtctlclient OnlineDDL commerce retry 2201058f_f266_11ea_bab4_0242c0a8b007
+-----------------+--------------+
|     Tablet      | RowsAffected |
+-----------------+--------------+
| test-0000000101 |            1 |
| test-0000000201 |            1 |
| test-0000000301 |            1 |
| test-0000000401 |            1 |
+-----------------+--------------+

$ vtctlclient OnlineDDL commerce show 2201058f_f266_11ea_bab4_0242c0a8b007
+-----------------+-------+--------------+-------------+------------+--------------------------------------+----------+-------------------+---------------------+------------------+
|     Tablet      | shard | mysql_schema | mysql_table | ddl_action |            migration_uuid            | strategy | started_timestamp | completed_timestamp | migration_status |
+-----------------+-------+--------------+-------------+------------+--------------------------------------+----------+-------------------+---------------------+------------------+
| test-0000000201 | 40-80 | vt_commerce  | demo        | alter      | 2201058f_f266_11ea_bab4_0242c0a8b007 | online   |                   |                     | queued           |
| test-0000000101 |   -40 | vt_commerce  | demo        | alter      | 2201058f_f266_11ea_bab4_0242c0a8b007 | online   |                   |                     | queued           |
| test-0000000301 | 80-c0 | vt_commerce  | demo        | alter      | 2201058f_f266_11ea_bab4_0242c0a8b007 | online   |                   |                     | queued           |
| test-0000000401 | c0-   | vt_commerce  | demo        | alter      | 2201058f_f266_11ea_bab4_0242c0a8b007 | online   |                   |                     | queued           |
+-----------------+-------+--------------+-------------+------------+--------------------------------------+----------+-------------------+---------------------+------------------+

$ vtctlclient OnlineDDL commerce show 2201058f_f266_11ea_bab4_0242c0a8b007
+-----------------+-------+--------------+-------------+------------+--------------------------------------+----------+---------------------+---------------------+------------------+
|     Tablet      | shard | mysql_schema | mysql_table | ddl_action |            migration_uuid            | strategy |  started_timestamp  | completed_timestamp | migration_status |
+-----------------+-------+--------------+-------------+------------+--------------------------------------+----------+---------------------+---------------------+------------------+
| test-0000000101 |   -40 | vt_commerce  | demo        | alter      | 2201058f_f266_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 06:37:33 |                     | running          |
| test-0000000401 | c0-   | vt_commerce  | demo        | alter      | 2201058f_f266_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 06:37:33 |                     | running          |
| test-0000000201 | 40-80 | vt_commerce  | demo        | alter      | 2201058f_f266_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 06:37:33 |                     | running          |
| test-0000000301 | 80-c0 | vt_commerce  | demo        | alter      | 2201058f_f266_11ea_bab4_0242c0a8b007 | online   | 2020-09-09 06:37:33 |                     | running          |
+-----------------+-------+--------------+-------------+------------+--------------------------------------+----------+---------------------+---------------------+------------------+
```

## Auto resume after failure

VReplication based migrations (`ddl_strategy="online"`) are resumable across failure and across primary failovers.

## Auto retry after failure

Neither `gh-ost` and `pt-osc` are able to resume from point of failure, or after a failover. However, Vitess management can issue an automated retry (starting the migration afresh).

- which `vttablet` initiated the migration
- how many times a migration has been retried
- whether a migration failed due to a `vttablet` failure (as is the case in a failover scenario)

Vitess will auto-retry a failed migration when:

- The migration failed due to a `vttablet` failure, and
- it has not been retried (this is a temporary restriction)

The migration will be transitioned into `queued` state, as if the user requested a `retry` operation. Note that this takes place on a per-shard basis.

The primary use case is a primary failure and failover. The newly promoted tablet will be able to retry the migration that broke during the previous primary failure. To clarify, the migration will start anew, as at this time there is no mechanism to resume a broken migration.

## Throttling

All three strategies: `online`, `gh-ost` and `pt-osc` utilize the tablet throttler, which is a cooperative throttler service based on replication lag. The tablet throttler automatically detects topology `REPLICA` tablets and adapts to changes in the topology. See [Tablet throttler](../../../reference/features/tablet-throttler/).

- `online` strategy uses the throttler by the fact VReplication natively uses the throttler on both source and target ends (for both reads and writes)
- `gh-ost` uses the throttler via `--throttle-http`, which is automatically provided by Vitess
- `pt-osc` uses the throttler by replication lag plugin, automatically injected by vitess.

**NOTE** that at this time (and subject to change) the tablet throttler is disabled by default. Enable it with `vttablet`'s `-enable-lag-throttler` flag. If the tablet throttler is disabled, schema migrations will not throttle on replication lag.

## Table cleanup

All `ALTER` strategies leave artifacts behind. Whether successful or failed, either the original table or the _ghost_ table is left still populated at the end of the migration. Vitess explicitly makes sure the tables are not dropped at the end of the migration. This is for two reasons:

- Make the table/data still available for a while, and
- in MySQL pre `8.0.23`, a `DROP TABLE` operation can be dangerous in production as it commonly locks the buffer pool for a substantial period.

The tables are kept for 24 hours after migration completion. Vitess automatically cleans up those tables as soon as a migration completes (either successful or failed). You will normally not need to do anything.

Artifact tables are identifiable via `SELECT artifacts FROM _vt.schema_migrations` in a `VExec` command, see below. You should generally not touch these tables. It's possible to `DROP` those tables with `direct` DDL strategy. Note that dropping tables in production can be risky and lock down your database for a substantial period of time.

## VExec commands for greater control and visibility

`vtctlclient OnlineDDL` command should provide with most needs. However, Vitess gives the user greater control through the `VExec` command and via SQL queries.

For schema migrations, Vitess allows operations on the virtual table `_vt.schema_migrations`. Queries on this virtual table scatter to the underlying tablets and gather or manipulate data on their own, private backend tables (which incidentally are called by the same name). `VExec` only allows specific types of queries on that table.

- `SELECT`: you may SELECT any column, or `SELECT *`. `vtctlclient OnlineDDL show` commands only present with a subset of columns, and so running ` VExec` `SELECT` provides greater visibility. Some columns that are not shown are:
  - `log_path`: tablet server and path where migration logs are.
  - `artifacts`: tables created by the migration. This can be used to determine which tables need cleanup.
  - `alter`: the exact `alter` statement used by the migration
  - `options`: any options passed by the user (e.g. `--max-load=Threads_running=200`)
  - Various timestamps indicating the migration progress
  Aggregate functions do not work as expected and should be avoided. `LIMIT` and `OFFSET` are not supported.
- `UPDATE`: you may directly update the status of a migration. You may only change status into `cancel` or `retry`, which Vitess interprets similarly to a `vtctlclient OnlineDDL cancel/retry` command. However, you get greater control as you may filter on a specific `shard`.
- `DELETE`: unsupported
- `INSERT`: unsupported, used internally only to advertise new migration requests to the tablets.

The syntax to run `VExec` queries is:

```
vtctlclient VExec <keyspace>.<migration_id> "<sql query>"
```

Examples:

```shell

$ vtctlclient VExec commerce.2201058f_f266_11ea_bab4_0242c0a8b007 "select * from _vt.schema_migrations"

$ vtctlclient VExec commerce.91b5c953-e1e2-11ea-a097-f875a4d24e90 "update _vt.schema_migrations set migration_status='retry'

$ vtctlclient VExec commerce.91b5c953-e1e2-11ea-a097-f875a4d24e90 "update _vt.schema_migrations set migration_status='retry' where shard='40-80'
```

```shell
$ vtctlclient VExec commerce.2201058f_f266_11ea_bab4_0242c0a8b007 "select shard, mysql_table, migration_uuid, started_timestamp, completed_timestamp, migration_status from _vt.schema_migrations"
+-----------------+-------+-------------+--------------------------------------+---------------------+---------------------+------------------+
|     Tablet      | shard | mysql_table |            migration_uuid            |  started_timestamp  | completed_timestamp | migration_status |
+-----------------+-------+-------------+--------------------------------------+---------------------+---------------------+------------------+
| test-0000000301 | 80-c0 | demo        | 2201058f_f266_11ea_bab4_0242c0a8b007 | 2020-09-09 06:37:33 |                     | failed           |
| test-0000000101 |   -40 | demo        | 2201058f_f266_11ea_bab4_0242c0a8b007 | 2020-09-09 06:37:33 |                     | failed           |
| test-0000000201 | 40-80 | demo        | 2201058f_f266_11ea_bab4_0242c0a8b007 | 2020-09-09 08:31:47 |                     | failed           |
| test-0000000401 | c0-   | demo        | 2201058f_f266_11ea_bab4_0242c0a8b007 | 2020-09-09 06:37:33 |                     | failed           |
+-----------------+-------+-------------+--------------------------------------+---------------------+---------------------+------------------+

$ vtctlclient VExec commerce.2201058f_f266_11ea_bab4_0242c0a8b007 "update _vt.schema_migrations set migration_status='retry' where migration_uuid='2201058f_f266_11ea_bab4_0242c0a8b007' and shard='40-80'"
+-----------------+--------------+
|     Tablet      | RowsAffected |
+-----------------+--------------+
| test-0000000201 |            1 |
+-----------------+--------------+

$ vtctlclient VExec commerce.2201058f_f266_11ea_bab4_0242c0a8b007 "select shard, mysql_table, migration_uuid, started_timestamp, completed_timestamp, migration_status from _vt.schema_migrations"
+-----------------+-------+-------------+--------------------------------------+---------------------+---------------------+------------------+
|     Tablet      | shard | mysql_table |            migration_uuid            |  started_timestamp  | completed_timestamp | migration_status |
+-----------------+-------+-------------+--------------------------------------+---------------------+---------------------+------------------+
| test-0000000301 | 80-c0 | demo        | 2201058f_f266_11ea_bab4_0242c0a8b007 | 2020-09-09 06:37:33 |                     | failed           |
| test-0000000201 | 40-80 | demo        | 2201058f_f266_11ea_bab4_0242c0a8b007 | 2020-09-09 08:34:59 |                     | running          |
| test-0000000101 |   -40 | demo        | 2201058f_f266_11ea_bab4_0242c0a8b007 | 2020-09-09 06:37:33 |                     | failed           |
| test-0000000401 | c0-   | demo        | 2201058f_f266_11ea_bab4_0242c0a8b007 | 2020-09-09 06:37:33 |                     | failed           |
+-----------------+-------+-------------+--------------------------------------+---------------------+---------------------+------------------+

$ vtctlclient VExec commerce.2201058f_f266_11ea_bab4_0242c0a8b007 "update _vt.schema_migrations set migration_status='cancel' where migration_uuid='2201058f_f266_11ea_bab4_0242c0a8b007' and shard='40-80'"
+-----------------+--------------+
|     Tablet      | RowsAffected |
+-----------------+--------------+
| test-0000000201 |            1 |
+-----------------+--------------+

$ vtctlclient VExec commerce.2201058f_f266_11ea_bab4_0242c0a8b007 "select shard, mysql_table, migration_uuid, started_timestamp, completed_timestamp, migration_status from _vt.schema_migrations"
+-----------------+-------+-------------+--------------------------------------+---------------------+---------------------+------------------+
|     Tablet      | shard | mysql_table |            migration_uuid            |  started_timestamp  | completed_timestamp | migration_status |
+-----------------+-------+-------------+--------------------------------------+---------------------+---------------------+------------------+
| test-0000000401 | c0-   | demo        | 2201058f_f266_11ea_bab4_0242c0a8b007 | 2020-09-09 06:37:33 |                     | failed           |
| test-0000000101 |   -40 | demo        | 2201058f_f266_11ea_bab4_0242c0a8b007 | 2020-09-09 06:37:33 |                     | failed           |
| test-0000000201 | 40-80 | demo        | 2201058f_f266_11ea_bab4_0242c0a8b007 | 2020-09-09 08:34:59 |                     | failed           |
| test-0000000301 | 80-c0 | demo        | 2201058f_f266_11ea_bab4_0242c0a8b007 | 2020-09-09 06:37:33 |                     | failed           |
+-----------------+-------+-------------+--------------------------------------+---------------------+---------------------+------------------+

$ vtctlclient VExec commerce.2201058f_f266_11ea_bab4_0242c0a8b007 "update _vt.schema_migrations set migration_status='cancel' where migration_uuid='2201058f_f266_11ea_bab4_0242c0a8b007' and shard='40-80'"
<no result>

$ vtctlclient VExec commerce.2201058f_f266_11ea_bab4_0242c0a8b007 "select shard, log_path from _vt.schema_migrations"
+-----------------+-------+-----------------------------------------------------------------------------+
|     Tablet      | shard |                                   log_path                                  |
+-----------------+-------+-----------------------------------------------------------------------------+
| test-0000000201 | 40-80 | 11ac2af6e63e:/tmp/online-ddl-2201058f_f266_11ea_bab4_0242c0a8b007-657478384 |
| test-0000000101 |   -40 | e779a82d35d7:/tmp/online-ddl-2201058f_f266_11ea_bab4_0242c0a8b007-901629215 |
| test-0000000401 | c0-   | 5aad1249ab91:/tmp/online-ddl-2201058f_f266_11ea_bab4_0242c0a8b007-039568897 |
| test-0000000301 | 80-c0 | 5e7c662679d3:/tmp/online-ddl-2201058f_f266_11ea_bab4_0242c0a8b007-532703073 |
+-----------------+-------+-----------------------------------------------------------------------------+
```


