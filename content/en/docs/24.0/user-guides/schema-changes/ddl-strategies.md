---
title: Online DDL strategies
weight: 3
aliases: ['/docs/user-guides/schema-changes/ddl-strategies/']
---

Vitess supports both managed, online schema migrations (aka Online DDL) as well as unmanaged migrations. How Vitess runs a schema migration depends on the _DDL strategy_. Vitess allows these strategies:

- `vitess` (formerly known as `online`): utilizes Vitess's built-in [VReplication](../../../reference/vreplication/vreplication/) mechanism. This is the preferred strategy in Vitess.
- `mysql`: managed by the Online DDL scheduler, but executed via normal MySQL statement. Whether it is blocking or not is up to the specific query.
- `direct`: unmanaged. The direct apply of DDL to your database. Whether it is blocking or not is up to the specific query.

{{<info>}}`gh-ost` and `pt-osc` strategies are not supported as of v22.{{</info>}}

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

### Notes on `vitess` strategy

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

- `vitess` migrations support `INSTANT` DDL where applicable. See [INSTANT DDL](../instant-ddl-migrations/). A migration that runs with `ALGORITHM=INSTANT` does not use a shadow table and is not revertible.
- `RANGE` partitioning rotation: `ADD PARTITION` and `DROP PARTITION` statements are executed directly against MySQL and not as a `vreplication` Online DDL. See [PARTITIONING notes](../instant-ddl-migrations/#partitioning-notes)

- `vitess` migrations use an atomic cut-over based on MySQL locking. At the end of the migration, the tables are switched, and incoming queries are momentarily blocked, but not lost. In addition, `vitess` offers a buffering layer, that reduces the contention on the database server at cut-over time.

- `vitess` strategy supports foreign keys using a custom built MySQL server, found in https://github.com/planetscale/mysql-server, and using experimental `--unsafe-allow-foreign-keys` DDL strategy flag. Otherwise `vitess` does not allow making changes to a table participating in a foreign key relationship.

## Strategy functionality comparison

| Strategy | Managed | Online | Trackable | Declarative | Revertible          | Recoverable | Backoff |
|----------|---------|--------|-----------|-------------|---------------------|-------------|---------|
| `vitess` | Yes     | Yes*   | Yes+      | Yes         | `CREATE,DROP,ALTER` | Yes         | Yes     |
| `mysql`  | Yes     | MySQL* | Yes       | Yes         | No                  | No          | No      |
| `direct` | No      | MySQL* | No        | No          | No                  | No          | No      |

- **Managed**: whether Vitess schedules and operates the migration
- **Online**:
  - MySQL supports limited online (`INPLACE`) DDL as well as `INSTANT` DDL. See [support chart](https://dev.mysql.com/doc/refman/8.0/en/innodb-online-ddl-operations.html). `INSTANT` DDL is instant on both primary and replicas. `INPLACE` is non-blocking on parent but serialized on replicas, causing replication lag. Otherwise migrations are blocking on both primary and replicas.
  - `vitess` supports foreign keys on a [patched MySQL server](https://github.com/planetscale/mysql-server/commit/bb777e3e86387571c044fb4a2beb4f8c60462ced) and with `--unsafe-allow-foreign-keys` DDL strategy flag.
- **Trackable**: able to determine migration state (`ready`, `running`, `complete` etc)
  - `vitess` strategy also makes available _progress %_ and _ETA seconds_
- **Declarative**: support `--declarative` flag
- **Revertible**: `vitess` strategy supports [revertible](../revertible-migrations/) `ALTER` statements (or `ALTER`s implied by `--declarative` migrations). All managed strategies supports revertible `CREATE` and `DROP`.
- **Recoverable**: a `vitess` migration interrupted by planned/unplanned failover, [automatically resumes](../recoverable-migrations/) work from point of interruption. Vitess will automatically retry the migration (by marking the migration as failed and by initiating a `RETRY`), exactly once for any migration.
- **Backoff**: if the final cut-over step times out due to heavy traffic or locks on the migrated table, Vitess retries it in increasing intervals up to `30min` apart, so as not to further overwhelm production traffic.