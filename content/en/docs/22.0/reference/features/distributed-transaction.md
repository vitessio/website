---
title: Distributed Transaction
weight: 11
aliases: ['/docs/launching/twopc/','/docs/reference/two-phase-commit/','/docs/reference/distributed-transaction/']
---

# Distributed Transactions in Vitess

## Overview

A distributed transaction is an operation that spans multiple database shards while maintaining data consistency.
Vitess supports distributed transactions through a Two-Phase Commit (TwoPC) protocol,
allowing you to perform atomic updates across different shards in your database cluster.

> **Performance Note:** Using atomic distributed transactions will impact commit latency.
> We recommend designing your VSchema to minimize cross-shard updates where possible.

## Transaction Modes

Vitess supports three levels of transaction atomicity, each offering different guarantees and performance characteristics:

| Mode | Description | Use Case | Guarantees |
|------|-------------|----------|-----------|
| Single | Transactions limited to one shard | Simple CRUD operations | Full ACID |
| Multi | Can span multiple shards with best-effort commits | Bulk updates where partial success is acceptable | No atomicity |
| TwoPC | Atomic commits across multiple shards | Financial transactions, inventory updates | Atomic commits |

### When to Use TwoPC

Choose TwoPC when you need guaranteed atomic commits across shards, such as:
- Financial transactions where partial commits could lead to inconsistent balances
- Inventory systems where items must be updated together
- User transactions that modify data in multiple shards

## Understanding Isolation Level

While TwoPC guarantees atomicity (all-or-nothing commits), it does not provide isolation in the traditional ACID sense.
The Applications might observe fractured reads in a cross-shard query i.e. a query might see partial commits while a TwoPC transaction commit is in progress.

This design choice prioritizes performance for common use cases. Full ACID isolation across shards would introduce significant performance overhead.

## Configuration

### VTGate Setup

Set the default transaction mode via the `transaction_mode` flag:

```bash
# Default mode (multi-shard, best-effort)
transaction_mode=multi

# Force single-shard transactions
transaction_mode=single

# Enable TwoPC by default
transaction_mode=twopc
```

Override the default mode for specific sessions:
```sql
SET transaction_mode='twopc';
```

### VTTablet Requirements

Enable TwoPC on VTTablet with these flags:

```bash
# Enable TwoPC support
-twopc_enable

# Time in seconds before marking transaction as abandoned
-twopc_abandon_age=300  # Recommended: 5 minutes minimum
```

Transaction watcher at VTTablet sends signal to VTGate for any pending abandoned transaction for resolution.

### MySQL Prerequisites

1. **Semi-sync Replication**
- Required for atomic commit guarantees
- TwoPC transactions will roll back if semi-sync is not enabled

2. **Connection Timeout**
- Verify `wait_timeout` is set appropriately (default: 28800 seconds)
- Short timeouts risk premature connection closure during prepared transactions

## Monitoring

The user can monitor distributed transactions at a per-transaction level with `SHOW STATEMENT` and at a higher level with metrics.

When a commit failure is received from VTGate on the session, the user can issue `show warnings` statement to retrieve the Distributed transaction ID (DTID).
This DTID can be tracked to understand the state of the transaction.
The `SHOW TRANSACTION STATUS FOR <DTID>` statement can be used to get the status of the transaction.

Example:
```mysql
> show transaction status for <dtid>;
+-------------+---------+-------------------------------+-------------------+
| id          | state   | record_time                   | participants      |
+-------------+---------+-------------------------------+-------------------+
| ks:-80:4334 | PREPARE | 2024-07-06 04:05:34 +0000 UTC | ks:80-a0,ks:a0-c0 |
  +-------------+---------+-------------------------------+-------------------+
  1 row in set (0.00 sec)
```

Additional metrics have been added to monitor the distributed transactions. The alert system could be built around understanding the metrics and failures described below.

### VTGate Watchers
* **CommitModeTimings**: This is a histogram that shows the time taken to commit a transaction in different transaction modes.
* **CommitUnresolved**: This is a counter that shows the number of commits that were not concluded by VTGate after a commit decision was made.
* **QueriesRouted**: This is a counter with PlanType (Commit) as a dimension to track the number of shards involved in a transaction.

### VTTablet Watchers
* **QueryTimings**: This is a histogram that shows the time taken to perform an operation.
  It can be used to track 2PC commit operations for MM, such as **CreateTransaction**, **StartCommit**, **SetRollback**, and **Resolve**, and for RM, such as **Prepare**, **CommitPrepared**, and **RollbackPrepared**.
* **Unresolved**: This is a gauge that shows the number of unresolved transactions that have been lingering longer than the abandon age.

### Critical Failures

The following errors are not expected to happen. If they do, it means that TwoPC transactions have failed to commit atomically:

* **InternalErrors.TwopcOpen**: This counter is incremented if VTTablet is unable to open the 2PC engine. Any unresolved prepared transactions would be abandoned.
* **InternalErrors.TwopcCommit**: This is a counter that shows the number of times a prepared transaction failed to fulfill a commit request.
* **InternalErrors.TwopcPrepareRedo**: This counter shows the number of times VTTablet failed to re-prepare a previously prepared transaction.
* **InternalErrors.TwopcResurrection**: This counter is incremented to notify a failure in resurrecting prepared transactions.

### Alertable Failures

The following failures are not urgent but require investigation:

* **InternalErrors.RedoWatcherFail**: This counter is incremented if there is a failure in reading the 2PC redo state.
* **InternalErrors.TransactionWatcherFail**: This counter is incremented if there is a failure in reading the 2PC transaction state.
* **Unresolved**: This is a gauge mentioned above that should be tracked to keep a check on the number of open 2PC transactions.

### Repairs

If any of the alerts are triggered, the user may need to scan the VTGate/VTTablet logs for investigation to identify the DTID and/or VTTablet.
The user can navigate to the `VTAdmin` UI to see the list of in-flight transactions for each keyspace.

The `VTAdmin` UI has the option to display the DTID information, which can be used to manually repair the transaction.
Later, the user can force `Conclude` on the transaction to remove it from the unresolved list.
