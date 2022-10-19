---
title: Initialize Shard Primary
weight: 9
---

The [PlannedReparentShard](../../configuration-advanced/reparenting/#plannedreparentshard-planned-reparenting) command should be used to initialize the shard by electing a new primary and setting up replication for the replicas. Additionally, a database is created to store the data for the keyspace-shard. The default name for the database will be `vt_` followed by the keyspace. In our use case, it would be `vt_commerce`. You can override this default by providing an `init_db_name_override` flag to each vttablet. However, all future invocations must continue to supply this parameter.

The InitShardPrimary step can also be used to do the same operation. However, it is a destructive command and should only be used by advanced users. This command copies over the `executed_gtid_set` from the primary to the replica which can break replication if the user isn't careful. 

{{< info >}}
If using a custom `init_db.sql` that omits `SET sql_log_bin = 0`, then InitShardPrimary must be used instead of PlannedReparentShard.
{{< /info >}}

The command for `InitShardPrimary` is as follows:

```text
vtctlclient \
  InitShardPrimary -- \
  --force \
  commerce/0 \
  cell1-100
```

Until one of these commands is run, you may also see errors like this in the vttablet logs: `Cannot start query service: Unknown database 'vt_xxx'`. This is because the database will be created only after a primary is elected.

If you have semi-sync enabled and did not set up at least two replicas, InitShardPrimary could hang indefinitely. Even if it succeeds, future operations that perform failovers could cause this shard to go into a deadlocked state.

After this step, visiting the `/debug/status` page on the vttablets should show all the tablets as healthy:

![healthy-tablet](../img/healthy-tablet.png)

{{< warning >}}
`InitShardPrimary` is a destructive command that resets all servers by deleting their binlog metadata. It should only be used for initializing a brand new cluster.
{{< /warning >}}

{{< info >}}
`InitShardPrimary` will soon be deprecated. This action will be performed automatically by VTOrc once it is released as production-ready.
{{< /info >}}
