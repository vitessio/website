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
Reshard -- --v1 [--cells=<cells>] [--tablet_types=<source_tablet_types>] [--skip_schema_copy]
                [--auto_start] [--stop_after_copy] [--on-ddl=<action>] <keyspace.workflow>
                <source_shards> <target_shards>
```

### Description

Reshard support horizontal sharding by letting you change the sharding ranges of your existing keyspace.

### Parameters

#### --cells
**optional**\

<div class="cmd">
Comma separated Cell(s) or CellAlias(es) to replicate from.
</div>

#### --tablet_types
**optional**\
**default** empty

<div class="cmd">
Source Vitess tablet_type, or comma separated list of tablet types, that should be used for choosing source tablet(s) for the reshard.
</div>

#### --skip_schema_copy
**optional**\
**default** false

<div class="cmd">
If true the source schema is copied to the target shards. If false, you need to create the tables
before calling reshard.
</div>

#### --auto_start
**optional**\
**default** true

<div class="cmd">
If false, streams will start in the Stopped state and will need to be explicitly started (default true).
</div>

#### --stop_after_copy
**optional**\
**default** false

<div class="cmd">
Streams will be stopped once the copy phase is completed.
</div>

#### --on-ddl
**optional**\
**default** IGNORE

<div class="cmd">

This flag allows you to specify what to do with DDL SQL statements when they are encountered
in the replication stream from the source. The values can be as follows:

* `IGNORE`: Ignore all DDLs (this is also the default, if a value for `on-ddl`
  is not provided).
* `STOP`: Stop when DDL is encountered. This allows you to make any necessary
  changes to the target. Once changes are made, updating the workflow state to
  `Running` will cause VReplication to continue from just after the point where
  it encountered the DDL. Alternatively you may want to `Cancel` the workflow
  and create a new one to fully resync with the source.
* `EXEC`: Apply the DDL, but stop if an error is encountered while applying it.
* `EXEC_IGNORE`: Apply the DDL, but ignore any errors and continue replicating.

{{< warning >}}
We caution against against using `EXEC` or `EXEC_IGNORE` for the following reasons:
  * You may want a different schema on the target.
  * You may want to apply the DDL in a different way on the target.
  * The DDL may take a long time to apply on the target and may disrupt replication, performance, and query execution (if serving  traffic from the target) while it is being applied.
{{< /warning >}}

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
