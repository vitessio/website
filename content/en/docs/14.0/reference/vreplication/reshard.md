---
title: Reshard
description: Reshard a keyspace to achieve horizontal scaling
weight: 20
aliases: ['/docs/reference/vreplication/v2/reshard/']
---

{{< info >}}
This documentation is for a new (v2) set of vtctld commands that start in Vitess 11.0. See [RFC](https://github.com/vitessio/vitess/issues/7225) for more details.
{{< /info >}}

{{< warning >}}
These workflows can have a significant impact on the source tablets (which are often in production) — especially when a PRIMARY tablet is used as a source. You can limit the impact on the source tablets using the [`--vreplication_copy_phase_max_*` vttablet flags](../flags/#vreplication_copy_phase_max_innodb_history_list_length)
{{< /warning >}}

## Command

```
Reshard <options> <action> <workflow identifier>
```

or

```
Reshard [--source_shards=<source_shards>] [--target_shards=<target_shards>] [--cells=<cells>] [--tablet_types=<source_tablet_types>]  [--skip_schema_copy] [--auto_start] [--stop_after_copy] [--timeout=timeoutDuration] [--reverse_replication] [--keep_data] [--keep_routing_rules] <action> <keyspace.workflow>
```

## Description

Reshard is used to create and manage workflows to horizontally shard an existing keyspace. The source keyspace can be unsharded or sharded.

## Parameters

### action

<div class="cmd">

Reshard is an "umbrella" command. The `action` sub-command defines the operation on the workflow.
Action must be one of the following: Create, Complete, Cancel, SwitchTraffic, ReverseTrafffic, Show, or Progress 

</div>

### options
<div class="cmd">

Each `action` has additional options/parameters that can be used to modify its behavior.

`actions` are common to both MoveTables and Reshard v2 workflows. Only the `create` action has different parameters, all other actions have common options and similar semantics. These actions are documented separately.

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

**optional**
**default** true

<div class="cmd">

Normally the workflow starts immediately after it is created. If this flag is set
to false then the workflow is in a Stopped state until you explicitly start it.

</div>

###### Uses
* allows updating the rows in `_vt.vreplication` after MoveTables has setup the
streams. For example, you can add some filters to specific tables or change the
projection clause to modify the values on the target. This
provides an easier way to create simpler Materialize workflows by first using
MoveTables with auto_start false, updating the BinlogSource as required by your
Materialize and then start the workflow.
* changing the `copy_state` and/or `pos` values to restart a broken MoveTables workflow
from a specific point of time.

#### -stop_after_copy

**optional**
**default** false

<div class="cmd">

If set, the workflow will stop once the Copy phase has been completed i.e. once
all tables have been copied and VReplication decides that the lag
is small enough to start replicating, the workflow state will be set to Stopped.

###### Uses
* If you just want a consistent snapshot of all the tables you can set this flag. The workflow
will stop once the copy is done and you can then mark the workflow as `Complete`d

</div>

#### --timeout
**optional**\
**default** 30s

<div class="cmd">

For primary tablets, SwitchTraffic first stops writes on the source primary and waits for the replication to the target to
catchup with the point where the writes were stopped. If the wait time is longer than timeout
the command will error out. For setups with high write qps you may need to increase this value.

</div>

#### --reverse_replication
**optional**\
**default** true

<div class="cmd">

SwitchTraffic for primary tablet types, by default, starts a reverse replication stream with the current target as the source, replicating back to the original source. This enables a quick and simple rollback using ReverseTraffic. This reverse workflow name is that of the original workflow concatenated with \_reverse.

If set to false these reverse replication streams will not be created and you will not be able to rollback once you have switched write traffic over to the target.

</div>

#### --keep_data
**optional**\
**default** false

<div class="cmd">

Usually, the target data (tables or shards) are deleted by Cancel. If this flag is used with MoveTables, target tables will not be deleted and, with Reshard, target shards will not be dropped.

</div>

#### --keep_routing_rules
**optional**\
**default** false

<div class="cmd">

Usually, any routing rules created by the workflow in the source and target keyspace are removed by Complete or Cancel. If this flag is used the routing rules will be left in place.

</div>

#### workflow identifier

<div class="cmd">

All workflows are identified by `targetKeyspace.workflow` where `targetKeyspace` is the name of the keyspace to which the tables are being moved. `workflow` is a name you assign to the Reshard workflow to identify it.

</div>


### The most basic Reshard Workflow lifecycle

1. Initiate the migration using [Create](../create)<br/>
`Reshard --source_shards=<source_shards> --target_shards=<target_shards> Create <keyspace.workflow>`
1. Monitor the workflow using [Show](../show) or [Progress](../progress)<br/>
`Reshard Show <keyspace.workflow>` _*or*_ <br/>
`Reshard Progress <keyspace.workflow>`<br/>
1. Confirm that data has been copied over correctly using [VDiff](../vdiff)
1. Cutover to the target keyspace with [SwitchTraffic](../switchtraffic) <br/>
`Reshard SwitchTraffic <keyspace.workflow>`
1. Cleanup vreplication artifacts and source shards with [Complete](../complete) <br/>
`Reshard Complete <keyspace.workflow>`
