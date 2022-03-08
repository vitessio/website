---
title: Managed, Online Schema Changes
weight: 2
aliases: ['/docs/user-guides/managed-online-schema-changes/']
---

**Note:** `gh-ost` migrations are considered stable. `pt-osc` and `vitess` migrations are considered **EXPERIMENTAL**.

Vitess offers managed, online schema migrations (aka Online DDL), transparently to the user. Vitess Onine DDL offers:

- Non-blocking migrations
- Migrations are asyncronously auto-scheduled, queued and executed by tablets
- Migration state is trackable
- Migrations are cancellable
- Migrations are retry-able
- Lossless, [revertible migrations](../revertible-migrations/)
- Support for [declarative migrations](../declarative-migrations/)
- Support for [postponed migrations](../postponed-migrations/)
- Support for [failover agnostic migrations](../recoverable-migrations/)
- Support for [concurrent migrations](../concurrent-migrations/)
- See also [advanced usage](../advanced-usage/)

As general overview:
- User chooses a [strategy](../ddl-strategies) for online DDL (online DDL is opt in)
- User submits one or more schema change queries, using the standard MySQL `CREATE TABLE`, `ALTER TABLE` and `DROP TABLE` syntax.
- Vitess responds with a Job ID for each schema change query.
- Vitess resolves affected shards.
- A shard's `primary` tablet schedules the migration to run when possible.
- Tablets will independently run schema migrations:
  - `ALTER TABLE` statements run via `VReplication`, `gh-ost` or `pt-online-schema-change`, as per selected [strategy](../ddl-strategies)
  - `CREATE TABLE` statements run directly.
  - `DROP TABLE` statements run [safely and lazily](../../../design-docs/table-lifecycle/safe-lazy-drop-tables/).
- Vitess provides the user a mechanism to view migration status, cancel or retry migrations, based on the job ID.

## Syntax

The standard MySQL syntax for `CREATE`, `ALTER` and `DROP` is supported.

### ALTER TABLE

Use the standard MySQL `ALTER TABLE` syntax to run online DDL. Whether your schema migration runs synchronously (the default MySQL behavior) or asynchronously (aka online), is determined by `ddl_strategy`.

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

You will set either `@@ddl_strategy` session variable, or `-ddl_strategy` command line flag, to control your schema migration strategy, and specifically, to enable and configure online DDL. Details in [DDL Strategies](../ddl-strategies). A quick overview:

- The value `"direct"`, means not an online DDL. The empty value (`""`) is also interpreted as `direct`. A query is immediately pushed and applied on backend servers. This is the default strategy.
- The value `"vitess"` instructs Vitess to run an `ALTER TABLE` online DDL via `VReplication`.
- The value `"gh-ost"` instructs Vitess to run an `ALTER TABLE` online DDL via `gh-ost`.
- The value `"pt-osc"` instructs Vitess to run an `ALTER TABLE` online DDL via `pt-online-schema-change`.
- You may specify arguments for your tool of choice, e.g. `"gh-ost --max-load Threads_running=200"`. Details follow.

`CREATE` and `DROP` statements run in the same way for `"vitess"`, `"gh-ost"` and `"pt-osc"` strategies, and we consider them all to be _online_.

See also [ddl_strategy flags](../ddl-strategy-flags).

## Running, tracking and controlling Online DDL

Vitess provides two interfaces to interacting with Online DDL:

- SQL commands, via `VTGate`
- Command line interface, via `vtctl`

Supported interactions are:

