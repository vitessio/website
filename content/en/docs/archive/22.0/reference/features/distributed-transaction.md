---
title: Distributed Transactions
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
- Other user transactions that modify data across multiple shards or keyspaces that must remain consistent.

## Understanding Isolation Levels

While TwoPC guarantees atomicity (all-or-nothing commits), it does not provide isolation in the traditional ACID sense.
Applications might observe fractured reads in a cross-shard query i.e. a query might see partial commits while a TwoPC transaction commit is in progress.

The current implementation prioritizes performance for common use cases. Full ACID isolation across shards would introduce significant performance overhead.

## Configuration

### VTGate

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

### VTTablet

Enable TwoPC on VTTablet with these flags:

```bash
# Enable TwoPC support
--twopc_enable
# Time in seconds before marking transaction as abandoned
# Recommended: 5-10 minutes
--twopc_abandon_age=300
```

Transaction watcher at VTTablet uses `twopc_abandon_age` to count the pending abandoned transaction and sends signal to VTGate for resolution.

### MySQL Prerequisites

1. **Semi-sync Replication**
- Required for atomic commit guarantees
- TwoPC transactions will roll back if semi-sync is not enabled

2. **Connection Timeout**
- Verify `wait_timeout` is set appropriately (default: 28800 seconds)
- Short timeouts risk premature connection closure during prepared transactions

## Monitoring

Users can monitor distributed transactions at a per-transaction level with `SHOW STATEMENT` and at a higher level with metrics.

When a commit failure is received from VTGate on the session, a `show warnings` statement can be issued to retrieve the Distributed transaction ID (DTID).
This DTID can be tracked to monitor the state of the transaction.
The `SHOW TRANSACTION STATUS FOR <DTID>` statement can be used to retrieve the status of the transaction.

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

Additional metrics have been added for monitoring the distributed transactions.

### VTGate
* **CommitModeTimings**: This is a histogram that shows the time taken to commit transactions in different transaction modes.
* **CommitUnresolved**: This is a counter that shows the number of commits that were not concluded by VTGate after a commit decision was made.
* **QueriesRouted**: This is a counter with PlanType (Commit) as a dimension to track the number of shards involved in a transaction.

### VTTablet
* **QueryTimings**: This is a histogram that shows the time taken to perform an operation.
  It can be used to track TwoPC commit operations such as **CreateTransaction**, **Prepare**, **StartCommit**, **SetRollback**, **CommitPrepared**, **RollbackPrepared** and **Resolve**.
* **Unresolved**: This is a gauge that shows the number of unresolved transactions that have been lingering longer than the abandon age.

#### Critical Failures

The following errors are not expected to happen. If they do, it means that TwoPC transactions have failed to commit atomically:

* **InternalErrors.TwopcOpen**: This is a counter that tracks the number of failures the TwoPC engine is unable to open. Any unresolved prepared transactions will remain abandoned.
* **InternalErrors.TwopcCommit**: This is a counter that tracks the number of failures to fulfill a commit request on the prepared transactions.
* **InternalErrors.TwopcPrepareRedo**: This is a counter that tracks the number of failures to re-prepare a previously prepared transaction.
* **InternalErrors.TwopcResurrection**: This is a counter that tracks the number of failures in resurrecting prepared transactions.

#### Alertable Failures

The following failures are not urgent but require investigation:

* **InternalErrors.RedoWatcherFail**: This counter is incremented if there is a failure in reading the TwoPC redo state.
* **InternalErrors.TransactionWatcherFail**: This counter is incremented if there is a failure in reading the TwoPC transaction state.

## Repairs

If any of the alerts are triggered, an administrator may need to scan the VTGate/VTTablet logs for investigation to identify the DTID and/or VTTablet.
The user can navigate to the `VTAdmin` UI to see the list of in-flight transactions for each keyspace.

`VTAdmin` can display the DTID information which can be used to manually repair the transaction.
Once that is done, the administrator can force `Conclude` on the transaction to remove it from the unresolved list.
