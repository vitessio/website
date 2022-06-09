---
title: Reparenting
weight: 6
aliases: ['/docs/user-guides/reparenting/']
---

**Reparenting** is the process of changing a shard's primary tablet from one host to another or changing a replica tablet to have a different primary. Reparenting can be initiated manually or it can occur automatically in response to particular database conditions. As examples, you might reparent a shard or tablet during a maintenance exercise or automatically trigger reparenting when a primary tablet dies.

This document explains the types of reparenting that Vitess supports:

* [Active reparenting](../../configuration-advanced/reparenting/#active-reparenting) occurs when Vitess manages the entire reparenting process.
* [External reparenting](../../configuration-advanced/reparenting/#external-reparenting) occurs when another tool handles the reparenting process, and Vitess just updates its topology service, replication graph, and serving graph to accurately reflect primary-replica relationships.

## MySQL requirements

### GTIDs

Vitess requires the use of global transaction identifiers ([GTIDs](https://dev.mysql.com/doc/refman/5.6/en/replication-gtids-concepts.html)) for its operations:

* During active reparenting, Vitess uses GTIDs to initialize the replication process and then depends on the GTID stream to be correct when reparenting. (During external reparenting, Vitess assumes the external tool manages the replication process.)
* During resharding, Vitess uses GTIDs for [VReplication](../../../reference/vreplication), the process by which source tablet data is transferred to the proper destination tablets.

### Semisynchronous replication

Vitess does not depend on [semisynchronous replication](https://dev.mysql.com/doc/refman/5.6/en/replication-semisync.html) but does work if it is implemented. Larger Vitess deployments typically do implement semisynchronous replication.

### Active Reparenting

You can use the following `vtctl` commands to perform reparenting operations:

* `PlannedReparentShard`
* `EmergencyReparentShard`

Both commands lock the Shard record in the global topology service. The two commands cannot run in parallel, nor can either command run in parallel with the `InitShardPrimary` command.

Both commands are both dependent on the global topology service being available, and they both insert rows in the topology service's `_vt.reparent_journal` table. As such, you can review your database's reparenting history by inspecting that table.

### PlannedReparentShard: Planned reparenting

The `PlannedReparentShard` command reparents a healthy shard to a new primary. It can be used to initialize the shard primary when the shard is brought up. If it is used to change the primary of an already running shard, then both the current and new primary must be up and running. In case the current primary is down, use `EmergencyReparentShard` instead.

This command performs the following actions when used to change the current primary:

1. Puts the current primary tablet in read-only mode.
2. Shuts down the current primary's query service, which is the part of the system that handles user SQL queries. At this point, Vitess does not handle any user SQL queries until the new primary is configured and can be used a few seconds later.
3. Retrieves the current primary's replication position.
4. Instructs the primary-elect tablet to wait for replication data and then begin functioning as the new primary after that data is fully transferred.
5. Ensures replication is functioning properly via the following steps:
    - On the primary-elect tablet, insert a row into an internal tabkle and then update the global shard object's PrimaryAlias record.
    - In parallel on each replica, including the old primary, set the new primary and wait for the inserted row to replicate to the replica tablet. Replica tablets that had not been replicating before the command was called are left in their current state and do not start replication after the reparenting process.
    - Start replication on the old primary tablet so it catches up to the new primary.

In this scenario, the old primary's tablet type transitions to `spare`. If health checking is enabled on the old primary, it will likely rejoin the cluster as a replica on the next health check. To enable health checking, set the `target_tablet_type` parameter when starting a tablet. That parameter indicates what type of tablet that tablet tries to be when healthy. When it is not healthy, the tablet type changes to spare.

This command performs the following actions when used to initialize the first primary in the shard:
1. Promote the new primary that is specified.
2. Ensures replication is functioning properly via the following steps:
    - On the primary-elect tablet, insert a row into an internal table and then update the global shard object's PrimaryAlias record.
    - In parallel on each replica, set the new primary and wait for the inserted row to replicate to the replica tablet.

The new primary (if unspecified) is chosen using the configured [Durability Policy](../../configuration-basic/durability_policy).

### EmergencyReparentShard: Emergency reparenting

The `EmergencyReparentShard` command is used to force a reparent to a new primary when the current primary is unavailable. The command assumes that data cannot be retrieved from the current primary because it is dead or not working properly.

As such, this command does not rely on the current primary at all to replicate data to the new primary. Instead, it makes sure that the primary-elect is the most advanced in replication within all of the available replicas or that the primary-elect has caught up to the most advanced one. In either case, the candidate will only be promoted once it is the most advanced replica.

**Important**: You can specify which replica you want to be promoted. If not specified, Vitess will choose it for you depending on the durability policies being used.

This command performs the following actions:

1. Determines the current replication position on all of the replica tablets and finds the tablet that has the most advanced replication position.
2. Choose a primary-elect tablet based on the durability policy specified, if the user has not specified one using the flags.
3. Wait for the primary-elect to catch up to the most advanced replica, if it isn't already the most advanced.
4. Promotes the primary-elect tablet to be the new primary. In addition to changing its tablet type to primary, the primary-elect performs any other changes that might be required for its new state.
5. Ensures replication is functioning properly via the following steps:
    - On the primary-elect tablet, Vitess inserts an entry in a test table and then updates the `PrimaryAlias` record of the global Shard object.
    - In parallel on each replica, excluding the old primary, Vitess sets the primary and waits for the test entry to replicate to the replica tablet. Replica tablets that had not been replicating before the command was called are left in their current state and do not start replication after the reparenting process.

The new primary (if unspecified) is chosen using the configured [Durability Policy](../../configuration-basic/durability_policy).

## External Reparenting

External reparenting occurs when another tool handles the process of changing a shard's primary tablet. After that occurs, the tool needs to call the [`vtctl TabletExternallyReparented`](../../../reference/programs/vtctl/shards/#tabletexternallyreparented) command to ensure that the topology service, replication graph, and serving graph are updated accordingly.

That command performs the following operations:

1. Reads the Tablet from the local topology service.
2. Reads the Shard object from the global topology service.
3. If the Tablet type is not already `PRIMARY`, sets the tablet type to `PRIMARY`.
4. The Shard record is updated asynchronously (if needed) with the current primary alias.
5. Any other tablets that still have their tablet type to `PRIMARY` will demote themselves to `REPLICA`.

The `TabletExternallyReparented` command fails in the following cases:

* The global topology service is not available for locking and modification. In that case, the operation fails completely.

Active reparenting might be a dangerous practice in any system that depends on external reparents. You can disable active reparents by starting `vtctld` with the `--disable_active_reparents` flag set to true. (You cannot set the flag after `vtctld` is started.)

## Fixing Replication

A tablet can be orphaned after a reparenting if it is unavailable when the reparent operation is running but then recovers later on. In that case, you can manually reset the tablet's primary to the current shard primary using the `vtctl ReparentTablet` command. You can then restart replication on the tablet if it was stopped by calling the `vtctl StartReplication` command.
