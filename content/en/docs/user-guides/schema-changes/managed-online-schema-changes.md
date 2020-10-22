---
title: Managed, Online Schema Changes
weight: 2
aliases: ['/docs/user-guides/managed-online-schema-changes/']
---

**Note:** this feature is **EXPERIMENTAL**. Also, the syntax for online-DDL is **subject to change**.

Vitess offers managed, online schema migrations, via [gh-ost](https://github.com/github/gh-ost) and [pt-online-schema-change](https://www.percona.com/doc/percona-toolkit/3.0/pt-online-schema-change.html). As a quick breakdown:

- Vitess recognizes a special `ALTER TABLE` syntax that indicates an online schema change request.
- Vitess responds to an online schema change request with a job ID
- Vitess resolves affected shards
- A shard's `primary` tablet schedules the migration to run when possible
- The tablets run migrations via `gh-ost` or `pt-online-schema-change`
- Vitess provides the user a mechanism to view migration status, cancel or retry migrations, based on the job ID

## Syntax

**Note:** the syntax is subject to change while this feature is in _experimental_ state.

We assume we have a keyspace (schema) called `commerce`, with a table called `demo`, that has the following definition:

```sql
CREATE TABLE `demo` (
  `id` int NOT NULL,
  `status` varchar(32) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB
```

The following syntax is valid and is interpreted by Vitess as an online schema change request:

```sql
ALTER WITH 'gh-ost' TABLE demo modify id bigint unsigned;
ALTER WITH 'gh-ost' '--max-load="Threads_running=200"' TABLE demo modify id bigint unsigned;
ALTER WITH 'pt-osc' TABLE demo ADD COLUMN created_timestamp TIMESTAMP NOT NULL;
ALTER WITH 'pt-osc' '--null-to-not-null' TABLE demo ADD COLUMN created_timestamp TIMESTAMP NOT NULL;
```

`gh-ost` and `pt-osc` are the only supported values. Any other value is a syntax error. Specifics about `gh-ost` and `pt-online-schema-change` follow later on.

You may use this syntax either with `vtctlclient` or via `vtgate`

## ApplySchema

Invocation is similar to direct DDL statements. However, the response is different:

```shell
$ vtctlclient ApplySchema -sql "ALTER WITH 'gh-ost' TABLE demo modify id bigint unsigned" commerce
a2994c92_f1d4_11ea_afa3_f875a4d24e90
```

When the user indicates online schema change (aka online DDL), `vtctl` registers an online-DDL request with global `topo`. This generates a job ID for tracking. `vtctl` does not try to resolve the shards nor the `primary` tablets. The command returns immediately, without waiting for the migration(s) to start. It prints out the job ID (`a2994c92_f1d4_11ea_afa3_f875a4d24e90` in the above)

If we immediately run `SHOW CREATE TABLE`, we are likely to still see the old schema:
```sql
SHOW CREATE TABLE demo;

CREATE TABLE `demo` (
  `id` int NOT NULL,
  `status` varchar(32) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB
```

We discuss how the migration jobs get scheduled and executed shortly. We will use the job ID for tracking.

`ApplySchema` will have vitess run some validations:

```shell
$ vtctlclient ApplySchema -sql "ALTER WITH 'gh-ost' TABLE demo add column status int" commerce
E0908 16:17:07.651284 3739130 main.go:67] remote error: rpc error: code = Unknown desc = schema change failed, ExecuteResult: {
  "FailedShards": null,
  "SuccessShards": null,
  "CurSQLIndex": 0,
  "Sqls": [
    "ALTER WITH 'gh-ost' TABLE demo add column status int"
  ],
  "ExecutorErr": "rpc error: code = Unknown desc = TabletManager.PreflightSchema on zone1-0000000100 error: /usr/bin/mysql: exit status 1, output: ERROR 1060 (42S21) at line 3: Duplicate column name 'status'\n: /usr/bin/mysql: exit status 1, output: ERROR 1060 (42S21) at line 3: Duplicate column name 'status'\n",
  "TotalTimeSpent": 144283260
}
```

Vitess was able to determine that the migration is invalid because a column named `status` already exists. `vtctld` generates no job ID, and does not persist any migration request.

## VTGate

You may run online DDL directly from VTGate. For example:

```shell
$ mysql -h 127.0.0.1 -P 15306 commerce
Welcome to the MySQL monitor.  Commands end with ; or \g.

mysql> ALTER WITH 'pt-osc' TABLE demo ADD COLUMN sample INT;
+--------------------------------------+
| uuid                                 |
+--------------------------------------+
| fa2fb689_f1d5_11ea_859e_f875a4d24e90 |
+--------------------------------------+
1 row in set (0.00 sec)
```

Just like in the previous example, `VTGate` identifies that this is an online schema change request, and persists it in global `topo`, returning a job ID for tracking. Migration does not start immediately.

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
- Tablet then prepares for the migration. It creates a MySQL account with a random password, to be used by this migration only. It creates the command line invocation, and extra scripts if possible.
- The tablet then runs the migration. Whether `gh-ost` or `pt-online-schema-change`, it first runs in _dry run_ mode, and, if successful, in actual _execute_ mode. The migration is then in `running` state.
- The migration will either run to completion, fail, or be interrupted. If successful, it transitions into `complete` state, which is the end of the road for that migration. If failed or interrupted, it transitions to `failed` state. The user may choose to _retry_ failed migrations (see below).
- The user is able to _cancel_ a migration (details below). If the migration hasn't started yet, it transitions to `cancelled` state. If the migration is `running`, then it is interrupted, and is expected to transition into `failed` state.

By way of illustration, suppose a migration is now in `running` state, and is expected to keep on running for the next few hours. The user may initiate a new `ALTER WITH 'gh-ost' TABLE...` statement. It will persist in global `topo`. `vtctld` will pick it up and advertise it to the relevant tablets. Each will persist the migration request in `queued` state. None will run the migration yet, since another migration is already in progress. In due time, and when the executing migration completes (whether successfully or not), and assuming no other migrations are `queued`, the `primary` tablets, each in its own good time, will execute the new migration. 

At this time, the user is responsible to track the state of all migrations. VTTablet does not report back to `vtctld`. This may change in the future.

At this time, there are no automated retries. For example, a failover on a shard causes the migration to fail, and Vitess will not try to re-run the migration on the new `primary`. It is the user's responsibility to issue a `retry`. This may change in the future.


## Tracking migrations

You may track the status of a single migration, of all or recent migrations, or of migrations in a specific state. Examples:

```shell
$ vtctlclient OnlineDDL commerce show ab3ffdd5_f25c_11ea_bab4_0242c0a8b007
+-----------------+-------+--------------+-------------+--------------------------------------+----------+---------------------+---------------------+------------------+
|     Tablet      | shard | mysql_schema | mysql_table |            migration_uuid            | strategy |  started_timestamp  | completed_timestamp | migration_status |
+-----------------+-------+--------------+-------------+--------------------------------------+----------+---------------------+---------------------+------------------+
| test-0000000201 | 40-80 | vt_commerce  | demo        | ab3ffdd5_f25c_11ea_bab4_0242c0a8b007 | gh-ost   | 2020-09-09 05:24:33 | 2020-09-09 05:24:34 | complete         |
| test-0000000301 | 80-c0 | vt_commerce  | demo        | ab3ffdd5_f25c_11ea_bab4_0242c0a8b007 | gh-ost   | 2020-09-09 05:25:13 | 2020-09-09 05:25:14 | complete         |
| test-0000000401 | c0-   | vt_commerce  | demo        | ab3ffdd5_f25c_11ea_bab4_0242c0a8b007 | gh-ost   | 2020-09-09 05:25:13 | 2020-09-09 05:25:14 | complete         |
| test-0000000101 |   -40 | vt_commerce  | demo        | ab3ffdd5_f25c_11ea_bab4_0242c0a8b007 | gh-ost   | 2020-09-09 05:25:13 | 2020-09-09 05:25:14 | complete         |
+-----------------+-------+--------------+-------------+--------------------------------------+----------+---------------------+---------------------+------------------+

$ vtctlclient OnlineDDL commerce show 8a797518_f25c_11ea_bab4_0242c0a8b007
+-----------------+-------+--------------+-------------+--------------------------------------+----------+---------------------+---------------------+------------------+
|     Tablet      | shard | mysql_schema | mysql_table |            migration_uuid            | strategy |  started_timestamp  | completed_timestamp | migration_status |
+-----------------+-------+--------------+-------------+--------------------------------------+----------+---------------------+---------------------+------------------+
| test-0000000401 | c0-   | vt_commerce  | demo        | 8a797518_f25c_11ea_bab4_0242c0a8b007 | gh-ost   | 2020-09-09 05:23:32 |                     | running          |
| test-0000000201 | 40-80 | vt_commerce  | demo        | 8a797518_f25c_11ea_bab4_0242c0a8b007 | gh-ost   | 2020-09-09 05:23:32 | 2020-09-09 05:23:33 | complete         |
| test-0000000301 | 80-c0 | vt_commerce  | demo        | 8a797518_f25c_11ea_bab4_0242c0a8b007 | gh-ost   | 2020-09-09 05:23:32 |                     | running          |
| test-0000000101 |   -40 | vt_commerce  | demo        | 8a797518_f25c_11ea_bab4_0242c0a8b007 | gh-ost   | 2020-09-09 05:23:32 |                     | running          |
+-----------------+-------+--------------+-------------+--------------------------------------+----------+---------------------+---------------------+------------------+

$ vtctlclient OnlineDDL commerce show 8a797518_f25c_11ea_bab4_0242c0a8b007
+-----------------+-------+--------------+-------------+--------------------------------------+----------+---------------------+---------------------+------------------+
|     Tablet      | shard | mysql_schema | mysql_table |            migration_uuid            | strategy |  started_timestamp  | completed_timestamp | migration_status |
+-----------------+-------+--------------+-------------+--------------------------------------+----------+---------------------+---------------------+------------------+
| test-0000000401 | c0-   | vt_commerce  | demo        | 8a797518_f25c_11ea_bab4_0242c0a8b007 | gh-ost   | 2020-09-09 05:23:32 |                     | failed           |
| test-0000000101 |   -40 | vt_commerce  | demo        | 8a797518_f25c_11ea_bab4_0242c0a8b007 | gh-ost   | 2020-09-09 05:23:32 |                     | failed           |
| test-0000000301 | 80-c0 | vt_commerce  | demo        | 8a797518_f25c_11ea_bab4_0242c0a8b007 | gh-ost   | 2020-09-09 05:23:32 |                     | failed           |
| test-0000000201 | 40-80 | vt_commerce  | demo        | 8a797518_f25c_11ea_bab4_0242c0a8b007 | gh-ost   | 2020-09-09 05:23:32 | 2020-09-09 05:23:33 | complete         |
+-----------------+-------+--------------+-------------+--------------------------------------+----------+---------------------+---------------------+------------------+

$ vtctlclient OnlineDDL commerce show recent
+-----------------+-------+--------------+-------------+--------------------------------------+----------+---------------------+---------------------+------------------+
|     Tablet      | shard | mysql_schema | mysql_table |            migration_uuid            | strategy |  started_timestamp  | completed_timestamp | migration_status |
+-----------------+-------+--------------+-------------+--------------------------------------+----------+---------------------+---------------------+------------------+
| test-0000000201 | 40-80 | vt_commerce  | demo        | 63b5db0c_f25c_11ea_bab4_0242c0a8b007 | gh-ost   | 2020-09-09 05:22:41 | 2020-09-09 05:22:42 | complete         |
| test-0000000201 | 40-80 | vt_commerce  | demo        | 8a797518_f25c_11ea_bab4_0242c0a8b007 | gh-ost   | 2020-09-09 05:23:32 | 2020-09-09 05:23:33 | complete         |
| test-0000000201 | 40-80 | vt_commerce  | demo        | ab3ffdd5_f25c_11ea_bab4_0242c0a8b007 | gh-ost   | 2020-09-09 05:24:33 | 2020-09-09 05:24:34 | complete         |
| test-0000000301 | 80-c0 | vt_commerce  | demo        | 63b5db0c_f25c_11ea_bab4_0242c0a8b007 | gh-ost   | 2020-09-09 05:22:41 | 2020-09-09 05:22:42 | complete         |
| test-0000000301 | 80-c0 | vt_commerce  | demo        | 8a797518_f25c_11ea_bab4_0242c0a8b007 | gh-ost   | 2020-09-09 05:23:32 |                     | failed           |
| test-0000000301 | 80-c0 | vt_commerce  | demo        | ab3ffdd5_f25c_11ea_bab4_0242c0a8b007 | gh-ost   | 2020-09-09 05:25:13 | 2020-09-09 05:25:14 | complete         |
| test-0000000401 | c0-   | vt_commerce  | demo        | 63b5db0c_f25c_11ea_bab4_0242c0a8b007 | gh-ost   | 2020-09-09 05:22:41 | 2020-09-09 05:22:42 | complete         |
| test-0000000401 | c0-   | vt_commerce  | demo        | 8a797518_f25c_11ea_bab4_0242c0a8b007 | gh-ost   | 2020-09-09 05:23:32 |                     | failed           |
| test-0000000401 | c0-   | vt_commerce  | demo        | ab3ffdd5_f25c_11ea_bab4_0242c0a8b007 | gh-ost   | 2020-09-09 05:25:13 | 2020-09-09 05:25:14 | complete         |
| test-0000000101 |   -40 | vt_commerce  | demo        | 63b5db0c_f25c_11ea_bab4_0242c0a8b007 | gh-ost   | 2020-09-09 05:22:41 | 2020-09-09 05:22:42 | complete         |
| test-0000000101 |   -40 | vt_commerce  | demo        | 8a797518_f25c_11ea_bab4_0242c0a8b007 | gh-ost   | 2020-09-09 05:23:32 |                     | failed           |
| test-0000000101 |   -40 | vt_commerce  | demo        | ab3ffdd5_f25c_11ea_bab4_0242c0a8b007 | gh-ost   | 2020-09-09 05:25:13 | 2020-09-09 05:25:14 | complete         |
+-----------------+-------+--------------+-------------+--------------------------------------+----------+---------------------+---------------------+------------------+

$ vtctlclient OnlineDDL commerce show failed
+-----------------+-------+--------------+-------------+--------------------------------------+----------+---------------------+---------------------+------------------+
|     Tablet      | shard | mysql_schema | mysql_table |            migration_uuid            | strategy |  started_timestamp  | completed_timestamp | migration_status |
+-----------------+-------+--------------+-------------+--------------------------------------+----------+---------------------+---------------------+------------------+
| test-0000000301 | 80-c0 | vt_commerce  | demo        | 8a797518_f25c_11ea_bab4_0242c0a8b007 | gh-ost   | 2020-09-09 05:23:32 |                     | failed           |
| test-0000000401 | c0-   | vt_commerce  | demo        | 8a797518_f25c_11ea_bab4_0242c0a8b007 | gh-ost   | 2020-09-09 05:23:32 |                     | failed           |
| test-0000000101 |   -40 | vt_commerce  | demo        | 8a797518_f25c_11ea_bab4_0242c0a8b007 | gh-ost   | 2020-09-09 05:23:32 |                     | failed           |
+-----------------+-------+--------------+-------------+--------------------------------------+----------+---------------------+---------------------+------------------+
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
+-----------------+-------+--------------+-------------+--------------------------------------+----------+---------------------+---------------------+------------------+
|     Tablet      | shard | mysql_schema | mysql_table |            migration_uuid            | strategy |  started_timestamp  | completed_timestamp | migration_status |
+-----------------+-------+--------------+-------------+--------------------------------------+----------+---------------------+---------------------+------------------+
| test-0000000301 | 80-c0 | vt_commerce  | demo        | 2201058f_f266_11ea_bab4_0242c0a8b007 | gh-ost   | 2020-09-09 06:32:31 |                     | running          |
| test-0000000101 |   -40 | vt_commerce  | demo        | 2201058f_f266_11ea_bab4_0242c0a8b007 | gh-ost   | 2020-09-09 06:32:31 |                     | running          |
| test-0000000401 | c0-   | vt_commerce  | demo        | 2201058f_f266_11ea_bab4_0242c0a8b007 | gh-ost   | 2020-09-09 06:32:31 |                     | running          |
| test-0000000201 | 40-80 | vt_commerce  | demo        | 2201058f_f266_11ea_bab4_0242c0a8b007 | gh-ost   | 2020-09-09 06:32:31 |                     | running          |
+-----------------+-------+--------------+-------------+--------------------------------------+----------+---------------------+---------------------+------------------+

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
+-----------------+-------+--------------+-------------+--------------------------------------+----------+---------------------+---------------------+------------------+
|     Tablet      | shard | mysql_schema | mysql_table |            migration_uuid            | strategy |  started_timestamp  | completed_timestamp | migration_status |
+-----------------+-------+--------------+-------------+--------------------------------------+----------+---------------------+---------------------+------------------+
| test-0000000401 | c0-   | vt_commerce  | demo        | 2201058f_f266_11ea_bab4_0242c0a8b007 | gh-ost   | 2020-09-09 06:32:31 |                     | failed           |
| test-0000000301 | 80-c0 | vt_commerce  | demo        | 2201058f_f266_11ea_bab4_0242c0a8b007 | gh-ost   | 2020-09-09 06:32:31 |                     | failed           |
| test-0000000201 | 40-80 | vt_commerce  | demo        | 2201058f_f266_11ea_bab4_0242c0a8b007 | gh-ost   | 2020-09-09 06:32:31 |                     | failed           |
| test-0000000101 |   -40 | vt_commerce  | demo        | 2201058f_f266_11ea_bab4_0242c0a8b007 | gh-ost   | 2020-09-09 06:32:31 |                     | failed           |
+-----------------+-------+--------------+-------------+--------------------------------------+----------+---------------------+---------------------+------------------+
```


## Retrying a migration

The user may retry running a migration. If the migration is in `failed` or in `cancelled` state, Vitess will re-run the migration, with exact same arguments as previously intended. If the migration is in any other state, `retry` does nothing.

It is not possible to retry a migration with different options. e.g. if the user initially runs `ALTER WITH 'gh-ost' '--max-load Threads_running=200' TABLE demo MODIFY id BIGINT` and the migration failed, it is not possible to retry with `'--max-load Threads_running=500'`.

Continuing the above example, where we cancelled a migration while running, we now retry it:

```shell
$ vtctlclient OnlineDDL commerce show 2201058f_f266_11ea_bab4_0242c0a8b007
+-----------------+-------+--------------+-------------+--------------------------------------+----------+---------------------+---------------------+------------------+
|     Tablet      | shard | mysql_schema | mysql_table |            migration_uuid            | strategy |  started_timestamp  | completed_timestamp | migration_status |
+-----------------+-------+--------------+-------------+--------------------------------------+----------+---------------------+---------------------+------------------+
| test-0000000401 | c0-   | vt_commerce  | demo        | 2201058f_f266_11ea_bab4_0242c0a8b007 | gh-ost   | 2020-09-09 06:32:31 |                     | failed           |
| test-0000000301 | 80-c0 | vt_commerce  | demo        | 2201058f_f266_11ea_bab4_0242c0a8b007 | gh-ost   | 2020-09-09 06:32:31 |                     | failed           |
| test-0000000201 | 40-80 | vt_commerce  | demo        | 2201058f_f266_11ea_bab4_0242c0a8b007 | gh-ost   | 2020-09-09 06:32:31 |                     | failed           |
| test-0000000101 |   -40 | vt_commerce  | demo        | 2201058f_f266_11ea_bab4_0242c0a8b007 | gh-ost   | 2020-09-09 06:32:31 |                     | failed           |
+-----------------+-------+--------------+-------------+--------------------------------------+----------+---------------------+---------------------+------------------+

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
+-----------------+-------+--------------+-------------+--------------------------------------+----------+-------------------+---------------------+------------------+
|     Tablet      | shard | mysql_schema | mysql_table |            migration_uuid            | strategy | started_timestamp | completed_timestamp | migration_status |
+-----------------+-------+--------------+-------------+--------------------------------------+----------+-------------------+---------------------+------------------+
| test-0000000201 | 40-80 | vt_commerce  | demo        | 2201058f_f266_11ea_bab4_0242c0a8b007 | gh-ost   |                   |                     | queued           |
| test-0000000101 |   -40 | vt_commerce  | demo        | 2201058f_f266_11ea_bab4_0242c0a8b007 | gh-ost   |                   |                     | queued           |
| test-0000000301 | 80-c0 | vt_commerce  | demo        | 2201058f_f266_11ea_bab4_0242c0a8b007 | gh-ost   |                   |                     | queued           |
| test-0000000401 | c0-   | vt_commerce  | demo        | 2201058f_f266_11ea_bab4_0242c0a8b007 | gh-ost   |                   |                     | queued           |
+-----------------+-------+--------------+-------------+--------------------------------------+----------+-------------------+---------------------+------------------+

$ vtctlclient OnlineDDL commerce show 2201058f_f266_11ea_bab4_0242c0a8b007
+-----------------+-------+--------------+-------------+--------------------------------------+----------+---------------------+---------------------+------------------+
|     Tablet      | shard | mysql_schema | mysql_table |            migration_uuid            | strategy |  started_timestamp  | completed_timestamp | migration_status |
+-----------------+-------+--------------+-------------+--------------------------------------+----------+---------------------+---------------------+------------------+
| test-0000000101 |   -40 | vt_commerce  | demo        | 2201058f_f266_11ea_bab4_0242c0a8b007 | gh-ost   | 2020-09-09 06:37:33 |                     | running          |
| test-0000000401 | c0-   | vt_commerce  | demo        | 2201058f_f266_11ea_bab4_0242c0a8b007 | gh-ost   | 2020-09-09 06:37:33 |                     | running          |
| test-0000000201 | 40-80 | vt_commerce  | demo        | 2201058f_f266_11ea_bab4_0242c0a8b007 | gh-ost   | 2020-09-09 06:37:33 |                     | running          |
| test-0000000301 | 80-c0 | vt_commerce  | demo        | 2201058f_f266_11ea_bab4_0242c0a8b007 | gh-ost   | 2020-09-09 06:37:33 |                     | running          |
+-----------------+-------+--------------+-------------+--------------------------------------+----------+---------------------+---------------------+------------------+
```

## Auto retry after failure

Vitess keeps track of:

- which `vttablet` initiated the migration
- how many times a migration has been retried
- whether a migration failed due to a `vttablet` failure (as is the case in a failover scenario)

Vitess will auto-retry a failed migration when:

- The migration failed due to a `vttablet` failure, and
- it has not been retried (this is a temporary restriction)

The migration will be transitioned into `queued` state, as if the user requested a `retry` operation. Note that this takes place on a per-shard basis.

The primary use case is a primary failure and failover. The newly promoted tablet will be able to retry the migration that broke during the previous primary failure. To clarify, the migration will start anew, as at this time there is no mechanism to resume a broken migration.

## gh-ost and pt-online-schema-change

The user must pick one of these migration tools. The tools differ in features, operation, load, and more.  

## Using gh-ost

[gh-ost](https://github.com/github/gh-ost) was developed by [GitHub](https://github.com) as a lightweight and safe schema migration tool.

To be able to run online schema migrations via `gh-ost`:

- If you're on Linux/amd64 architecture, and on `glibc` `2.3` or similar, there are no further dependencies. Vitess comes with a built-in `gh-ost` binary, that is compatible with your system.
- On other architectures:
  - Have `gh-ost` executable installed
  - Run `vttablet` with `-gh-ost-path=/full/path/to/gh-ost` flag

Vitess automatically creates a MySQL account for the migration, with a randomly generated password. The account is destroyed at the end of the migration.

Vitess takes care of setting up the necessary command line flags. It automatically creates a hooks directory and populates it with hooks that report `gh-ost`'s progress back to Vitess. You may supply additional flags for your migration as part of the `ALTER` statement. Examples:

- `ALTER WITH 'gh-ost' '--max-load Threads_running=200' TABLE demo MODIFY id BIGINT`
- `ALTER WITH 'gh-ost' '--critical-load Threads_running=500 --critical-load-hibernate-seconds=60' --default-retries=512 TABLE demo MODIFY id BIGINT`
- `ALTER WITH 'gh-ost' '--allow-nullable-unique-key --chunk-size 200' TABLE demo MODIFY id BIGINT`

Do not override the following flags: `alter, database, table, execute, max-lag, force-table-names, serve-socket-file, hooks-path, hooks-hint-token, panic-flag-file`.

`gh-ost` throttling is done via Vitess's own tablet throttler, based on replication lag.


## Using pt-online-schema-change

[pt-online-schema-change](https://www.percona.com/doc/percona-toolkit/3.0/pt-online-schema-change.html) is part of [Percona Toolkit](https://www.percona.com/doc/percona-toolkit/3.0/index.html), a set of Perl scripts. To be able to use `pt-online-schema-change`, you must have the following setup on all your tablet servers (normally tablets are co-located with MySQL on same host and so this implies setting up on all MySQL servers):

- `pt-online-schema-change` tool installed and is executable
- Perl `libdbi` and `libdbd-mysql` modules installed. e.g. on Debian/Ubuntu, `sudo apt-get install libdbi-perl libdbd-mysql-perl`
- Run `vttablet` with `-pt-osc-path=/full/path/to/pt-online-schema-change` flag.

Vitess automatically creates a MySQL account for the migration, with a randomly generated password. The account is destroyed at the end of the migration.

Vitess takes care of supplying the command line flags, the DSN, the username & password. It also sets up `PLUGINS` used to communicate migration progress back to the tablet. You may supply additional flags for your migration as part of the `ALTER` statement. Examples:

- `ALTER WITH 'pt-osc' '--null-to-not-null' TABLE demo MODIFY id BIGINT`
- `ALTER WITH 'pt-osc' '--max-load Threads_running=200' TABLE demo MODIFY id BIGINT`
- `ALTER WITH 'pt-osc' '--alter-foreign-keys-method auto --chunk-size 200' TABLE demo MODIFY id BIGINT`

Vitess tracks the state of the `pt-osc` migration. If it fails, Vitess makes sure to drop the migration triggers. Vitess keeps track of the migration even if the tablet itself restarts for any reason. Normally that would terminate the migration; vitess will cleanup the triggers if so, or will happily let the migration run to completion if not.

Do not override the following flags: `alter, pid, plugin, dry-run, execute, new-table-name, [no-]drop-new-table, [no-]drop-old-table`.

`pt-osc` throttling is done via Vitess's own tablet throttler, based on replication lag, and via a `pt-online-schema-change` plugin.


## Throttling

Schema migrations use the tablet throttler, which is a cooperative throttler service based on replication lag. The tablet throttler automatically detectes topology `REPLICA` tablets and adapts to changes in the topology. See [Tablet throttler](../../../reference/features/tablet-throttler/).

**NOTE** that at this time the tablet throttler is an experimental feature and is opt in. Enable it with `vttablet`'s `-enable-lag-throttler` flag. If the tablet throttler is disabled, schema migrations will not throttle on replication lag.

## Table cleanup

Both `gh-ost` and `pt-online-schema-change` leave artifacts behind. Whether successful or failed, either the original table or the _ghost_ table are left still populated at the end of the migration. Vitess explicitly configures both tools to not drop those tables. The reason is that in MySQL, a `DROP TABLE` operation can be dangerous in production as it commonly locks the buffer pool for a substantial period.

Artifact tables are identifiable via `SELECT artifacts FROM _vt.schema_migrations` in a `VExec` command, see below.

Vitess automatically cleans up those tables as soon as a migration completes (either successful or failed). You will normally not need to do anything.

## VExec commands for greater control and visibility

`vtctlclient OnlineDDL` command should provide with most needs. However, Vitess gives the user greater control through the `VExec` command and via SQL queries.

For schema migrations, Vitess allows operations on the virtual table `_vt.schema_migrations`. Queries on this virtual table scatter to the underlying tablets and gather or manipulate data on their own, private backend tables (which incidentally are called by the same name). `VExec` only allows specific types of queries on that table.

- `SELECT`: you may SELECT any column, or `SELECT *`. `vtctlclient OnlineDDL show` commands only present with a subset of columns, and so running ` VExec` `SELECT` provides greater visibility. Some columns that are not shown are:
  - `log_path`: tablet server and path where migration logs are.
  - `artifacts`: tables created by the migration. This can be used to determine which tables need cleanup.
  - `alter`: the exact `alter` statement used by the migration
  - `options`: any options passed by the user (e.g. `--max-load=Threads_running=200`)
  - Various timestamps indicating the migratoin progress
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


