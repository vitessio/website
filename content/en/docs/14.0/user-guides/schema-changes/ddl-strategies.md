---
title: Online DDL strategies
weight: 3
aliases: ['/docs/user-guides/schema-changes/ddl-strategies/']
---

Vitess supports both managed, online schema migrations (aka Online DDL) as well as unmanaged migrations. How Vitess runs a schema migration depends on the _DDL strategy_. Vitess allows these strategies:

- `direct`: the direct apply of DDL to your database. This is not an online DDL. It is a synchronous and blocking operation. This is the default strategy. 
- `vitess` (formerly known as `online`): utilizes Vitess's built in [VReplication](../../../reference/vreplication/vreplication/) mechanism.
- `gh-ost`: uses 3rd party GitHub's [gh-ost](https://github.com/github/gh-ost) tool.
- `pt-osc`: uses 3rd party Percona's [pt-online-schema-change](https://www.percona.com/doc/percona-toolkit/3.0/pt-online-schema-change.html) as part of [Percona Toolkit](https://www.percona.com/doc/percona-toolkit/3.0/index.html)

`CREATE` and `DROP` are managed in the same way, by Vitess, whether strategy is `vitess`, `gh-ost` or `pt-osc`.

See also [ddl_strategy flags](../ddl-strategy-flags).

## Specifying a DDL strategy

You will set either `@@ddl_strategy` session variable, or `-ddl_strategy` command line flag. Examples:

#### Via vtctl/vtctlclient
```shell
$ vtctlclient ApplySchema -ddl_strategy "vitess" -sql "ALTER TABLE demo MODIFY id bigint UNSIGNED" commerce
a2994c92_f1d4_11ea_afa3_f875a4d24e90
```

```shell
$ vtctlclient ApplySchema -ddl_strategy "gh-ost --max-load Threads_running=200" -sql "ALTER TABLE demo add column status int" commerce
```

#### Via VTGate


```shell
$ mysql -h 127.0.0.1 -P 15306 commerce
Welcome to the MySQL monitor.  Commands end with ; or \g.

mysql> SET @@ddl_strategy='vitess';
Query OK, 0 rows affected (0.00 sec)

mysql> ALTER TABLE demo ADD COLUMN sample INT;
+--------------------------------------+
| uuid                                 |
+--------------------------------------+
| fa2fb689_f1d5_11ea_859e_f875a4d24e90 |
+--------------------------------------+
1 row in set (0.00 sec)
```

## Choosing a DDL strategy

Different strategies have different behavior for `ALTER` statements. Sections below first break down specific handling and notes for each strategy, followed by an evaluation of the differences.

### vitess

The `vitess` strategy invokes Vitess's built in [VReplication](../../../reference/vreplication/vreplication/) mechanism. It is the mechanism behind resharding, materialized views, imports from external databases, and more. VReplication migrations use the same logic for copying data as do other VReplication operations, and as such the `vitess` strategy is known to be compatible with overall Vitess behavior. VReplication is authored by the maintainers of Vitess.

VReplication migrations enjoy the general features of VReplication:

- Seamless integration with Vitess.
- Seamless use of the throttler mechanism.
- Visibility into internal working and status of VReplication.
- Agnostic to planned reparenting and to unplanned failovers. A migration will resume from point of interruption shortly after a new primary is available.

VReplication migrations further:

- Are [revertible](../revertible-migrations): you may switch back to the pre-migration schema without losing any data accumulated during and post migration.
- Support a wider range of schema changes. For example, while `gh-ost` has a strict requirement for a shared unique key pre/post migration, `vitess` migrations may work with different keys, making it possible to modify a table's `PRIMARY KEY` without having to rely on an additional `UNIQUE KEY`.

### gh-ost

