---
title: Online DDL strategies
weight: 3
aliases: ['/docs/user-guides/schema-changes/ddl-strategies/']
---

Vitess supports both managed, online schema migrations (aka Online DDL) as well as unmanaged migrations. How Vitess runs a schema migration depends on the _DDL strategy_. Vitess allows these strategies:

- `vitess` (formerly known as `online`): utilizes Vitess's built-in [VReplication](../../../reference/vreplication/vreplication/) mechanism. This is the preferred strategy in Vitess.
- `gh-ost`: uses 3rd party GitHub's [gh-ost](https://github.com/github/gh-ost) tool. `gh-ost` strategy is **unsupported** and slated to be removed in future versions.
- `pt-osc`: uses 3rd party Percona's [pt-online-schema-change](https://www.percona.com/doc/percona-toolkit/3.0/pt-online-schema-change.html) as part of [Percona Toolkit](https://www.percona.com/doc/percona-toolkit/3.0/index.html). `pt-osc` strategy is **experimental** and slated to be removed in future versions.
- `mysql`: managed by the Online DDL scheduler, but executed via normal MySQL statement. Whether it is blocking or not is up to the specific query.
- `direct`: unmanaged. The direct apply of DDL to your database. Whether it is blocking or not is up to the specific query.

`CREATE` and `DROP` are managed in the same way, by Vitess, whether strategy is `vitess`, `gh-ost` or `pt-osc`.

See also [ddl_strategy flags](../ddl-strategy-flags).

## Specifying a DDL strategy

You can apply DDL strategies to your schema changes in these different ways:

- The command `vtctldclient ApplySchema` takes a `--ddl-strategy` flag. The strategy applies to the specific changes requested in the command. The following example applies the `vitess` strategy to three migrations submitted together: 

```sh
$ vtctldclient ApplySchema --ddl-strategy "vitess" --sql "ALTER TABLE demo MODIFY id bigint UNSIGNED; CREATE TABLE sample (id int PRIMARY KEY); DROP TABLE another;" commerce
ab185fdf_6e46_11ee_8f23_0a43f95f28a3
```

- Set `vtgate --ddl_strategy` flag. Migrations executed from within `vtgate` will use said strategy.

```sh
$ vtgate --ddl_strategy="vitess"

$ mysql
```
```sql
mysql> alter table corder force;
+--------------------------------------+
| uuid                                 |
+--------------------------------------+
| 2015f08d_6e46_11ee_a918_0a43f95f28a3 |
+--------------------------------------+
```

- Set the `@@ddl_strategy` session variable to override the value of `vtgate`'s `--ddl_strategy` flag, for the current session.

```sql
mysql> set @@ddl_strategy="vitess --postpone-completion --allow-concurrent";
Query OK, 0 rows affected (0.01 sec)

mysql> alter table corder force;
+--------------------------------------+
| uuid                                 |
+--------------------------------------+
| 861f7de9_6e46_11ee_a918_0a43f95f28a3 |
+--------------------------------------+
```

## Choosing a DDL strategy

Different strategies have different behavior for `ALTER` statements. Sections below first break down specific handling and notes for each strategy, followed by an evaluation of the differences.

### vitess

The `vitess` strategy invokes Vitess's built in [VReplication](../../../reference/vreplication/vreplication/) mechanism. It is the mechanism behind resharding, materialized views, imports from external databases, and more. VReplication migrations use the same logic for copying data as do other VReplication operations, and as such the `vitess` strategy is known to be compatible with overall Vitess behavior. VReplication is authored by the maintainers of Vitess.

`vitess` migrations enjoy the general features of VReplication:

- Seamless integration with Vitess.
- Seamless use of the throttler mechanism.
- Visibility into internal working and status of VReplication.
- Agnostic to planned reparenting and to unplanned failovers. A migration will resume from point of interruption shortly after a new primary is available.

`vitess` migrations further:

- Are [revertible](../revertible-migrations): you may switch back to the pre-migration schema without losing any data accumulated during and post migration.
- Support a wider range of schema changes. For example, while `gh-ost` has a strict requirement for a shared unique key pre/post migration, `vitess` migrations may work with different keys, making it possible to modify a table's `PRIMARY KEY` without having to rely on an additional `UNIQUE KEY`.
- Support cut-over backoff: should a cut-over fail due to timeout, next cut-overs take place at increasing intervals and up to `30min` intevals, so as to not overwhelm production traffic.
- Support forced cut-over, to prioritise completion of the migration over any queries using the mgirated table, or over any transactions holding locks on the table.

