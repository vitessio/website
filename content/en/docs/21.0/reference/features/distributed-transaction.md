---
title: Distributed Transaction
weight: 11
aliases: ['/docs/launching/twopc/','/docs/reference/two-phase-commit/','/docs/reference/distributed-transaction/']
---

{{< info >}}
Commit is will slow when using Atomic Distributed Transaction. The maintainers of Vitess recommend that you design your VSchema so that cross-shard updates are minimal.
{{< /info >}}

Vitess **TwoPC** (2PC) allows you to perform atomic distributed commits. The feature is implemented using traditional MySQL transactions and thus inherits the same guarantees. With this addition, Vitess can be configured to support the following three levels of atomicity:

1. **Single**: At this level, only single-shard transactions are allowed. Any transaction that tries to go beyond a single shard will fail and be rolled back.
2. **Multi**: A transaction can span multiple shards. The commit guarantees are best effort, meaning partial commits are possible.
3. **TwoPC**: This is similar to **Multi** but with an atomic commit guarantee across shards.

**TwoPC** commits are more expensive than **Multi** as the system must persist the statements before starting the commit process, and later purge them after a successful commit. This is why it is a separate option instead of being always on.

## Isolation

**TwoPC** transactions guarantee atomicity: either the whole transaction commits, or it is rolled back entirely. However, they do not guarantee isolation (in the ACID sense). This means that a third party performing cross-database reads may observe partial commits while a **TwoPC** transaction is in progress.

Guaranteeing ACID isolation is highly contentious and incurs significant costs. Providing it by default would have made Vitess impractical for the most common use cases.

## Enabling TwoPC

### Configuring VTGate and/or Connection Session

The atomicity policy is controlled by the `transaction_mode` flag. The default value is `multi` and sets all transactions to multi-shard best-effort commit mode.

To enforce single-shard transactions as the default, the VTGates can be started by specifying `transaction_mode=single`.

To enable 2PC as the default, the VTGates need to be started with `transaction_mode=twopc`.

The VTGate's default `transaction_mode` can be overridden for a specific workflow in the session by modifying the session variable using `set transaction_mode=<mode>` where necessary.

```
set transaction_mode=twopc
```

### Configuring VTTablet

The following flags need to be set to enable 2PC in VTTablet:

* **twopc_enable**: This flag needs to be turned on.
* **twopc_abandon_age**: This is the time in seconds that specifies how long to wait before requesting VTGate to resolve an abandoned transaction.

With the above flags specified, every primary VTTablet also enables the transaction watcher.
If any 2PC transaction lingers for longer than `twopc_abandon_age` seconds, VTTablet sends a signal to VTGate via the health stream to resolve all abandoned transactions older than `twopc_abandon_age`.

Ideally, `twopc_abandon_age` should be substantially longer than the time it takes for a typical 2PC commit to complete (tens of seconds).

### Configuring MySQL

Validate that the `wait_timeout` (28800 seconds by default) has not been modified or has a reasonably high value. If this value is changed to be too short, MySQL could prematurely close a prepared transaction connection, causing data loss or out-of-order commits.

`Semi-sync` replication is required for 2PC to provide an atomic guarantee. If semi-sync is not enabled, the 2PC transaction will be rolled back.

## Monitoring

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