[gh-ost](https://github.com/github/gh-ost) was developed by [GitHub](https://github.com) as a lightweight and safe schema migration tool.

To be able to run online schema migrations via `gh-ost`:

- If you're on Linux/amd64 architecture, and on `glibc` `2.3` or similar, there are no further dependencies. Vitess comes with a built-in `gh-ost` binary, that is compatible with your system. Note that the Vitess Docker images use this architecture, and `gh-ost` comes pre-bundled and compatible.
- On other architectures:
  - Have `gh-ost` executable installed
  - Run `vttablet` with `-gh-ost-path=/full/path/to/gh-ost` flag

Vitess automatically creates a MySQL account for the migration, with a randomly generated password. The account is destroyed at the end of the migration.

Vitess takes care of setting up the necessary command line flags. It automatically creates a hooks directory and populates it with hooks that report `gh-ost`'s progress back to Vitess. You may supply additional flags for your migration as part of `@@ddl_strategy` session variable (using `VTGate`) or `-ddl_strategy` command line flag (using `vtctl`). Examples:

- `set @@ddl_strategy='gh-ost --max-load Threads_running=200';`
- `set @@ddl_strategy='gh-ost --max-load Threads_running=200 --critical-load Threads_running=500 --critical-load-hibernate-seconds=60 --default-retries=512';`
- `vtctl ApplySchema -ddl_strategy "gh-ost --allow-nullable-unique-key --chunk-size 200" ...`

**Note:** Do not override the following flags: `alter, database, table, execute, max-lag, force-table-names, serve-socket-file, hooks-path, hooks-hint-token, panic-flag-file`. Overriding any of these may cause Vitess to lose control and track of the migration, or even to migrate the wrong table.

`gh-ost` throttling is done via Vitess's own tablet throttler, based on replication lag.


### Using pt-online-schema-change

[pt-online-schema-change](https://www.percona.com/doc/percona-toolkit/3.0/pt-online-schema-change.html) is part of [Percona Toolkit](https://www.percona.com/doc/percona-toolkit/3.0/index.html), a set of Perl scripts. To be able to use `pt-online-schema-change`, you must have the following setup on all your tablet servers (normally tablets are co-located with MySQL on same host and so this implies setting up on all MySQL servers):

- `pt-online-schema-change` tool installed and is executable
- Perl `libdbi` and `libdbd-mysql` modules installed. e.g. on Debian/Ubuntu, `sudo apt-get install libdbi-perl libdbd-mysql-perl`
- Run `vttablet` with `-pt-osc-path=/full/path/to/pt-online-schema-change` flag.

Note that on Vitess Docker images, `pt-online-schema-change` and dependencies are pre-installed.

Vitess automatically creates a MySQL account for the migration, with a randomly generated password. The account is destroyed at the end of the migration.

Vitess takes care of supplying the command line flags, the DSN, the username & password. It also sets up `PLUGINS` used to communicate migration progress back to the tablet. You may supply additional flags for your migration as part of `@@ddl_strategy` session variable (using `VTGate`) or `-ddl_strategy` command line flag (using `vtctl`). Examples:

- `set @@ddl_strategy='pt-osc --null-to-not-null';`
- `set @@ddl_strategy='pt-osc --max-load Threads_running=200';`
- `vtctl ApplySchema -ddl_strategy "pt-osc --alter-foreign-keys-method auto --chunk-size 200" ...`

Vitess tracks the state of the `pt-osc` migration. If it fails, Vitess makes sure to drop the migration triggers. Vitess keeps track of the migration even if the tablet itself restarts for any reason. Normally that would terminate the migration; Vitess will cleanup the triggers if so, or will happily let the migration run to completion if not.

Do not override the following flags: `alter, pid, plugin, dry-run, execute, new-table-name, [no-]drop-new-table, [no-]drop-old-table`.

`pt-osc` throttling is done via Vitess's own tablet throttler, based on replication lag, and via a `pt-online-schema-change` plugin.

### Comparing the options

There are pros and cons to using any of the strategies. Some notable differences:

#### General

- All three options mimic an `ALTER TABLE` statement by creating and populating a shadow/ghost table behind the scenes, slowly bringing it up to date, and finally switching between the original and shadow tables.
- All three options utilize the Vitess throttler.

#### Support

- VReplication (`vitess` strategy) is internal to Vitess and supported by the Vitess maintainers.
- `gh-ost` enjoys partial, informal support from Vitess maintainers.
- `pt-online-schema-change` is out of the maintainers control.

#### Setup

- VReplication is part of Vitess
- A `gh-ost` binary is embedded within the Vitess binary, compatible with `glibc 2.3` and `Linux/amd64`. The user may choose to use their own `gh-ost` binary, configured with `-gh-ost-path`.
- `pt-online-schema-change` is not included in Vitess, and the user needs to set it up on tablet hosts.
  - Note that on Vitess Docker images, `pt-online-schema-change` and dependencies _are_ pre-installed.

#### Load

- `pt-online-schema-change` uses triggers to propagate changes. This method is traditionally known to generate high load on the server. Both VReplication and `gh-ost` tail the binary logs to capture changes, and this approach is known to be more lightweight.
- When throttled, `pt-online-schema-change` still runs trigger actions, whereas both VReplication and `gh-ost` cease transfer of data (they may keep minimal bookkeeping operations).

#### Cut-over

- Both `pt-online-schema-change` and `gh-ost` have an atomic cut-over based on MySQL locking. At the end of the migration, the tables are switched, and incoming queries are momentarily blocked, but not lost.
- `vitess` offers a combined Vitess/MySQL locking logic:
  - To queries on the migrated table, that are going through Vitess (ie route through `VTGate`), the cut-over is blocking. Vitess will buffer incoming queries during cut-over, and will allow them to operate once the cut-over is complete.
  - Any queries on the migrated table that are not going through Vitess and which operate directly on the MySQL server will experience a brief outage: the queries will notice the table does not exist momentarily.
  - It is at any case safe, in terms of data consistency, to run both types of queries throughout the migration and specifically during the cut-over.

#### MySQL compatibility

- `pt-online-schema-change` partially supports foreign keys. Neither `gh-ost` nor `VReplication` support foreign keys.

## Vitess functionality comparison

| Strategy | Managed | Online | Trackable | Declarative | Revertible          | Recoverable |
|----------|---------|--------|-----------|-------------|---------------------|-------------|
| `direct` | No      | MySQL* | No        | No          | No                  | No          |
| `pt-osc` | Yes     | Yes*   | Yes       | Yes         | `CREATE,DROP`       | No*         |
| `gh-ost` | Yes     | Yes*   | Yes+      | Yes         | `CREATE,DROP`       | No*         |
| `vitess` | Yes     | Yes*   | Yes+      | Yes         | `CREATE,DROP,ALTER` | Yes         |

- **Managed**: whether Vitess schedules and operates the migration
- **Online**:
  - MySQL supports limited online ("In place") DDL and instant DDL. See [support chart](https://dev.mysql.com/doc/refman/8.0/en/innodb-online-ddl-operations.html).
  - `gh-ost`, `vitess` do not support foreign keys
  - `pt-osc` has support for foreign keys (may apply collateral blocking operations)
- **Trackable**: able to determine migration state (`ready`, `running`, `complete` etc)
  - `vitess` and `gh-ost` strategies also makes available _progress %_ and _ETA seconds_
- **Declarative**: support `-declarative` flag
- **Revertible**: `vitess` strategy supports [revertible](../revertible-migrations/) `ALTER` statements (or `ALTER`s implied by `-declarative` migrations). All managed strategies supports revertible `CREATE` and `DROP`.
- **Recoverable**: a `vitess` migration interrupted by planned/unplanned failover, [automatically resumes](../recoverable-migrations/) work from point of interruption. `gh-ost` and `pt-osc` will not resume after failover, but Vitess will automatically retry the migration (by marking the migration as failed and by initiating a `RETRY`), exactly once for any migration.
