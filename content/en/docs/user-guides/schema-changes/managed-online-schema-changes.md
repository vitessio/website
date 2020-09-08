---
title: Managed, Online Schema Changes
weight: 2
aliases: ['/docs/user-guides/managed-online-schema-changes/']
---

**Note:** this feature is **EXPERIMENTAL**

Vitess offers managed, online schema migrations, via [gh-ost](https://github.com/github/gh-ost) and [pt-online-schema-change](https://www.percona.com/doc/percona-toolkit/3.0/pt-online-schema-change.html). As a quick breakdown:

- Vitess recognized a special `ALTER TABLE` syntax that indicates on online schema hcnage request.
- Vitess responds to on online schema change request with a job ID
- Vitess resolves affected shards
- A shard's `primary` tablet schedules the migration to run when possible
- The tablets run migrations via `gh-ost` or `pt-online-schema-change`
- Vitess provides the user the mechanism to show migration status, cancel or retry migrations, based on the job ID

## Syntax

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

## Tracking migrations

You may track the status of a single migration, of all or recent migrations, or of migrations in a specific state. 

## Cancelling a migration

## Retrying a migration

## Using gh-ost

[gh-ost](https://github.com/github/gh-ost) was developed by [GitHub](https://github.com) as a lightweight and safe schema migration tool.

To be able to run online schema migrations via `gh-ost`:

- If you're on Linux/amd64 architecture, and on `glibc` `2.3` or similar, there are no further dependencies. Vitess comes with a built-in `gh-ost` binary, that is compatible with your system.
- On other architectures:
  - `gh-ost` executable installed
  - Run `vttablet` with `-gh-ost-path=/full/path/to/gh-ost` flag


## Using pt-online-schema-change

[pt-online-schema-change](https://www.percona.com/doc/percona-toolkit/3.0/pt-online-schema-change.html) is part of [Percona Toolkit](https://www.percona.com/doc/percona-toolkit/3.0/index.html), a set of Perl scripts. To be able to use `pt-online-schema-change`, you must have the following setup on all your tablet servers (normally tablets are co-located with MySQL on same host and so this implies setting up on all MySQL servers):

- `pt-online-schema-change` tool installed and is executable
- Perl `libdbi` and `libdbd-mysql` modules installed. e.g. on Debian/Ubuntu, `sudo apt-get install libdbi-perl libdbd-mysql-perl`
- Run `vttablet` with `-pt-osc-path=/full/path/to/pt-online-schema-change` flag.

Vitess takes care of supplying the command line flags, the DSN, the username & password. It also sets up `PLUGINS` used to communicate migration progress back to the tablet. You may supply additional flags for your migration as part of the `ALTER` statement. Examples:

- `ALTER WITH 'pt-osc' '--null-to-not-null' TABLE demo MODIFY id BIGINT`
- `ALTER WITH 'pt-osc' '--max-load Threads_running=200' TABLE demo MODIFY id BIGINT`
- `ALTER WITH 'pt-osc' '--alter-foreign-keys-method auto --chunk-size 200' TABLE demo MODIFY id BIGINT`

Vitess tracks the state of the `pt-osc` migration. If it fails, Vitess makes sure to drop the migration triggers. Vitess keeps track of the migration even if the tablet itself restarts for any reason. Normally that would terminate the migration; vitess will cleanup the triggers if so, or will happily let the migration run to completion if not.

## Throttling
## Table cleanup

#


cancel retry show
show all
show recent
show UUID
cancel UUID: states
retry UUID: states
logs path
SELECT
UPDATE




vtctl -topo_implementation consul -topo_global_server_address consul1:8500 -topo_global_root vitess/global  OnlineDDL test_keyspace show all


