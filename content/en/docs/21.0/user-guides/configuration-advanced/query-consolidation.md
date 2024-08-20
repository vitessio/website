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

* `--enable_consolidator`: Defaults to true.
* `--enable_consolidator_replicas`: Only enable query consolidation on non-primary tablets.

## Consistency

It is important to note that in some cases read-after-write consistency can be lost.

For example, if user1 issues a read query and user2 issues a write, that changes the result that the first read query would get, then user2 issues an identical read while user1's read is still executing.

In this case the consolidator will kick in and user2 will get the result of user1's query thereby losing read-after-write consistency.

If the application is sensitive to this behavior then you can specify that consolidation should be disabled on the primary using the following flags: `--enable_consolidator=false` and `--enable_consolidator_replicas=true`

