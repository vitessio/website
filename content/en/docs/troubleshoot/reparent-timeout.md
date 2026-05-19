---
title: Reparenting timeout during DemotePrimary
description: Debug PlannedReparentShard timeouts when enabling super_read_only
weight: 6
---

## Reparenting timeout during DemotePrimary

During `PlannedReparentShard`, Vitess demotes the current primary by enabling `super_read_only` mode on MySQL. This can stall if MySQL is waiting for transactions or locks to clear. When this happens, VTTablet automatically logs diagnostic information to help you find the root cause.

### Recognizing the problem

If `PlannedReparentShard` fails with a `DeadlineExceeded` error and VTTablet logs show:

```
timed out or canceled while enabling super_read_only during DemotePrimary, dumping MySQL diagnostics
```

Vitess detected a stall while setting `super_read_only` and is dumping diagnostic data.

### Understanding the diagnostic output

VTTablet logs several MySQL queries to help identify what blocked the operation:

**Active MySQL sessions**

Shows all non-sleeping connections from `information_schema.processlist`. Look for long-running queries or transactions holding locks.

**Read-only settings**

Reports the current values of `@@global.read_only` and `@@global.super_read_only`. Check whether the setting change was partially applied.

**Semi-sync counters**

Displays replication semi-sync status from `performance_schema.global_status`. High wait counter values may indicate replicas are slow to acknowledge writes.

**Active InnoDB transactions**

Lists transactions from `information_schema.innodb_trx` ordered by start time. Long-running transactions prevent `super_read_only` from being enabled.

**InnoDB row lock waits**

Shows blocking and waiting transactions from `performance_schema.data_lock_waits`. Check if transactions are stuck waiting for row locks held by other transactions.

**Pending metadata locks**

Reports pending metadata locks from `performance_schema.metadata_locks`. DDL operations or schema changes can hold metadata locks that block the read-only transition.

### Common causes and resolutions

| Cause | What to look for | Resolution |
|-------|------------------|------------|
| Long-running transaction | Active InnoDB transaction with old `trx_started` time | Identify the application, wait for completion, or terminate the connection |
| DDL operation | Pending metadata lock with `ALTER TABLE` or similar in `processlist_info` | Wait for DDL to complete before reparenting |
| Row lock contention | Entries in InnoDB row lock waits | Resolve the blocking transaction |
| Slow replica acknowledgment | High semi-sync wait counters | Check replica health and network connectivity |

### Example diagnostic output

```
2026-05-19 15:56:09.899 UTC ERR tabletmanager/rpc_replication.go:724 timed out or canceled while enabling super_read_only during DemotePrimary, dumping MySQL diagnostics error="context canceled"
2026-05-19 15:56:09.901 UTC INF tabletmanager/diagnostics.go:209 active MySQL sessions row="map[command:Query db: host:localhost id:51 info:select sleep(:redacted1 /* INT64 */) from dual state:User sleep time:21 user:root]" row_index=2 row_count=6
```

In this example, a `SELECT SLEEP()` query running for 21 seconds was preventing the `super_read_only` change.

### Preventing reparent timeouts

To reduce the likelihood of timeouts during planned reparenting:

- Avoid running long transactions or DDL during maintenance windows
- Use the `--wait-replicas-timeout` flag with `PlannedReparentShard` to allow more time if needed
- Enable [query buffering](../25.0/reference/features/vtgate-buffering/) to pause incoming queries during reparenting
- Monitor and limit long-running transactions in your application

### Related documentation

- [Reparenting](../25.0/user-guides/configuration-advanced/reparenting/)
- [VTGate buffering](../25.0/reference/features/vtgate-buffering/)
- [PlannedReparentShard command](../25.0/reference/programs/vtctldclient/vtctldclient_PlannedReparentShard/)
