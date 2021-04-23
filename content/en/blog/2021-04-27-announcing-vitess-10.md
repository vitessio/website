---
author: 'Alkin Tezuysal'
date: 2021-04-27
slug: '2020-04-27-announcing-vitess-10'
tags: ['release','Vitess','MySQL','kubernetes','operator','cloud','GKE','sharding']
title: 'Announcing Vitess 10'
description: 'We are pleased to announce the general availability of Vitess 10'
---
On behalf of the Vitess maintainers, I am pleased to announce the general availability of [Vitess 10](https://github.com/vitessio/vitess/releases/tag/v10.0.0).

## Major Themes

In this release, Vitess Maintainers have continued to focus on compatibility. It is still the most critical component of Vitess being part of the MySQL ecosystem. We have also started working on benchmarking and performance optimizations. These improvements have given us a clear vision of which areas of Vitess can be improved in terms of performance. 
 
Please take a moment to review the [Release Notes](https://github.com/vitessio/vitess/blob/master/doc/releasenotes/10_0_0_release_notes.md). Please read them carefully and report any issues via [GitHub](https://github.com/vitessio/vitess/issues).


### Compatibility (MySQL, frameworks)

It’s now been a little over a year since we started spending serious time making sure that Vitess can be a drop-in replacement for MySQL. We’ve done work on every level of Vitess - from what the TCP packets look like to parsing and query planning.

Since the beginning of this year, we have made a push to create automated tests running a popular database framework. During testing, we have found and fixed various issues that would have stopped most users from being able to use Vitess with this framework.

With the release of V10.0, we can proudly say that Vitess (unsharded)  passes all automated end-to-end tests of the Ruby on Rails framework.

Now, even if Rails isn’t what you use, the improvements might still benefit you. There is a large overlap between frameworks in terms of what type of queries are issued and which expectations they have on results coming back.

Rails is just the beginning - we’ll continue adding tests for more frameworks, which should flush out discrepancies between MySQL and Vitess that we need to address.
We’ll continue with this work, making sure that Vitess can be used as a database wherever you can use MySQL.

### Migration
Freno-style throttling has been added to VReplication workflows. Both source and target tablets can be throttled based on replication lag of the corresponding shards.
New commands Mount and Migrate let you import data from another Vitess cluster. 
The release also includes Improved metrics, bug-fixes and fine-tuning of the VReplication V2  user commands.

### Schema Management
Online DDL continues to evolve on top of version 9. New and noteworthy:
* Improved SQL syntax:
  * SHOW VITESS_MIGRATIONS
  * SHOW VITESS MIGRATIONS LIKE ‘<uuid>’
  * SHOW VITESS MIGRATIONS LIKE ‘<migration-context>’
  * SHOW VITESS MIGRATIONS LIKE ‘<state>’
  * ALTER VITESS_MIGRATION ‘<uuid>’ CANCEL
  * ALTER VITESS_MIGRATION ‘<uuid>’ RETRY
  * REVERT VITESS_MIGRATION ‘<uuid>’ (see following)
https://vitess.io/docs/user-guides/schema-changes/audit-and-control/
* Introducing VReplication-based migrations, via @@ddl_strategy=’online’
VReplication is the underlying mechanism behind resharding, materialed news, MoveTables, and more. It is now capable of running schema migrations.
  * https://vitess.io/docs/user-guides/schema-changes/ddl-strategies/#onlinevreplication
* Revertible Online DDL: lossless, online revert for completed migrations
  * Supported via REVERT VITESS_MIGRATION ‘<uuid>’ statement
  * Supported for CREATE TABLE statements in all online DDL strategies (reverting a CREATE TABLE hides away the table)
  * Supported for DROP TABLE statements in all online DDL strategies (reverting a DROP TABLE reinstates the table with all data)
  * Supported for ALTER TABLE in online (VReplication) strategy. Reverting an ALTER TABLE is lossless, and retains changes made to the table after migration completion. The operation is quick and only requires catching up on the binlog events since migration completion.
  * https://vitess.io/docs/user-guides/schema-changes/revertible-migrations/
* Declarative schema changes
  * Via @@ddl_strategy=’online|gh-ost|pt-osc -declarative’
  * Per-table, either supply CREATE TABLE or DROP TABLE statement but never ALTER TABLE
  * Vitess automatically decides whether the existing schema matches the required schema, or works towards matching it.
  * Declarative schema changes are idempotent
  * https://vitess.io/docs/user-guides/schema-changes/declarative-migrations/

## Performance Optimizations
This new release of Vitess has had a particular focus on performance optimization. Some highlights include:

* We have added a new and more performant Cache Implementation for query plans. The new cache uses a LFU eviction algorithm to make it more resilient against pollution, so it behaves particularly better in pathological cases (such as bulk inserts into an active database) while having faster response times and better hit rates during normal operation.
* The performance of the Vitess SQL Parser has been greatly improved, both in parsing speed and in reduction of memory allocations. This will result in less CPU usage for vtgate instances, faster query times and less GC churn. Third party applications which depend on Vitess’ parser will also receive these benefits if they upgrade to our newest version -- the external API remains mostly unchanged.
* Many of the AST operations that Vitess performs on SQL syntax trees have been redesigned so they do not allocate memory unless it’s strictly necessary. This will result in a noticeable decrease in memory usage for vtgate processes, particularly in busy Vitess clusters.
* Most of the improvements are in CPU and memory usage of vtgate. We are working on benchmarking the impact on latency and throughput and will publish results when they are available.

## User Interface 

Vitess 10.0 introduces an experimental multi-cluster admin API and web UI, called VTAdmin. Deploying the vtadmin-api and vtadmin-web components is completely opt-in. If you're interested in trying it out and providing early feedback, come find us in #feat-vtadmin in the Vitess slack. Note that VTAdmin relies on the new VtctldServer API, so you must be running the new grpc-vtctld service on your vtctlds in order to use it.

## Benchmarking 
To ensure that Vitess delivers high performance to its users, we have improved our benchmarking and performance monitoring techniques ever since Vitess 9.0. The project arewefastyet is at the core of these techniques and is still under development at the moment, its goal is to measure and observe Vitess’s performance in an automatic manner.

There is a shortlist of incompatible changes in this release. We encourage you to spend a moment reading the release notes and see if any of these will affect you.

Please download [Vitess 10](https://github.com/vitessio/vitess/releases/tag/v10.0.0) and try it out!