### gh-ost

[gh-ost](https://github.com/github/gh-ost) was developed by [GitHub](https://github.com) as a lightweight and safe schema migration tool.

To be able to run online schema migrations via `gh-ost`:

- If you're on Linux/amd64 architecture, and on `glibc` `2.3` or similar, there are no further dependencies. Vitess comes with a built-in `gh-ost` binary, that is compatible with your system. Note that the Vitess Docker images use this architecture, and `gh-ost` comes pre-bundled and compatible.
- On other architectures:
  - Have `gh-ost` executable installed
  - Run `vttablet` with `--gh-ost-path=/full/path/to/gh-ost` flag

Vitess automatically creates a MySQL account for the migration, with a randomly generated password. The account is destroyed at the end of the migration.

Vitess takes care of setting up the necessary command line flags. It automatically creates a hooks directory and populates it with hooks that report `gh-ost`'s progress back to Vitess. You may supply additional flags for your migration as part of `@@ddl_strategy` session variable (using `VTGate`) or `--ddl-strategy` command line flag (using `vtctldclient`). Examples:

- `set @@ddl_strategy='gh-ost --max-load Threads_running=200';`
- `set @@ddl_strategy='gh-ost --max-load Threads_running=200 --critical-load Threads_running=500 --critical-load-hibernate-seconds=60 --default-retries=512';`
- `vtctldclient --ddl-strategy "gh-ost --allow-nullable-unique-key --chunk-size 200" ...`

**Note:** Do not override the following flags: `alter, database, table, execute, max-lag, force-table-names, serve-socket-file, hooks-path, hooks-hint-token, panic-flag-file`. Overriding any of these may cause Vitess to lose control and track of the migration, or even to migrate the wrong table.

`gh-ost` throttling is done via Vitess's own tablet throttler, based on replication lag.

{{< warning >}}
`gh-ost` strategy is **unsupported** and slated to be removed in future versions.
{{< /warning >}}

### Using pt-online-schema-change

[pt-online-schema-change](https://www.percona.com/doc/percona-toolkit/3.0/pt-online-schema-change.html) is part of [Percona Toolkit](https://www.percona.com/doc/percona-toolkit/3.0/index.html), a set of Perl scripts. To be able to use `pt-online-schema-change`, you must have the following setup on all your tablet servers (normally tablets are co-located with MySQL on same host and so this implies setting up on all MySQL servers):

- `pt-online-schema-change` tool installed and is executable
- Perl `libdbi` and `libdbd-mysql` modules installed. e.g. on Debian/Ubuntu, `sudo apt-get install libdbi-perl libdbd-mysql-perl`
- Run `vttablet` with `-pt-osc-path=/full/path/to/pt-online-schema-change` flag.

Note that on Vitess Docker images, `pt-online-schema-change` and dependencies are pre-installed.

Vitess automatically creates a MySQL account for the migration, with a randomly generated password. The account is destroyed at the end of the migration.

Vitess takes care of supplying the command line flags, the DSN, the username & password. It also sets up `PLUGINS` used to communicate migration progress back to the tablet. You may supply additional flags for your migration as part of `@@ddl_strategy` session variable (using `VTGate`) or `-ddl-strategy` command line flag (using `vtctldclient`). Examples:

- `set @@ddl_strategy='pt-osc --null-to-not-null';`
- `set @@ddl_strategy='pt-osc --max-load Threads_running=200';`
- `vtctldclient ApplySchema --ddl-strategy "pt-osc --alter-foreign-keys-method auto --chunk-size 200" ...`

Vitess tracks the state of the `pt-osc` migration. If it fails, Vitess makes sure to drop the migration triggers. Vitess keeps track of the migration even if the tablet itself restarts for any reason. Normally that would terminate the migration; Vitess will cleanup the triggers if so, or will happily let the migration run to completion if not.

Do not override the following flags: `alter, pid, plugin, dry-run, execute, new-table-name, [no-]drop-new-table, [no-]drop-old-table`.

`pt-osc` throttling is done via Vitess's own tablet throttler, based on replication lag, and via a `pt-online-schema-change` plugin.

{{< warning >}}
`pt-osc` strategy is **experimental** and slated to be removed in future versions.
{{< /warning >}}

### Comparing the options

There are pros and cons to using any of the strategies. Some notable differences:

#### General

- All three options mimic an `ALTER TABLE` statement by creating and populating a shadow/ghost table behind the scenes, slowly bringing it up to date, and finally switching between the original and shadow tables.
- All three options utilize the Vitess throttler.

#### Support

- VReplication (`vitess` strategy) is internal to Vitess and supported by the Vitess maintainers.
- `gh-ost` and `pt-online-schema-change` are not supported by the Vitess maintainers, and slated to be removed in future versions.

#### Setup

- VReplication is part of Vitess
- To use `gh-ost` strategy, the user must supply a `gh-ost` binary. By default, Vitess will look for the binary in `/usr/bin/gh-ost`. Otherwise, the user should configure the binary's full path with `--gh-ost-path`.
- `pt-online-schema-change` is not included in Vitess, and the user needs to set it up on tablet hosts.
  - Note that on Vitess Docker images, `pt-online-schema-change` and dependencies _are_ pre-installed.

#### Load

- `pt-online-schema-change` uses triggers to propagate changes. This method is traditionally known to generate high load on the server. Both VReplication and `gh-ost` tail the binary logs to capture changes, and this approach is known to be more lightweight.
- When throttled, `pt-online-schema-change` still runs trigger actions, whereas both VReplication and `gh-ost` cease transfer of data (they may keep minimal bookkeeping operations).

#### Cut-over

- All strategies use an atomic cut-over based on MySQL locking. At the end of the migration, the tables are switched, and incoming queries are momentarily blocked, but not lost.
- In addition, `vitess` offers a buffering layer, that reduces the contention on the database server at cut-over time.

#### MySQL compatibility

- `vitess` strategy supports foreign keys using a custom built MySQL server, found in https://github.com/planetscale/mysql-server, and using experimental `--unsafe-allow-foreign-keys` DDL strategy flag. Otherwise `vitess` does not allow making changes to a table participating in a foreign key relationship.
  `pt-online-schema-change` partially supports foreign keys.
  `gh-ost` does not allow making changes to a table participating in a foreign key relationship.

## Vitess functionality comparison

| Strategy | Managed | Online | Trackable | Declarative | Revertible          | Recoverable | Backoff |
|----------|---------|--------|-----------|-------------|---------------------|-------------|---------|
| `vitess` | Yes     | Yes*   | Yes+      | Yes         | `CREATE,DROP,ALTER` | Yes         | Yes     |
| `gh-ost` | Yes     | Yes*   | Yes+      | Yes         | `CREATE,DROP`       | No*         | No      |
| `pt-osc` | Yes     | Yes*   | Yes       | Yes         | `CREATE,DROP`       | No*         | No      |
| `mysql`  | Yes     | MySQL* | Yes       | Yes         | No                  | No          | No      |
| `direct` | No      | MySQL* | No        | No          | No                  | No          | No      |

- **Managed**: whether Vitess schedules and operates the migration
- **Online**:
  - MySQL supports limited online (`INPLACE`) DDL as well as `INSTANT` DDL. See [support chart](https://dev.mysql.com/doc/refman/8.0/en/innodb-online-ddl-operations.html). `INSTANT` DDL is instant on both primary and replicas. `INPLACE` is non-blocking on parent but serialized on replicas, causing replication lag. Otherwise migrations are blocking on both primary and replicas.
  - `gh-ost` does not support foreign keys
  - `pt-osc` has support for foreign keys (may apply collateral blocking operations)
  - `vitess` supports foreign keys on a [patched MySQL server](https://github.com/planetscale/mysql-server/commit/bb777e3e86387571c044fb4a2beb4f8c60462ced) and with `--unsafe-allow-foreign-keys` DDL strategy flag.
- **Trackable**: able to determine migration state (`ready`, `running`, `complete` etc)
  - `vitess` and `gh-ost` strategies also makes available _progress %_ and _ETA seconds_
- **Declarative**: support `--declarative` flag
- **Revertible**: `vitess` strategy supports [revertible](../revertible-migrations/) `ALTER` statements (or `ALTER`s implied by `--declarative` migrations). All managed strategies supports revertible `CREATE` and `DROP`.
- **Recoverable**: a `vitess` migration interrupted by planned/unplanned failover, [automatically resumes](../recoverable-migrations/) work from point of interruption. `gh-ost` and `pt-osc` will not resume after failover, but Vitess will automatically retry the migration (by marking the migration as failed and by initiating a `RETRY`), exactly once for any migration.
- **Backoff**: if the final cut-over step times out due to heavy traffic or locks on the migrated table, Vitess retries it in increasing intervals up to `30min` apart, so as not to further overwhelm production traffic.