---
title: Reshard
description: split or merge shards in a keyspace
weight: 60
---

{{< info >}}
Starting with Vitess 11.0 you should use the [VReplication v2 commands](../../reshard)
{{< /info >}}

### Command

```
Reshard -v1 [-cells=<cells>] [-tablet_types=<source_tablet_types>] [-skip_schema_copy] [-auto_start] [-stop_after_copy] <keyspace.workflow> <source_shards> <target_shards>
```

### Description

Reshard support horizontal sharding by letting you change the sharding ranges of your existing keyspace.

### Parameters

#### -cells
**optional**\

<div class="cmd">
Comma separated Cell(s) or CellAlias(es) to replicate from.
</div>

#### -tablet_types
**optional**\
**default** empty

<div class="cmd">
Source Vitess tablet_type, or comma separated list of tablet types, that should be used for choosing source tablet(s) for the reshard.
</div>

#### -skip_schema_copy
**optional**\
**default** false

<div class="cmd">
If true the source schema is copied to the target shards. If false, you need to create the tables
before calling reshard.
</div>

#### -auto_start
**optional**\
**default** true

<div class="cmd">
If false, streams will start in the Stopped state and will need to be explicitly started (default true).
</div>

#### -stop_after_copy
**optional**\
**default** false

<div class="cmd">
Streams will be stopped once the copy phase is completed.
</div>

#### keyspace.workflow
**mandatory**

<div class="cmd">
Name of keyspace being sharded and the associated workflow name, used in later commands to refer back to this reshard.
</div>

#### source_shards
**mandatory**

<div class="cmd">
Comma separated shard names to reshard from.
</div>

#### target_shards
**mandatory**

<div class="cmd">
Comma separated shard names to reshard to.
</div>


### A Reshard Workflow

Once you decide on the new resharding strategy for a keyspace, you need to initiate a VReplication workflow as follows:

1. Initiate the migration using Reshard
2. Monitor the workflow using [Workflow](../../workflow)
3. Confirm that data has been copied over correctly using [VDiff](../../vdiff)
4. Start the cutover by routing all reads from your application to those tables using [SwitchReads](../switchreads)
5. Complete the cutover by routing all writes using [SwitchWrites](../switchwrites)
6. Optionally cleanup the source tables using [DropSources](../dropsources)
