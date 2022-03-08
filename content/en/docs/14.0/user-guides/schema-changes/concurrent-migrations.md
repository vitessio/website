---
title: Concurrent migration execution
weight: 15
aliases: ['/docs/user-guides/schema-changes/concurrent-migrations/']
---

By default, Vitess schedules all migrations to run sequentially. Only a single migration is expected to run at any given time. However, there are cases for concurrent execution of migrations, and the user may request concurrent execution via `-allow-concurrent` flag in `ddl_startegy`.

## Why not run concurrent migrations by default

At the heart of schema migration management we are interested in `ALTER` DDLs that run for long periods of time. These will copy large amounts of data, perform many reads and writes, and overall affect the production server. They use built-in throttling mechanism to prevent harming production. The migration essentially competes with production traffic over resources.

We have found that running multiple such migrations concurrently increases resource competition substantially, and yields with overall higher wall clock migrations runtime compared with sequential execution.

## Cases for concurrent migrations, supported by Vitess

There are valid, even essential cases to running multiple migrations concurrently. Vitess supports the following scenarios:

- Even though a long running `ALTER` may be running, a `CREATE` or `DROP` can be issued concurrently, with little to no effect on the migration and without competing over resources.
- There can be an urgent need to [revert a migration](../revertible-migrations). Vitess can allow reverting a migration (or even multiple migrations) even as some other unrelated migration is in process.

## Running a concurrent migration

To run a migration concurrently, the user will add `-allow-concurrent` to the `ddl_strategy`. For example:

```sql
mysql> set @@ddl_strategy='vitess -allow-concurrent';
mysql> create table sample_table(id int primary key);
```

or, via `vtctl`:

```shell
vtctl ApplySchema -skip_preflight -ddl_strategy "vitess -allow-concurrent" -sql "REVERT VITESS_MIGRATION '3091ef2a_4b87_11ec_a827_0a43f95f28a3'"
```

## Restrictions and eligibility

- To be eligible for concurrent execution, `-allow-concurrent` must be supplied.
- Any `CREATE` and `DROP` DDL is eligible for concurrent execution.
- Any `REVERT` request is eligible for concurrent execution.
- There can be at most one non-concurrent (regular) migration running at any given time.
- There may be an unlimited number of concurrent migrations running at any given time, on top of potentially a single non-concurrent migration.
- But there will never be two migrations running concurrently that operate on the same table.

To clarify:

- `gh-ost` and `pt-osc` `ALTER` migrations are not eligible to run concurrently
- A "normal" `vitess` `ALTER` migration is not eligible to run concurrently. A `REVERT` of a `vitess` migration _is_ eligible though.

## Scheduling notes

- Multiple migrations can be in `ready` state. The scheduler will check them one by one to see which is eligible to next run.
- Migrations will advance to `running` state one at a time, at most a few seconds apart.
- A migration can be blocked from `running` if it operates on the same table as an already running migration.
- While one or more migrations can be blocked from `running`, other migrations, even if submitted later, could start running, assuming no concurrency conflicts.
