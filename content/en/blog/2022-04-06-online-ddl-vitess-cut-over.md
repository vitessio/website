---
author: 'Shlomi Noach'
date: 2022-04-06
slug: '2022-04-06-online-ddl-vitess-cut-over'
tags: ['Vitess','MySQL', 'DDL', 'schema migrations', 'operations']
title: 'Cut-over logic in vitess schema migrations'
description: 'A deep dive into the migration cut-over logic, which provides the best experience to the apps while maintaining complete data integrity'
---

Vitess supports managed, non-blocking schema migrations based on VReplication, aptly named `vitess` migrations. Vitess migrations are powerful, revertible, and failure agnostic. They take an [asynchronous approach](https://docs.planetscale.com/learn/online-schema-change-tools-comparison#synchronous-vs-asynchronous), which is more lightweight on the database server. The asynchronous approach comes with an implementation challenge: how to cut-over with minimal impact to the user/app and risk free of data loss. In this post we take a deep dive into the cut-over logic used in vitess migrations.

Vitess migration cut-over is:

- Quick
- Atomic to vitess clients
- Safe from data loss / data drift concerns

To understand better what this means, let's first review what cut-over is.

## The cut-over step

This is the most critical step in an online schema migration process, and in all implementations and tools: from [pt-online-schema-change](https://www.percona.com/doc/percona-toolkit/3.0/pt-online-schema-change.html), [fb-osc](http://bazaar.launchpad.net/~mysqlatfacebook/mysqlatfacebook/tools/annotate/head:/osc/OnlineSchemaChange.php), to [gh-ost](https://github.com/github/gh-ost) and finally [vitess](https://vitess.io/docs/user-guides/schema-changes/).
An online schema migration (aka online DDL) process creates a shadow table, populates it, brings it up to date with the original table, and then cuts-over by renaming the original table away, and the shadow table in its place.

The cut-over is a point where the two tables must be, and remain, in complete sync throughout the switch. Whichever the implementation is, this involves locks, and this impacts the users/apps.
Vitess migrations use asynchronous change propagation: they look for changes to the original table in the binary logs, then apply those changes to the shadow table. This means some latency, however small, before applying those changes to the shadow table. At any point in time the two tables may be out of sync, with the shadow table slightly lagging behind the original table.

But at cut-over, the shadow table must be brought into complete sync with the original table. How is this done?

## A brief suspense

All schema migration techniques use some form of locking at cut-over time. That locking causes queries to stall and connections to spike.

To be able to bring the shadow table up to speed with the original table, vitess runs the following generalized flow:

- Verify the migration is in appropriate state
- Prevent writes to the original table
- Mark the point in time where writes have been disabled
- Consume binary logs up to marked point in time, and apply onto shadow table
- Tables now in sync, cut-over

Exactly how vitess prevents write to the original table is the topic of the reminder of this post. It's noteworthy that the flow can fail, or timeout, in which case vitess resumes writes and tries again at a later stage.

## Preventing writes

There's a few techniques to preventing writes on the migrated table. They differ in a few ways: are the techniques safe enough? Are they revertible? What is the impact to the app?

Take `fb-osc`'s approach: it runs a two-step cut-over, where it first renames the original table away, thus creating a puncture in the database, then renaming the shadow table in its place. There is a point in time where the table just doesn't exist. To the users and apps this manifests as unexpected errors. All of a sudden a bunch of queries fail claiming there is no such table. And what if the tool crashes in between those two renames?

`gh-ost`'s approach is to lock the table via an [elaborate mechanism](https://github.com/github/gh-ost/issues/82) that ensures rollback in case of error/timeout. To the users/apps it looks atomic. Queries will block and pile up, then be released to operate on the new table. The logic relies on internal MySQL lock prioritization, and some users have shown specific scenarios where expected prioritization [can fail](https://github.com/github/gh-ost/issues/887).

Implementing vitess's cut-over, we wanted the best of all worlds. We wanted the cut-over to appear atomic to the apps, i.e. the apps should see no unexpected errors, and at worst case will block for a few seconds. We also wanted complete certainty of data integrity: that no write can possibly take place on the original table while we bring the shadow table to speed. Breakdown follows.

### 1. Buffering writes

Vitess has the advantage that traffic goes through VTGate, its MySQL compatible proxy. Normal users and apps do not communicate directly to MySQL (though as explained below, the cut-over logic also covers direct communication scenarios). Queries are normally sent to VTGate, which routes them to the appropriate shards and to the VTTablet servers on those shards. VTTablet will then run the query on MySQL.

VTTablet has the notion of ACLs (Access Control Lists). These were primarily intended to let administrators deny writes to tables.

Each query that goes through VTTablet gets a query plan. The plan includes all ACLs associated with any table referenced in the query. At execution time, VTTablet first evaluates whether ACLs permit the query to pass, and then proceeds to execute the query on MySQL and return its results.

Vitess migrations introduce a new form of ACL: time limited buffering. These are expiring rules. You may set a buffering rule onto some table, then either cancel the rule, or it eventually expires by itself.

While the rule is active, a query is buffered, or essentially just kept at bay, waiting until further notice. Either:

- the rule will be actively cancelled, meaning buffering is done, and the query proceeds to execute (assuming no other ACL has conflicts), or
- the rule will self expire, in which case the query gets rejected.

We expect cut-over total time to be a few seconds, typically two or three. When cut-over begins, vitess sets a `10s` buffering ACL on the migrated table. Thus, any new query enters buffering for up to ten seconds. If migration completes by then, great, the query unblocks and proceeds to run on the new table. If not, then the query errors.

Buffering can only allow a certain (configurable) number of queries to wait. Under heavy load the app could eventually exhaust the buffer capacity, at which time queries will error. This is why it is essential to complete the cut-over as soon as possible.

However, buffering is not a complete solution:

1. What happens to a query which was executed _just before_ cut-over, and has validated its ACLs? If we place buffering ACLs now, it's too late for that query. It proceeds to execute. How can we tell?
2. What happens if some automation runs a direct query on the MySQL server? It's not the normal vitess flow, but it can happen, and we've all been there.

### 2. Stall

As a gesture to potential pending queries, the flow stalls for an extra `100ms`. That time is very likely enough to let any queries which already passed pre-cut-over ACLs to begin executing on the MySQL server, also likely enough to let them complete executing.

This step increases the overall cut-over time for everyone, but lets remaining queries execute before introducing any locking.

The step doesn't guarantee anything, really. We have high belief that it give queries enough time to complete, but as race conditions go, a `sleep` is never an answer.

Besides, this again has no effect on any possible queries running directly on MySQL.

### 3. Puncture

Next step is to `RENAME original_table TO _somewhere_else_`. It's noteworthy that `RENAME` will wait for any pending queries to complete; thus any `UPDATE` still in progress will complete rather than fail.

But once the `RENAME` is complete, we have a puncture. The original table is no longer in place. There is just no possibility of any query modifying the original table anymore. Of course, normal app queries are not aware of the puncture: they are still buffered via ACLs.

We now mark our point in time (MySQL's `gtid_executed` value).

### 4. Complete

Vitess proceeds to read any remaining binary log entries up to marked point in time, and apply them onto the shadow table. We don't expect many of those. We only enter the cut-over process when our binary log processing is in good shape and tightly behind actual writes. We expect a second or two of final catchup time.

When the events are consumed, we know the original and shadow tables are in full sync. We now `RENAME` the shadow table in place of the original table. We have a new table in place! The puncture is amended.

Finally, we clear the buffering ACL. Buffered queries are then permitted to proceed to execute on the table - the new table - unaware that anything happened.

## Failures

While VTTablet is running, it is able to rollback the cut-over operation at any point:

- Failure before buffering begins? No problem, no harm done.
- Failure in renaming the original table away? No problem, undo ACLs and try later
- Failure in renaming the shadow table in place of the original table? No problem, rename the original table back in place, remove buffering, try again later

What happens if VTTablet's process fails while the puncture is in place, though? This is where we see the vitess framework benefit. A new VTTablet will run. Whether we failover to a new MySQL server or not, we expect there to eventually be a VTTablet process in charge. That process will run recovery steps for prematurely interrupted migrations. It will in fact resume any interrupted migration from point of interruption.

Before renaming the original table away, VTTablet audits the intended action. In case of failure, the new VTTablet processes the state of interrupted migrations and sees that audit. It then restores the original table back in place, thus rolling back the entire cut-over operation. ACLs are in-memory and so the new VTTablet does not need to remove the buffering ACL. It then adopts the migration and lets it run, and in the natural order of things attempts to cut-over when appropriate.

## Summary

By taking advantage of the vitess framework itself, vitess migrations are able to deliver a multi layered cut-over mechanism, involving ACLs as well as MySQL primitives, such that users and apps get the best experience, while still maintaining complete control over data accuracy.
