---
title: MoveTables
description: Move tables between keyspaces without downtime
weight: 10
aliases: ['/docs/reference/vreplication/v2/movetables/']
---

{{< info >}}
This documentation is for a new (v2) set of vtctld commands that start in Vitess 11.0. See [RFC](https://github.com/vitessio/vitess/issues/7225) for more details.
{{< /info >}}

{{< warning >}}
These workflows can have a significant impact on the source tablets (which are often in production) — especially when a PRIMARY tablet is used as a source. You can limit the impact on the source tablets using the [`--vreplication_copy_phase_max_*` vttablet flags](../flags/#vreplication_copy_phase_max_innodb_history_list_length)
{{< /warning >}}

## Command

```
MoveTables <options> <action> <workflow identifier>
```
or

```
MoveTables [--source=<sourceKs>] [--tables=<tableSpecs>] [--cells=<cells>] [--tablet_types=<source_tablet_types>] [--all] [--exclude=<tables>] [--auto_start] [--stop_after_copy] [--timeout=timeoutDuration] [--reverse_replication] [--keep_data] [--keep_routing_rules] <action> <workflow identifier>
```

## Description

MoveTables is used to start and manage workflows to move one or more tables from an external database or an existing Vitess keyspace into a new Vitess keyspace. The target keyspace can be unsharded or sharded.

MoveTables is typically used for migrating data into Vitess or to implement vertical sharding. You might use the former when you first start using Vitess and the latter if you want to distribute your load across servers without sharding tables.

## Parameters

### action

MoveTables is an "umbrella" command. The `action` sub-command defines the operation on the workflow.
Action must be one of the following: Create, Complete, Cancel, SwitchTraffic, ReverseTrafffic, Show, or Progress

### options

Each `action` has additional options/parameters that can be used to modify its behavior.

`actions` are common to both MoveTables and Reshard v2 workflows. Only the `create` action has different parameters, all other actions have common options and similar semantics. These actions are documented separately.

#### source_keyspace
**mandatory**
<div class="cmd">

Name of existing keyspace that contains the tables to be moved

</div>

#### table_specs
**optional**  one of `table_specs` or `--all` needs to be specified
<div class="cmd">

_Either_

* a comma-separated list of tables
  * if target keyspace is unsharded OR '
  * if target keyspace is sharded AND the tables being moved are already defined in the target's vschema

  Example: `MoveTables --workflow=commerce2customer commerce customer customer,corder`

_Or_

* the JSON table section of the vschema for associated tables
  * if target keyspace is sharded AND
  * tables being moved are not yet present in the target's vschema

  Example: `MoveTables --workflow=commerce2customer commerce customer '{"t1":{"column_vindexes": [{"column": "id", "name": "hash"}]}}}'`

</div>

#### --cells
**optional**\
**default** local cell\
**string**

<div class="cmd">

Cell(s) or CellAlias(es) (comma-separated) to replicate from.

</div>

#### --tablet_types 
**optional**\
**default** `--vreplication_tablet_type` parameter value for the tablet. `--vreplication_tablet_type` has the default value of "in_order:REPLICA,PRIMARY".\
**string**

<div class="cmd">

Source tablet types to replicate from (e.g. PRIMARY, REPLICA, RDONLY). Defaults to --vreplication_tablet_type parameter value for the tablet, which has the default value of "in_order:REPLICA,PRIMARY".

</div>

#### --all

**optional** cannot specify `table_specs` if `--all` is specified
<div class="cmd">

Move all tables from the source keyspace.

</div>

#### --exclude

**optional** only applies if `--all` is specified
<div class="cmd">

If moving all tables, specifies tables to be skipped.

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

#### --stop_after_copy

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

Usually, any data created by the workflow in the source and target (tables or shards) are deleted by Complete or Cancel. If this flag is used the data will be left in place.

</div>

#### --keep_routing_rules
**optional**\
**default** false

<div class="cmd">

Usually, any routing rules created by the workflow in the source and target keyspace are removed by Complete or Cancel. If this flag is used the routing rules will be left in place.

</div>

### workflow identifier

<div class="cmd">

All workflows are identified by `targetKeyspace.workflow` where `targetKeyspace` is the name of the keyspace to which the tables are being moved. `workflow` is a name you assign to the MoveTables workflow to identify it.

</div>


## The most basic MoveTables Workflow lifecycle

1. Initiate the migration using [Create](../create)<br/>
`MoveTables --source=<sourceKs> --tables=<tableSpecs> Create <targetKs.workflow>`
1. Monitor the workflow using [Show](../show) or [Progress](../progress)<br/>
`MoveTables Show <targetKs.workflow>` _*or*_ <br/>
`MoveTables Progress <targetKs.workflow>`<br/>
1. Confirm that data has been copied over correctly using [VDiff](../vdiff)
1. Cutover to the target keyspace with [SwitchTraffic](../switchtraffic) <br/>
`MoveTables SwitchTraffic <targetKs.workflow>`
1. Cleanup vreplication artifacts and source tables with [Complete](../complete) <br/>
`MoveTables Complete <targetKs.workflow>`


## Common use cases for MoveTables

### Adopting Vitess

For those wanting to try out Vitess for the first time, MoveTables provides an easy way to route part of their workload to Vitess with the ability to migrate back at any time without any risk. You point a vttablet to your existing MySQL installation, spin up an unsharded Vitess cluster and use a MoveTables workflow to start serving some tables from Vitess. You can also go further and use a Reshard workflow to experiment with a sharded version of a part of your database.

See this [user guide](../../../../../docs/user-guides/configuration-advanced/unmanaged-tablet/#move-legacytable-to-the-commerce-keyspace) for detailed steps.

### Vertical Sharding

For existing Vitess users you can easily move one or more tables to another keyspace, either for balancing load or as preparation for sharding your tables.

See this [user guide](../../../../../docs/user-guides/migration/move-tables/) which describes how MoveTables works in the local example provided in the Vitess repo.

### More Reading

* [MoveTables in practice](../../../../../docs/concepts/move-tables/)
