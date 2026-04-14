---
title: Initialize Shard Primary
weight: 9
---

A new primary is elected automatically by VTOrc and no user action is required.

The InitShardPrimary command can be used to do the same operation manually. However, it is a destructive command and should only be used by advanced users. This command copies over the `executed_gtid_set` from the primary to the replica which can break replication if the user isn't careful. 

The command for `InitShardPrimary` is as follows:

```text
vtctldclient \
  InitShardPrimary \
  --force \
  commerce/0 \
  cell1-100
```

Until this step is complete, you may see errors like this in the vttablet logs: `Cannot start query service: Unknown database 'vt_xxx'`. This is because the database will be created only after a primary is elected.

If you have semi-sync enabled and did not set up at least two replicas, InitShardPrimary could hang indefinitely. Even if it succeeds, future operations that perform failovers could cause this shard to go into a deadlocked state.

After this step, visiting the `/debug/status` page on the vttablets should show all the tablets as healthy:

![healthy-tablet](../img/healthy-tablet.png)

{{< warning >}}
`InitShardPrimary` is a destructive command that resets all servers by deleting their binlog metadata. It should only be used for initializing a brand new cluster.
{{< /warning >}}

{{< info >}}
`InitShardPrimary` is deprecated. This action is performed automatically by VTOrc. If manual action is needed, it is recommended to use `PlannedReparentShard`.
{{< /info >}}
