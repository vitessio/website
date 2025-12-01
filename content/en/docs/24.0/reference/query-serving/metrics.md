---
title: Query Plans Classification
description:
weight: 1
---

Vitess introduces enhanced query plan classification and new metrics to improve query execution analysis and monitoring.
These updates help users track query performance, identify costly execution plans, and optimize queries for better efficiency.

## Query Plan Classification Enhancements

Vitess now classifies query plans based on their execution strategies, allowing for more precise execution decisions.

The classifications include:
* `Local`: Queries executed locally on VTGate without involving any shard.
* `Passthrough`: Queries forwarded to single shard without having any additional processing at VTGate.
* `MultiShard`: Queries executed across multiple shards with controlled routing.
* `Lookup`: Queries using lookup vindexes to resolve keyspace IDs efficiently and route to specific shards.
* `Scatter`: Queries broadcast to all shards.
* `JoinOp`: Queries involving join operations across multiple shards, with Join on VTGate.
* `ForeignKey`: Queries handling foreign key constraints, such as cascades and validations.
* `Complex`: Queries with intricate execution logic requiring VTGate to process results, such as aggregation, ordering, or other transformations.
* `OnlineDDL`: DDLs executed though Online Schema change workflow.
* `DirectDDL`: DDLs directly executed on the shards.
* `Transaction`: Queries managing transactions, including BEGIN, COMMIT, ROLLBACK, and SAVEPOINT.
* `Topology`: Queries that involves accessing Topology Server for Get/Put.

## Query Metrics for Monitoring

The new metrics include dimensions for Query Type, Plan Type, and Tablet Type, 
providing a more granular view of query execution patterns and performance bottlenecks.

The new metrics include:

- `QueryExecutions`: Tracks queries processed at VTGate.
- `QueryRoutes`: Tracks the number of vttablets a query is routed to by VTGate.

## How to Use These Metrics for Optimization

By enabling monitoring for these metrics, users can analyze query execution patterns and optimize costly plans.
Some common optimizations include:

* Rewrite queries to include shard-aware filtering conditions.
* Adding new lookup vindexes to improve query routing efficiency.
* Leverage sharded indexes to push computation down to the MySQL instead of VTGate.
* Break down complex queries into smaller, more efficient queries executed at the MySQL level.

Users can identify unoptimized queries using the plan classification in VTGate’s /debug/query_plans endpoint and apply the necessary improvements.
By analyzing these metrics, users can fine-tune query execution, reduce latency, and improve overall performance in Vitess.

## QueryThrottler Metrics

The QueryThrottler is a VTTablet component that evaluates queries to determine if they should be throttled based on configurable throttling strategies. VTTablet exposes several metrics to monitor QueryThrottler activity.

### Available Metrics

VTTablet exposes the following metrics for monitoring QueryThrottler activity:

#### QueryThrottlerRequests

Tracks the total number of requests evaluated by the query throttler.

**Labels:**
* `strategy`: The throttling strategy being used (e.g., "MockStrategy", "Unknown")
* `workload`: The workload name from ExecuteOptions (defaults to "default" or "unknown")
* `priority`: The query priority value (0-100, defaults to 100)

#### QueryThrottlerThrottled

Tracks the number of requests that were throttled by the query throttler.

**Labels:**
* `strategy`: The throttling strategy being used
* `workload`: The workload name from ExecuteOptions
* `priority`: The query priority value (0-100)
* `metric_name`: Name of the metric that triggered throttling (e.g., "cpu", "memory")
* `metric_value`: The value of the metric that triggered throttling
* `dry_run`: Whether the throttler is in dry-run mode (true/false). In dry-run mode, throttling decisions are logged but queries are not throttled.

#### QueryThrottlerTotalLatencyNs

Measures the total latency of the QueryThrottler.Throttle function call in nanoseconds, from entry to exit.

**Labels:**
* `strategy`: The throttling strategy being used
* `workload`: The workload name from ExecuteOptions
* `priority`: The query priority value (0-100)

#### QueryThrottlerEvaluateLatencyNs

Measures the latency of the strategy evaluation phase in nanoseconds, from when the Throttle function begins to when the Evaluate method completes.

**Labels:**
* `strategy`: The throttling strategy being used
* `workload`: The workload name from ExecuteOptions
* `priority`: The query priority value (0-100)

### Using QueryThrottler Metrics

You can use these metrics to:
* Monitor queries being evaluated for throttling
* Track throttling rates by strategy, workload, and priority
* Identify which metrics are triggering throttling decisions
* Measure the performance overhead of throttling evaluation
* Verify dry-run mode behavior before enabling throttling

For example, you can use these metrics to determine if a particular workload or query priority is being throttled more frequently, or to measure the latency impact of throttling evaluation on query execution.
