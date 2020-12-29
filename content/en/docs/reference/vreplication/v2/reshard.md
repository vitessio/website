---
title: Reshard
description: Reshard a keyspace to achieve horizontal scaling
weight: 20
---
##### _Experimental_
This documentation is for a new (v2) set of vtctld commands. See [RFC](https://github.com/vitessio/vitess/issues/7225) for more details.

### Command

```
Reshard  -v2 <options> <action> <workflow identifier>
```

### Description

Reshard is used to start a workflow to horizontally shard an existing keyspace. The source keyspace can be unsharded or sharded.

### Parameters

#### action

<div class="cmd">
Reshard is an "umbrella" command. The `action` sub-command defines the operation on the workflow.
</div>

#### options
<div class="cmd">
Each `action` has additional options/parameters that can be used to modify its behavior.

`actions` are common to both MoveTables and Reshard v2 workflows. Only the `start` action has different parameters, all other actions have common options and semantics. These actions are documented separately.
</div>

#### workflow identifier

<div class="cmd">
All workflows are identified by `targetKeyspace`.`workflow` where `targetKeyspace` is the name of the keyspace to which the tables are being moved to. `workflow` is a name you assign to the MoveTables workflow to identify it.
</div>


### The most basic Reshard Workflow lifecycle

1. Initiate the migration using [Start](../start)<br/>
`Reshard -source_shards=<source_shards> -target_shards=<target_shards> Start <keyspace.workflow>`
1. Monitor the workflow using [Show](../show) or [Progress](../progress)<br/>
`Reshard Show <keyspace.workflow>` _*or*_ <br/>
`Reshard Progress <keyspace.workflow>`<br/>
1. Confirm that data has been copied over correctly using [VDiff](../../vdiff)
1. Cutover to the target keyspace with [SwitchTraffic](../switchtraffic) <br/>
`Reshard SwitchTraffic <keyspace.workflow>`
1. Cleanup vreplication artifacts and source shards [Complete](../complete) <br/>
`Reshard Complete <keyspace.workflow>`