- [Running migrations](../audit-and-control/#running-migrations) (submitting Online DDL requests)
- [Tracking migrations](../audit-and-control/#tracking-migrations)
- [Cancelling a migration](../audit-and-control/#cancelling-a-migration)
- [Cancelling all pending migrations](../audit-and-control/#cancelling-all-keyspace-migrations)
- [Retrying a migration](../audit-and-control/#retrying-a-migration)
- [Reverting a migration](../audit-and-control/#reverting-a-migration)

See [Audit and Control](../audit-and-control/) for a detailed breakdown. As quick examples:

#### Executing an Online DDL via VTGate/SQL

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

#### Executing an Online DDL via vtctl/ApplySchema

```shell
$ vtctlclient ApplySchema -skip_preflight -ddl_strategy "vitess" -sql "ALTER TABLE demo MODIFY id bigint UNSIGNED" commerce
a2994c92_f1d4_11ea_afa3_f875a4d24e90
```
You my run multiple migrations withing the same `ApplySchema` command:
```shell
$ vtctlclient ApplySchema -skip_preflight -ddl_strategy "vitess" -sql "ALTER TABLE demo MODIFY id bigint UNSIGNED; CREATE TABLE sample (id int PRIMARY KEY); DROP TABLE another;" commerce
3091ef2a_4b87_11ec_a827_0a43f95f28a3
```

`ApplySchema` accepts the following flags:

- `-ddl_strategy`: by default migrations run directly via MySQL standard DDL. This flag must be aupplied to indicate an online strategy. See also [DDL strategies](../ddl-strategies) and [ddl_strategy flags](../ddl-strategy-flags).
- `-migration_context <unique-value>`: all migrations in a `ApplySchema` command are logically grouped via a unique _context_. A unique value will be supplied automatically. The user may choose to supply their own value, and it's their responsibility to provide with a unique value. Any string format is accepted.
  The context can then be used to search for migrations, via `SHOW VITESS_MIGRATIONS LIKE 'the-context'`. It is visible in `SHOW VITESS_MIGRATIONS ...` output as the `migration_context` column.
- `-skip_preflight`: skip an internal Vitess schema validation. When running an online DDL it's recommended to add `-skip_preflight`. In future Vitess versions this flag may be removed or default to `true`.

## Migration flow and states

A migration can be in any one of these states:

- `queued`: a migration is submitted
- `ready`: a migration is picked from the queue to run
- `running`: a migration was started. It is periodically tested to be making progress.
- `complete`: a migration completed successfully
- `failed`: a migration started running and failed due to whatever reason
- `cancelled`: a _pending_ migration was cancelled

A migration is said to be _pending_ if we expect it to run and complete. Pending migrations are those in `queued`, `ready` and `running` states.

For more about internals of the scheduler and how migration states are controlled, see [Online DDL Scheduler](../../../design-docs/online-ddl/scheduler)

## Configuration

- `-retain_online_ddl_tables`: (`vttablet`) determines how long vttablet should keep an old migrated table before purging it. Type: duration. Default: 24 hours.

  Example: `vttablet -retain_online_ddl_tables 48h`

- `-migration_check_interval`: (`vttablet`) interval between checks for submitted migrations. Type: duration. Default: 1 hour. 

  Example: `vttablet -migration_check_interval 30s`

- `-enable_online_ddl`: (`vtgate`) whether Online DDL operations are at all possible through `VTGate`. Type: boolean. Default: `true`

  Example: `vtgate -enable_online_ddl=false` to disable access to Online DDL via `VTGate`.
 
## Auto resume after failure

VReplication based migrations (`ddl_strategy="vitess"`) are [failover agnostic](../recoverable-migrations/). They automatically resume after either planned promotion ([PlannedReparentShard](../../configuration-advanced/reparenting/#plannedreparentshard-planned-reparenting)), emergency promotion ([EmergencyReparentShard](../../configuration-advanced/reparenting/#emergencyreparentshard-emergency-reparenting)) or completely external reparenting.

Once the new primary is in place and turns active, it auto-resumes the VReplication stream. The online DDL scheduler assumes ownership of the stream and follows it to completion.

The new primary must be available within `10 minutes`, or else the migration is considered to be stale and is aborted.

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

All three strategies: `vitess`, `gh-ost` and `pt-osc` utilize the tablet throttler, which is a cooperative throttler service based on replication lag. The tablet throttler automatically detects topology `REPLICA` tablets and adapts to changes in the topology. See [Tablet throttler](../../../reference/features/tablet-throttler/).

- `vitess` strategy uses the throttler by the fact VReplication natively uses the throttler on both source and target ends (for both reads and writes)
- `gh-ost` uses the throttler via `--throttle-http`, which is automatically provided by Vitess
- `pt-osc` uses the throttler by replication lag plugin, automatically injected by Vitess.

**NOTE** that at this time (and subject to change) the tablet throttler is disabled by default. Enable it with `vttablet`'s `-enable-lag-throttler` flag. If the tablet throttler is disabled, schema migrations will not throttle on replication lag.

## Table cleanup

All `ALTER` strategies leave artifacts behind. Whether successful or failed, either the original table or the _ghost_ table is left still populated at the end of the migration. Vitess explicitly makes sure the tables are not dropped at the end of the migration. This is for two reasons:

- Make the table/data still available for a while, and
- in MySQL pre `8.0.23`, a `DROP TABLE` operation can be dangerous in production as it commonly locks the buffer pool for a substantial period.

The tables are kept for 24 hours after migration completion. Vitess automatically cleans up those tables as soon as a migration completes (either successful or failed). You will normally not need to do anything.

Artifact tables are identifiable via `artifacts` column in a `SHOW VITESS_MIGRATION ...` command. You should generally not touch these tables. It's possible to `DROP` those tables with `direct` DDL strategy. Note that dropping tables in production can be risky and lock down your database for a substantial period of time. Dropping artifact tables also makes the migrations impossible to [revert](../revertible-migrations/).

