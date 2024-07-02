---
title: Concurrent migration execution
weight: 15
aliases: ['/docs/user-guides/schema-changes/concurrent-migrations/']
---

By default, Vitess schedules all migrations to run sequentially. Only a single migration is expected to run at any given time. However, there are cases for concurrent execution of migrations, and the user may request concurrent execution via `--allow-concurrent` flag in `ddl_strategy`.

## Why not run concurrent migrations by default

At the heart of schema migration management we are interested in `ALTER` DDLs that run for long periods of time. These will copy large amounts of data, perform many reads and writes, and overall affect the production server. They use built-in throttling mechanism to prevent harming production. The migration essentially competes with production traffic over resources.

Generally speaking, running multiple such migrations concurrently increases resource competition substantially, and yields with overall higher wall clock migrations runtime compared with sequential execution. However, this depends on the _phases_ of the running migrations, as explained next.

## Phases of a Vitess migration

A `vitess` `ALTER TABLE` migration runs through several phases, and the two notable ones are:

- The copy phase
- The tailing phase

While the two interleave to some extent, it is illustrative to think of a migration as first copying the already existing rows of a table into the shadow table, then proceeding to tail the changelog (the binary logs) and apply events onto the shadow table.

The copy phase is generally a heavyweight operation, as it incurs a massive copy of data in a greedy (though throttled) approach. The tailing phase could be intensive or relaxed, depending on the incoming production traffic (`INSERT`, `DELETE`, `UPDATE`) to the migrated table.

Running two concurrent copy phases is, generally speaking, a very heavyweight operation and the two tasks interfere with each other. However, running two or more concurrent tailing phases could be lightweight, depending on incoming traffic.

## Types of migrations that may run concurrnetly

There are valid, even essential cases to running multiple migrations concurrently. Vitess supports the following scenarios:

- Even though a long running `ALTER` may be running, a `CREATE` or `DROP` can be issued concurrently, with little to no effect on the migration and without competing over resources.
- There can be an urgent need to [revert a migration](../revertible-migrations). Vitess can allow reverting a migration (or even multiple migrations) even as some other unrelated migration is in process.
- Two `vitess` migrations could run concurrently: `vitess` will make sure only a single copy-phase runs at a time, but as many (up to some limit, in the dozens) tail phases may run concurrently to each other.
  This plays well with [postponed migrations](../postponed-migrations).

## Running a concurrent migration

To run a migration concurrently, the user will add `--allow-concurrent` to the `ddl_strategy`. For example:

```sql
mysql> set @@ddl_strategy='vitess --allow-concurrent';
mysql> create table sample_table(id int primary key);
```

or, via `vtctl`:

```shell
vtctl ApplySchema -- --skip_preflight --ddl_strategy "vitess --allow-concurrent" -sql "REVERT VITESS_MIGRATION '3091ef2a_4b87_11ec_a827_0a43f95f28a3'"
```

## Restrictions and eligibility

- To be eligible for concurrent execution, `--allow-concurrent` must be supplied.
- Any `CREATE` and `DROP` DDL is eligible for concurrent execution.
- Any `REVERT` request is eligible for concurrent execution.
- There can be at most one non-concurrent (regular) migration running at any given time.
- There may be an unlimited number of concurrent migrations running at any given time, on top of potentially a single non-concurrent migration.
- But there will never be two migrations running concurrently that operate on the same table.

To clarify:

- `gh-ost` and `pt-osc` `ALTER` migrations are not eligible to run concurrently

## Scheduling notes

- Multiple migrations can be in `ready` state. The scheduler will check them one by one to see which is eligible to next run.
- Migrations will advance to `running` state one at a time, at most a few seconds apart.
- A migration can be blocked from `running` if it operates on the same table as an already running migration.
- While one or more migrations can be blocked from `running`, other migrations, even if submitted later, could start running, assuming no concurrency conflicts.
