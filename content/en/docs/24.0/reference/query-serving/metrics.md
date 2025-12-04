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
* `Strategy`: The throttling strategy being used (e.g., "TabletThrottlerStrategy")
* `Workload`: The client application workload name from the `WORKLOAD_NAME` comment directive
* `Priority`: The query priority value (0-100) determining query throttling preference (lower = higher priority)

#### QueryThrottlerThrottled

Tracks the number of requests that were throttled by the query throttler.

**Labels:**
* `Strategy`: The throttling strategy being used
* `Workload`: The client application workload name from the `WORKLOAD_NAME` comment directive
* `Priority`: The query priority value (0-100) determining query throttling preference (lower = higher priority)
* `MetricName`: Name of the metric that triggered throttling (e.g., "cpu", "lag")
* `MetricValue`: The value of the metric that triggered throttling
* `DryRun`: Whether the throttler is in dry-run mode (true/false). In dry-run mode, throttling decisions are logged but queries are not throttled.

#### QueryThrottlerTotalLatencyNs

Measures the total latency in nanoseconds for each throttling request from entry to exit, including evaluation, metric checks, and all overhead.

**Labels:**
* `Strategy`: The throttling strategy being used
* `Workload`: The client application workload name from the `WORKLOAD_NAME` comment directive
* `Priority`: The query priority value (0-100) determining query throttling preference (lower = higher priority)

#### QueryThrottlerEvaluateLatencyNs

Measures the latency in nanoseconds of the strategy evaluation phase, specifically the time taken to make the throttling decision. 

**Labels:**
* `Strategy`: The throttling strategy being used
* `Workload`: The client application workload name from the `WORKLOAD_NAME` comment directive
* `Priority`: The query priority value (0-100) determining query throttling preference (lower = higher priority)

### Using QueryThrottler Metrics

You can use these metrics to:
* Monitor queries being evaluated for throttling
* Track throttling rates by strategy, workload, and priority
* Identify which metrics are triggering throttling decisions
* Measure the performance overhead of throttling evaluation
* Verify dry-run mode behavior before enabling throttling

For example, you can use these metrics to determine if a particular workload or query priority is being throttled more frequently, or to measure the latency impact of throttling evaluation on query execution.
