---
title: Reparenting
weight: 20
aliases: ['/docs/user-guides/reparenting/']
---

**Reparenting** is the process of changing a shard's primary tablet from one host to another or changing a replica tablet to have a different primary. Reparenting can be initiated manually or it can occur automatically in response to certain system conditions. As examples, you might reparent a shard or tablet during scheduled maintenance or [VTOrc](../../configuration-basic/vtorc) might automatically trigger reparenting when a primary tablet's MySQL dies.

This document explains the types of reparenting that Vitess supports:

* [Active reparenting](../../configuration-advanced/reparenting/#active-reparenting) occurs when Vitess manages the entire reparenting process.
* [External reparenting](../../configuration-advanced/reparenting/#external-reparenting) occurs when another tool handles the reparenting process, and Vitess just updates its topology service, replication graph, and serving graph to accurately reflect primary-replica relationships.

## MySQL requirements

### GTIDs

Vitess requires the use of global transaction identifiers ([GTIDs](https://dev.mysql.com/doc/refman/8.0/en/replication-gtids-concepts.html)) for its operations:

* Vitess uses GTIDs to initialize replication when a cluster is initialized. It depends on the GTID stream to be correct when reparenting.
* If using external reparenting, Vitess assumes that the external tool manages the replication process.

### Semi-synchronous replication

Vitess does not depend on [semi-synchronous replication](https://dev.mysql.com/doc/refman/8.0/en/replication-semisync.html) but encourages its use. Larger Vitess deployments typically do use semi-synchronous replication.

### Active Reparenting

You can use the following `vtctldclient` commands to perform reparenting operations:

* `PlannedReparentShard`
* `EmergencyReparentShard`

Both commands lock the Shard record in the global topology service. The two commands cannot run in parallel for a given shard. Nor can two invocations of the same command run in parallel for a given shard.
Both commands are dependent on the global topology service being available, and they both insert rows in the Vitess-internal `reparent_journal` table. As such, you can review your database's reparenting history by inspecting that table.

### PlannedReparentShard: Planned reparenting

The `PlannedReparentShard` command reparents a healthy shard to a new primary. It can be used to initialize the shard primary when the shard is brought up. If it is used to change the primary of an already running shard, then both the current and new primary must be up and running. If the primary for a shard is down, use `EmergencyReparentShard` instead.

This command performs the following actions when used to change the current primary:

1. Puts the current primary tablet in read-only mode.
1. Shuts down the current primary's query service, which is the part of the system that handles user SQL queries.
1. Retrieves the current primary's executed GTID position.
1. Waits for the primary-elect tablet to catch up to the current primary's GTID position
1. Promotes the primary-elect tablet as the new primary.
1. Ensures replication is functioning properly via the following steps:
    - On the primary-elect tablet, insert a row into an internal table and then update the global shard object's PrimaryAlias property.
    - In parallel on each replica, including the old primary, set the new primary as the replication source and wait for the inserted row to replicate to the replica tablets.

This command performs the following actions when used to initialize the first primary in the shard:
1. Promote the new primary that is specified.
1. Ensures replication is functioning properly via the following steps:
    - On the primary-elect tablet, insert a row into an internal table and then update the global shard object's PrimaryAlias record.
    - In parallel on each replica, set the new primary as the replication source and wait for the inserted row to replicate to the replica tablets.

The new primary (if unspecified) is chosen using the configured [Durability Policy](../../configuration-basic/durability_policy).

In order to make planned maintenance operations zero-downtime, Vitess provides the capability of [buffering]((../../../reference/features/vtgate-buffering)) queries for the duration of the reparent operation.
While this is optional, it is highly recommended. With the proper settings, buffering can handle all non-transactional queries with zero errors.
Transactions are handled differently, we cannot buffer them because transaction state is held in the backing MySQL and not in Vitess.
When we start the process of shutting down the current primary's query service, we wait for a specified grace period to allow in-flight transactions to complete.
During this time, we do not start new transactions on the current primary. Instead, we buffer the `begin` statements that would typically start a new transaction.
Once the grace period is complete, any transactions that are still in-flight are killed, and an error is returned to the client. Clients are expected to treat this error as fatal, abandon any open transactions, and start new ones for subsequent operations.

### EmergencyReparentShard: Emergency reparenting

The `EmergencyReparentShard` command is used to force a reparent to a new primary when the current primary is unavailable. The command assumes that data cannot be retrieved from the current primary because it is dead or not working properly.

As such, this command does not rely on the current primary at all to replicate data to the new primary. Instead, it makes sure that the primary-elect is the most advanced in replication among all available replicas or that the primary-elect has caught up to the most advanced one. In either case, the candidate will only be promoted once it is the most advanced replica.

**Important**: You can specify which replica you want to promote. If not specified, Vitess will choose it for you depending on the durability policy specified for the keyspace.

This command performs the following actions:

1. Determines the current replication position on all replica tablets and finds the tablet that has the most advanced replication position.
1. Chooses a primary-elect tablet based on the durability policy specified, if the user has not chosen one.
1. Waits for the primary-elect to catch up to the most advanced replica, if it isn't already the most advanced.
1. Promotes the primary-elect tablet to be the new primary. In addition to changing its tablet type to primary, the primary-elect performs any other changes that might be required for its new state.
1. Ensures replication is functioning properly via the following steps:
    - On the primary-elect tablet, insert a row in the `reparent_journal` table and then updates the `PrimaryAlias` property of the global shard object.
    - In parallel on each replica, excluding the old primary, set the new primary as the replication source and wait for the inserted row to replicate to the replica tablets.

### Metrics

Metrics are available on the `/debug/vars` pages of VTOrc and VTCtld for the reparent operations that they execute. Corresponding Prometheus-compatible metrics are available at `/metrics`.

| Metric                             | Usage                                                                                                                          |
|------------------------------------|--------------------------------------------------------------------------------------------------------------------------------|
| `planned_reparent_counts`          | Number of times PlannedReparentShard has been run. Available dimensions are keyspace, shard and the result of the operation.   |
| `emergency_reparent_counts`        | Number of times EmergencyReparentShard has been run. Available dimensions are keyspace, shard and the result of the operation. |
| `reparent_shard_operation_timings` | Timings of reparent shard operations indexed by the type of operation.                                                         |

## External Reparenting

External reparenting occurs when another tool handles the process of changing a shard's primary tablet. After that occurs, the tool needs to call the [`vtctl TabletExternallyReparented`](../../../reference/programs/vtctl/shards/#tabletexternallyreparented) command to ensure that the topology service, replication graph, and serving graph are updated accordingly.

`TabletExternallyReparented` performs the following operations:

1. Reads the Tablet from the local topology service.
2. Reads the Shard object from the global topology service.
3. If the Tablet type is not already `PRIMARY`, sets the tablet type to `PRIMARY`.
4. The Shard record is updated asynchronously (if needed) with the current primary alias.
5. Any other tablets that still have their tablet type to `PRIMARY` will demote themselves to `REPLICA`.

The `TabletExternallyReparented` command fails in the following cases:

* The global topology service is not available for locking and modification. In that case, the operation fails completely.

Active reparenting might be a dangerous practice in any system that depends on external reparents. You can disable active reparents by starting `vtctld` with the `--disable_active_reparents` flag set to true. (You cannot set the flag after `vtctld` is started.)

## Fixing Replication

A tablet can be orphaned after a reparenting if it is unavailable when the reparent operation is running but then recovers later on. Its replication will be automatically fixed by [VTOrc](../../configuration-basic/vtorc).
You can also manually reset the tablet's primary to the current shard primary using the [`vtctl ReparentTablet`](../../../reference/programs/vtctl/tablets/#reparenttablet) command. You can then restart replication on the tablet if it was stopped by calling the [`vtctl StartReplication`](../../../reference/programs/vtctl/tablets/#startreplication) command.
