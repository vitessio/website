---
title: Query Plans Classification
description:
weight: 10
---

Vitess introduces enhanced query plan classification and new metrics to improve query execution analysis and monitoring. 
These updates help users track query performance, identify costly execution plans, and optimize queries for better efficiency.

## Query Plan Classification Enhancements

Vitess now classifies query plans based on their execution strategies, allowing for more precise execution decisions.

The classifications include:
* `PlanLocal`: Queries executed locally on VTGate without involving any shard.
* `PlanPassthrough`: Queries forwarded to single shard without having any additional processing at VTGate.
* `PlanMultiShard`: Queries executed across multiple shards with controlled routing.
* `PlanLookup`: Queries using lookup vindexes to resolve keyspace IDs efficiently and route to specific shards.
* `PlanScatter`: Queries broadcast to all shards.
* `PlanJoinOp`: Queries involving join operations across multiple shards, with Join on VTGate.
* `PlanForeignKey`: Queries handling foreign key constraints, such as cascades and validations.
* `PlanComplex`: Queries with intricate execution logic requiring VTGate to process results, such as aggregation, ordering, or other transformations.
* `PlanOnlineDDL`: DDLs executed though Online Schema change workflow.
* `PlanDirectDDL`: DDLs directly executed on the shards.
* `PlanTransaction`: Queries managing transactions, including BEGIN, COMMIT, ROLLBACK, and SAVEPOINT.

## Query Metrics for Monitoring

The new metrics added have dimensions on `Query Type`, `Plan Type`, and `Tablet Type`. 
This provides a more granular view of query execution patterns and performance bottlenecks. 

The new metrics include:

- `QueryProcessed`: Tracks queries received at VTGate.
- `QueryRouted`: Tracks queries routed by VTGate to how many shards.

## How to Use These Metrics for Optimization

By enabling monitoring for these metrics, users can analyze query execution patterns and optimize costly plans.
Some of the common optimization include:
* Rewrite queries to include shard-aware filtering conditions.
* Adding new lookup vindexes to improve query routing efficiency.
* Leverage sharded indexes to push computation down to the database instead of VTGate.
* Break down complex queries into smaller, more efficient queries executed at the database level.

Users can identify unoptimized queries using the plan classification in VTGate’s /debug/query_plans endpoint and apply the necessary improvements. 
By analyzing these metrics, users can fine-tune query execution, reduce latency, and improve overall performance in Vitess.
