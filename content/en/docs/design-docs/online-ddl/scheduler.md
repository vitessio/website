---
title: Online DDL Scheduler
description: How migrations are scheduled, executed and cancelled
weight: 30
---

# Overview

The DDL scheduler is a control plane that runs on a `PRIMARY` vttablet, as part of the state manager. It is responsible for identifying new migration requests, choose and excute next migration, review running migrations, cleaning up after completion, etc.

This document explain the general logic behind `onlineddl.Executor`, and in particular the scheduling aspect.

## OnlineDDL & VTTablet state manager

`onlineddl.Executor` runs on `PRIMARY` tablets. It `Open`s when a tablet turns primary, and `Close`s when the tablet changes type away from `PRIMARY`. It only operates when in open state.

## General operations

The scheduler:

- Identifies queued migrations
- Picks next migration to run
- Executed a migration
- Follows up on migration progress
- Identifies completion or failure
- Cleans up artifacts
- Identifies stale (rogue) migrations that need to be marked as failed
- Identifies migration started by another tablet
- Possibly auto-retries migrations

The executor also receives requests from the tablet's query engine/executor:

- Submit a new migration
- Cancel a migration
- Retry a migration

It also responds API endpoints:

- `/schema-migration/report-status`: called by `gh-ost` and `pt-online-schema-change` to report liveness, completion or failure.
# The scheduler

Breaking down the scheduler logic

## Migration states & transitions

A migration can be in any one of these states:

- `queued`: a migration is submitted
- `ready`: a migration is picked from the queue to run
- `running`: a migration was started. It is periodically tested to be alive.
- `complete`: a migration completed successfully
- `failed`: a migration started running and failed due to whatever reason
- `cancelled`: a _pending_ migration was cancelled

A migration is said to be _pending_ if we expect it to run and complete. Pending migrations are thos in `queued`, `ready` and `running` states.

Some possible state transitions are:

- `queued -> ready -> running -> complete`: the ideal flow where everything just works
- `queued -> ready -> running -> failed`: a migration breaks
- `queued -> cancelled`: a migration is cancelled by the user before taken out of queue
- `queued -> ready -> cancelled`: a migration is cancelled by the user before running
- `queued -> ready -> running -> failed`: a running migration is cancelled by the user and forcefully terminated, causing it to enter the `failed` state
- `queued -> ready -> running -> failed -> running`: a failed migration was _retried_
- `queued -> ... cancelled -> queued -> ready -> running`: a cancelled migration was _retried_ (irrespective of whether it was running at time of cancellation)
- `queued -> ready -> cancelled -> queued -> ready -> running -> failed -> running -> failed -> running -> completed`: a combined flow that shows we can retry multiple times

## General logic

The scheduler works by periodic sampling of known migration states. Normally there's a once per minute tick that kicks in a series of checks. You may imagine a state machine that advances once per minute. However, some steps:

- Submission of a new migration
- Migration execution start
- Migration execution completion
- Open() state
- Test suite scenario

will kick a burst of additional ticks. This is done to speed up the progress of the state machine. For example, if a new migration is submitted, there's a good chance it will be clear to execute, so an increase in ticks will start the migration within a few seconds rather than one minute later.

The scheduler only runs a single migration at a time. This could be a simple `CREATE TABLE` or a hours-long running `ALTER TABLE`. Noteworthy:

- Two parallel `ALTER TABLE` are likely to interfere with each other, competing for same resources, causing total runtime to be longer than sequential run. This is the reasoning for only running a single migration at a time.
- `CREATE TABLE` does not interfere in same fashion. Generally speaking, there shouldn't be a problem running a `CREATE TABLE` while a hours-long `ALTER TABLE` is in mid-run. The current logic still only allows one migration at a time. In the future we may change that.
- `DROP TABLE` is implemented by `RENAME TABLE`, and is therefore also a lightweight operation similarly to `CREATE TABLE`. Again, current logic still only allows one migration at a time. In the future we may change that.

## Who runs the migration

Some migrations are executed by the scheduler itself, some by a sub process, and some implicitly by vreplication. As follows:

- `CREATE TABLE` migrations are executed by the scheduler.
- `DROP TABLE` migrations are executed by the scheduler.
- `ALTER TABLE` migrations depend on `ddl_strategy`:
  - `pt-osc`: the executor runs `pt-online-schema-change` via `os.Exec`. It runs the entire flow within a single function. Thus, `pt-online-schema-change` completes within the same lifetime of the scheduler (and the tablet space in which is operates). To clarify, if the tablet goes down, then the migration is deemed lost.
  - `gh-ost`: the executor runs `pt-online-schema-change` via `os.Exec`. It runs the entire flow within a single function. Thus, `pt-online-schema-change` completes within the same lifetime of the scheduler (and the tablet space in which is operates). To clarify, if the tablet goes down, then the migration is deemed lost.
  - `online`: the scheduler configures, creates and starts a VReplication stream. From that point on, the tablet manager's VReplication logic takes ownership of the execution. The scheduler periodically checks progress. The scheduler identifies an end-of-migration scenario and finalizes the cut-over and termination of the VReplication stream. It is possible for a VReplication migration to span multiple tablets, detailed below.

## Stale migrations

The scheduler maintains a _liveness_ timestamp for running migrations:

- `gh-ost` migrations report liveness via `/schema-migration/report-status`
- `pt-osc` does not report liveness. The scheduler actively checks for liveness by looking up the `pt-online-schema-change` process.
- `online` migrations are based on VReplication, which reports last timestamp/transaction timestamp. The scheduler infers migration liveness based on these and on the stream status.

This way or another, we expect at most a (roughly) 1 minute interval between a running migration's liveness reports. When a migration is expected to be running, and does not have a _liveness_ report for `10` minutes, then it is considered _stale_.

A stale migration can happen because computers. Perhaps a `pt-osc` process went zombie. Or a `gh-ost` process was locked.

When the scheduler finds a stale migration, it:

- Considers it to be broken and removes it from internal bookkeeping of running migrations.
- Takes steps to forcefully terminate it, just in case it still happens to run:
  - For a `gh-ost` migration, it touches the panic flag file.
  - For `pt-osc`, it `kill`s the process, if any
  - For `online`, it stops and deletes the stream

## Failed tablet migrations

A specially handled scenario is where a migration runs, and the owning (primary) tablet fails.

For `gh-ost` and `pt-osc` migrations, it's impossible to resume the migration from exact point of failure. The scheduler will attempt a full retry of the migration. This means throwing away the previous migration's artifacts (ghost tables) and starting anew.

To avoid a cascading failure scenario, a migration is only auto-retried _once_. If a 2nd tablet failure takes place, it's up to the user to retry the failed migration.

## Cross tablet VReplication migrations

VReplication is more capable than `gh-ost` and `pt-osc`, since it tracks its state transactionally in the same database server as the migration/ghost table. This means a stream can automatically recover after e.g. a failover. The new `primary` has all the information in `_vt.vreplication`, `_vt.copy_state` to keep on running the stream.

The scheduler supports that. It is able to identify a stream which started with a previous tablet, and is able to take ownership of such a stream. Because VReplication will recover/resume a stream independently of the scheduler, the scheduler will then implicitly find that the stream is _running_ and be able to assert its _liveness_.

The result is that if a tablet fails mid-`online` migration, the new `primary` tablet will auto-resume migration _from point of interruption_. This happens whether it's the same table that recovers as `primary` or whether its a new tablet that is promoted as `primary`. A migration can survive multiple tablet failures. It is only limited by VReplication's capabilities.
