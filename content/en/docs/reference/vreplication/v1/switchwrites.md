---
title: SwitchWrites
description: Route writes to target keyspace in a vreplication workflow
weight: 50
aliases: ['/docs/reference/vreplication/switchwrites/']
---

{{< info >}}
Starting with Vitess 11.0 you should use the [SwitchTraffic VReplication v2 commands](../../switchtraffic)
{{< /info >}}

### Command

```
SwitchWrites  [-timeout=30s] [-cancel] [-reverse] [-reverse_replication=false] -tablet_types={replica|rdonly} [-dry-run] <keyspace.workflow>
```

### Description

SwitchWrites is used to switch writes for tables in a MoveTables workflow or for entire keyspace in the
Reshard workflow away from the primary in the source keyspace to the primary in the target keyspace

### Parameters

#### -timeout 
**optional**\
**default** 30s

<div class="cmd">
Specifies the maximum time to wait, in seconds, for vreplication to catch up on primary migrations. The migration will be cancelled on a timeout.
</div>


#### -filtered_replication_wait_time 
**DEPRECATED**\
**default** 30s

<div class="cmd">
SwitchWrites first stops writes on the source primary and waits for the replication to the target to
catchup with the point where the writes were stopped. If the wait time is longer than filtered_replication_wait_time
the command will error out. 
For setups with high write qps you may need to increase this value.
</div>

#### -cancel 
**optional**\
**default** false

<div class="cmd">
If a previous SwitchWrites returned with an error you can restart it by running the command again (after fixing
the issue that caused the failure) or the SwitchWrites can be canceled using this parameter. Only the SwitchWrites
is cancelled: the workflow is set to Running so that replication continues.
</div>

#### -reverse 
**optional**\
**default** false

<div class="cmd">
Reverse a previous SwitchWrites serve from source
</div>

#### -reverse_replication 
**optional**\
**default** true

<div class="cmd">
SwitchWrites, by default, starts a reverse replication stream with the current target as the source, replicating
back to the original source. This enables a quick and simple rollback. This reverse workflow name is that
of the original workflow concatenated with \_reverse.
</div>

#### -tablet_types
**mandatory**

<div class="cmd">
Tablet types to switch one or both or rdonly/replica (default "rdonly,replica")
Note: For tablet type rdonly you must [SwitchReads](../switchreads) before you can SwitchWrites
</div>

#### -dry-run 
**optional**\
**default** false

<div class="cmd">
You can do a dry run where no actual action is taken but the command logs all the actions that would be taken
by SwitchReads.
</div>

#### keyspace.workflow 
**mandatory**

<div class="cmd">
Name of target keyspace and the associated workflow to SwitchWrites for.
</div>
