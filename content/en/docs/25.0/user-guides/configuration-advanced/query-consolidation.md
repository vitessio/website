---
title: Query Consolidation
weight: 50
aliases: []
---
Query consolidation is a VTTablet feature meant to protect your database from an overload caused by a spike in QPS for a specific query.

Without this feature enabled such spikes can completely overwhelm the database. With this feature enabled the following will occur: when a vttablet receives a query, if an identical query is already in the process of being executed, the query will then wait.
As soon as the first query returns from the underlying database, the result is sent to all callers that have been waiting.

**Note**: an identical query is one that is exactly the same, including literals and bind variables.

Flags:

* `--enable-consolidator`: Defaults to true.
* `--enable-consolidator-replicas`: Only enable query consolidation on non-primary tablets.
* `--consolidator-query-waiter-cap`: The maximum number of clients allowed to wait on the consolidator for each query. No limit by default.
* `--consolidator-cache-proto3-rows`: Cache proto3 row encoding during query consolidation to reduce memory usage. Defaults to false.

## Waiter Cap Behavior

The `--consolidator-query-waiter-cap` flag limits the number of clients that can wait for the result of an already-executing identical query. This helps prevent resource exhaustion when many duplicate queries arrive simultaneously.

When the waiter cap is reached for a particular query, additional queries will not wait for the consolidated result. Instead, they fall back to independent execution. Each query executes separately and returns its own result.

For example, if you set `--consolidator-query-waiter-cap=10` and 15 identical queries arrive while the first query is still executing:

* The first query executes normally
* Queries 2-11 wait for the result (10 waiters)
* Queries 12-15 exceed the cap and execute independently

This fallback mechanism ensures all queries return correct results, even under heavy load. The waiter cap still provides resource protection by limiting how many queries can be waiting at once.

## Memory Optimization

When multiple clients consolidate on the same query, the consolidator shares a single result pointer across all waiters. However, each waiter independently encodes the result into proto3 format for transmission, creating redundant memory allocations. For a 100MB result with 50 consolidated waiters, this produces approximately 5GB of transient allocations from row encoding alone.

The `--consolidator-cache-proto3-rows` flag caches the proto3 row encoding. When enabled, the consolidator leader computes the encoding once and reuses it for all waiters instead of each waiter encoding independently.

This optimization defaults to false to allow safe rollout. Enable it for workloads with high consolidation fan-out to reduce memory pressure.

## Consistency

It is important to note that in some cases read-after-write consistency can be lost.

For example, if user1 issues a read query and user2 issues a write, that changes the result that the first read query would get, then user2 issues an identical read while user1's read is still executing.

In this case the consolidator will kick in and user2 will get the result of user1's query thereby losing read-after-write consistency.

If the application is sensitive to this behavior then you can specify that consolidation should be disabled on the primary using the following flags: `--enable-consolidator=false` and `--enable-consolidator-replicas=true`

