---
author: 'Vitess Maintainer Team'
date: 2024-03-06
slug: '2024-03-06-announcing-vitess-19'
tags: ['release','Vitess','MySQL','kubernetes','operator','sharding', 'Orchestration', 'Failover', 'High-Availability']
title: 'Announcing Vitess 19'
description: "Vitess 19 is now Generally Available"
---


## Announcing Vitess 19

We're thrilled to announce the release of Vitess 19, our latest version packed with enhancements aimed at improving scalability, performance, and usability of your database systems. With this release, we continue our commitment to providing a powerful, scalable, and reliable database clustering solution for MySQL.


## What's New in Vitess 19



* **Dropping Support for MySQL 5.7**: As Oracle has marked MySQL 5.7 end of life in October 2023, we're also moving forward by dropping support for MySQL 5.7. We advise users to upgrade to MySQL 8.0 while on Vitess 18 before making the jump to Vitess 19. However, Vitess 19 will still support importing from MySQL 5.7.
* **Deprecations**: We're cleaning house to streamline our offerings and improve maintainability. This includes deprecating several VTTablet flags, mysql specific tags of the Docker image `vitess/lite`, and changes to the `EXPLAIN` statement format.
* **Breaking Changes**: Notably, `ExecuteFetchAsDBA` now rejects multi-statement SQL, enforcing stricter security and stability practices.
* **New Metrics**: We're introducing new metrics for stream consolidations and adding the build version to `/debug/vars` to provide deeper insights and traceability.
* **Enhanced Query Compatibility**: This release brings support for multi-table delete operations, a new `SHOW VSCHEMA KEYSPACES` query, and several other SQL syntax enhancements that broaden Vitess's compatibility with MySQL.
* **Apply VSchema Enhancements**: We've added a `--strict` sub-flag and corresponding gRPC field to the `ApplyVSchema` command, ensuring that only known parameters are used in Vindexes, enhancing error checking and config validation.
* **Tablet Throttler**: Throttlers now communicate via gRPC only. HTTP communication is no longer used. This closes a possible vulnerability vector. 
* **Online DDL**: Support backoff for cut-over attempts in face of locking. Support forced cut-over.
* **Incremental Backup**: Support backup names and empty backups.
* **Table lifecycle**: Quicker cleanup flow.
* **Performance improvements**: Including a new connection pool for the Tablets, faster hashing in sharded Vitess clusters and faster aggregations in the Gates.


## Dive Deeper

Let's take a closer look at some of the key features.


### Query Compatibility Enhancements

Vitess 19 introduces several SQL syntax improvements and compatibility features, including:



* Support for `AVG()` aggregation function on sharded keyspaces, utilizing a combination of `SUM` and `COUNT`.
* Non-recursive Common Table Expressions (CTEs) support, allowing for more complex query constructions.


### Tablet throttler

Inter-throttler communication is now solely based on gRPC. HTTP communication is no longer supported.


### Online DDL

Vitess migration cut-over now uses back-off in face of table locks. If unable to cut-over, next attempts take place in increasing intervals. This reduces the impact on an already overloaded production system.

Online DDL also supports forced cut-over, at either predetermined timeout or on demand. Forced cut-over prioritizes the cut-over completion over production traffic, and terminates queries and transactions that conflict with the cut-over.

See [https://github.com/vitessio/vitess/pull/14546](https://github.com/vitessio/vitess/pull/14546).


### Incremental backup

The flag `Backup|BackupShard –incremental-from-pos` accepts a backup name as the backup starting point.

An empty incremental backup is now allowed, and the `Backup|BackupShard` command returns with success error code, although no backup manifest or other artifacts are created.


### Table Lifecycle

The table GC mechanism is now more responsive to tables that need to be garbage collected, and is able to observe operations that generate GC tables. For example, it can capture the result of an `ALTER VITESS_MIGRATION … CLEANUP` command and move the table through the relevant stages within seconds rather than taking several minutes or hours.


### Breaking Change: `ExecuteFetchAsDBA`

The command `ExecuteFetchAsDBA` now rejects multi-statement input. Previously, the results of multi-statement input were implicitly allowed, but resulted in undefined and undesired behavior: errors were only reported for the first statement, and silently dropped for successive statements. The connection was left in an undefined state and could leak results to next users of the connection pool. Schema tracker would not be notified of changes until the connection was closed. We will introduce formal multi-statement support in a future version.

### Performance Improvements

Following the trend over the past 3 years, this new Vitess release is faster than the previous one in _all_ the benchmarks we track in [Arewefastyet](https://benchmark.vitess.io/status). We've fixed several performance regressions from Vitess 18 and introduced significant performance improvements.

#### New connection pool

The connection pool for MySQL connections in the Tablets has been rewritten from scratch. The new pool is architected over several lock-free stacks and provides significantly lower query latencies, lower and more fair wait times and more efficient usage for idle connections. This is particularly noticeable in Vitess clusters with external tablets (i.e. clusters where the Tablet and the MySQL instance are deployed in different hosts) and busy Vitess clusters with many point queries.

#### Faster hashing in sharded Vitess clusters

The VIndex hasher for textual columns was previously implemented using the `x/text/collate` package, which allocates a linear amount of memory based on the length of the column being hashed. We've replaced it with a custom, backwards-compatible implementation, which is both faster and uses a constant amount of memory. This is a very significant performance improvement for sharded tables that use a large textual columns as a sharding key.

#### Faster comparisons in cross-shard aggregations

The performance of cross-shard aggregations that use `ORDER` or `GROUP BY` qualifiers has been greatly improved by introducing Tiny Weights. The query executor in the VTGates now tags all the SQL values from the upstream shards with a compressed form of their weight string, allowing constant-time comparisons while performing aggregations.

### A Call to the Community

We're excited to see how you'll use Vitess 19 to scale your database systems. As always, we're eager to hear your feedback and experiences. Join us on our [GitHub](https://github.com/vitessio/vitess) or [Slack channel](http://vitess.io/slack) to share your stories, ask questions, and connect with the Vitess community.


### Getting Started

Upgrading to Vitess 19 is straightforward, but we recommend reviewing the [detailed release notes](https://github.com/vitessio/vitess/blob/main/changelog/19.0/19.0.0/release_notes.md) for a smooth transition. Check out our [documentation](https://vitess.io/docs/) for comprehensive guides and tips.

Thank you for your continued support and contributions to the Vitess project. Here's to making database scaling even easier and more efficient with Vitess 19!


---

_The Vitess Team_
