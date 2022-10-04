---
title: Shard Level Migrations
description: Move shards between keyspaces without downtime
weight: 120
aliases: ['/docs/reference/vreplication/v2/shardlevelmigrations/']
---

{{< warning >}}
This feature is an **experimental** variant of the `MoveTables` command that allows you to migrate individual shards from one keyspace to another. Please be sure to understand the limitations and requirements below.
{{< /warning >}}

The full set of options for the `MoveTables` command [can be found here](../movetables/). The options specific to shard level migrations will be covered here.

## Use Case

The [`Mount`](../mount/) and [`Migrate`](../migrate/) commands are the default method provided for moving keyspaces from one Vitess cluster to another. This method, however, only provides a one time one way cutover without the ability to revert in the way that [`MoveTables`](../movetables/) does. Supporting shard level migrations allows you to move very large keyspaces from one Vitess cluster to another in an incremental way, cutting over traffic and reverting as needed on a per shard basis. When using this method, there is also a new [`vtgate`](../../programs/vtgate/) `--enable_partial_keyspace_migration` flag that enables support for shard level query routing so that individual shards can be routed to one side of the migration or the other during the migration period — *including when shard targeting is used*.

## Command

```
MoveTables --source_shards=<source_shards> <options> <action> <workflow identifier>
```

## Parameters

#### --source_shards
**mandatory** (for shard level migrations)
<div class="cmd">

A list of 1 or more shards that you want to migrate from the source keyspace to the target keyspace.

</div>

## Limitations and Requirements

  - The source and target keyspaces must have the exact same shard definitions
  - Query routing is all or nothing per shard, so you must *move all tables in the workflow that you wish to migrate* and you would use [`SwitchTraffic --tablet_types=RDONLY,REPLICA,PRIMARY`](../switchtraffic/) to switch *read and write traffic* all at once for the shard(s)
  - When the entire migration is complete, you cannot use the standard [`Complete`](../complete/) workflow action and the final cleanup step requires manual work:
    - The _reverse workflows should be [`Cancel`](../cancel/)ed. This will clean up the both the global routing rules and the shard routing rules associated with the migration
      - Note: [`Workflow delete`](../workflow/) does not clean up the shard routing rules
    - You would need to perform any and all source side cleanup manually

## Related Vitess Flags

In order to support the shard level query routing during the migration, the `--enable_partial_keyspace_migration` flag must be set for all of the [`vtgate`](../../programs/vtgate/) instances in the target Vitess cluster.

{{< warning >}}
This routing support has a performance impact for all traffic and thus you should only use this flag during the migration period and remove it once the migration is complete.
{{< /warning >}}

## Related Commands

You can view the current shard level routing rules in place using the [`GetShardRoutingRules`](../../programs/vtctldclient/vtctldclient_getshardroutingrules/) [`vtctldclient`](../../programs/vtctldclient/) command and you can save updated routing rules using the [`ApplyShardRoutingRules`](../../programs/vtctldclient/vtctldclient_applyshardroutingrules/) command.