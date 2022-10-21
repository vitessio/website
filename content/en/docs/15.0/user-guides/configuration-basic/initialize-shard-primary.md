---
title: Initialize Shard Primary
weight: 9
---

A new primary is elected automatically by VTOrc and no user action is required. However, a shard can be initialized manually as well using the following steps.

The [PlannedReparentShard](../../configuration-advanced/reparenting/#plannedreparentshard-planned-reparenting) command should be used to initialize the shard by electing a new primary and setting up replication for the replicas. Additionally, a database is created to store the data for the keyspace-shard. The default name for the database will be `vt_` followed by the keyspace. In our use case, it would be `vt_commerce`. You can override this default by providing an `init_db_name_override` flag to each vttablet. However, all future invocations must continue to supply this parameter.

Until this command is run, you may see errors like this in the vttablet logs: `Cannot start query service: Unknown database 'vt_xxx'`. This is because the database will be created only after a primary is elected.

If you have semi-sync enabled and did not set up at least two replicas, PlannedReparentShard could hang indefinitely. Even if it succeeds, future operations that perform failovers could cause this shard to go into a deadlocked state.

After this step, visiting the `/debug/status` page on the vttablets should show all the tablets as healthy:

![healthy-tablet](../img/healthy-tablet.png)

