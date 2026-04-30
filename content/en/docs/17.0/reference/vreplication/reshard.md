---
title: Reshard
description: Reshard a keyspace to achieve horizontal scaling
weight: 20
aliases: ['/docs/reference/vreplication/v2/reshard/']
---

{{< warning >}}
These workflows can have a significant impact on the source tablets (which are often in production) — especially when a PRIMARY tablet is used as a source. You can limit the impact on the source tablets using the [`--vreplication_copy_phase_max_*` vttablet flags](../flags/#vreplication_copy_phase_max_innodb_history_list_length)
{{< /warning >}}

## Command

```
Reshard -- <options> <action> <workflow identifier>
```

or

```
Reshard -- [--source_shards=<source_shards>] [--target_shards=<target_shards>] [--cells=<cells>]
           [--tablet_types=<source_tablet_types>] [--skip_schema_copy] [--auto_start]
           [--stop_after_copy] [--on-ddl=<ddl-action>] [--timeout=timeoutDuration]
           [--reverse_replication] [--keep_data] [--keep_routing_rules] <action> <keyspace.workflow>
```

## Description

`Reshard` is used to create and manage workflows to horizontally shard an existing keyspace. The source keyspace can be unsharded or sharded.


## Parameters

### action

`Reshard` is an "umbrella" command. The `action` sub-command defines the operation on the workflow.
Action must be one of the following: `Create`, `Show`, `Progress`, `SwitchTraffic`, `ReverseTrafffic`, `Cancel`, or `Complete`.

#### Create
<div class="cmd">

`Create` sets up and creates a new workflow. The workflow name should not conflict with that of an existing workflow.

</div>

#### Show
<div class="cmd">

`Show` displays useful information about a workflow. (At this time the [Workflow](../workflow) Show command gives more information. This will be improved over time.)

</div>

#### Progress
<div class="cmd">

`Progress` reports the progress of a workflow by showing the percentage of data copied across targets, if workflow is in copy state, and the replication lag between the target and the source once the copy phase is completed.

It is too expensive to get real-time row counts of tables, using _count(*)_, say. So we use the statistics available in the `information_schema` to approximate copy progress. This data can be significantly off (up to 50-60%) depending on the utilization of the underlying mysql server resources. You can manually run `analyze table` to update the statistics if so desired.

</div>

#### SwitchTraffic
<div class="cmd">

`SwitchTraffic` switches traffic forward for the `tablet_types` specified. This replaces the previous `SwitchReads` and `SwitchWrites` commands with a single one. It is now possible to switch all traffic with just one command, and this is the default behavior. Also, you can now switch replica, rdonly and primary traffic in any order: earlier you needed to first `SwitchReads` (for replicas and rdonly tablets) first before `SwitchWrites`.

</div>

#### ReverseTraffic
<div class="cmd">

`ReverseTraffic` switches traffic in the reverse direction for the `tablet_types` specified. The traffic should have been previously switched forward using `SwitchTraffic` for the `cells` and `tablet_types` specified.

</div>

#### Cancel
<div class="cmd">

`Cancel` can be used if a workflow was created in error or was misconfigured and you prefer to create a new workflow instead of fixing this one. Cancel can only be called if no traffic has been switched. It removes vreplication-related artifacts like rows from vreplication and copy_state tables in the sidecar `_vt` database along with the new target shards from the topo and, by default, the target tables on the target keyspace
(see [`--keep_data`](./#--keep_data) and [`--rename_tables`](#--rename_tables)).

</div>

#### Complete
<div class="cmd">

{{< warning >}}
This is a destructive command
{{< /warning >}}

`Complete` is used after all traffic has been switched. It removes vreplication-related artifacts like rows from vreplication and copy_state tables in the sidecar `_vt` database along with the original source shards from the topo. By default, the source tables are also dropped on the source shards
(see [`--keep_data`](./#--keep_data) and [`--rename_tables`](#--rename_tables)) .

</div>

### options

Each `action` has additional options/parameters that can be used to modify its behavior.

`actions` are common to both `MoveTables` and `Reshard` workflows. Only the `create` action has different parameters, all other actions have common options and similar semantics.

#### --auto_start
**optional**\
**default** true

<div class="cmd">

Normally the workflow starts immediately after it is created. If this flag is set
to false then the workflow is in a Stopped state until you explicitly start it.

</div>

###### Uses

* Allows updating the rows in `_vt.vreplication` after `Reshard` has setup the
streams. For example, you can add some filters to specific tables or change the
projection clause to modify the values on the target. This
provides an easier way to create simpler Materialize workflows by first using
`Reshard` with auto_start false, updating the BinlogSource as required by your
Materialize and then start the workflow.
* Changing the `copy_state` and/or `pos` values to restart a broken `Reshard` workflow
from a specific point of time

#### --cells
**optional**\
**default** local cell (of source tablet)\
**string**

<div class="cmd">

Comma seperated list of Cell(s) and/or CellAlias(es) to replicate from.

</div>

###### Uses

* Improve performance by picking a tablet in cells in network proximity with the target
* Reduce bandwidth costs by skipping cells that are in different availability zones
* Select cells where replica lags are lower

#### --defer-secondary-keys
**optional**\
**default** false

{{< warning >}}
This flag is currently **experimental**.
{{< /warning >}}

<div class="cmd">

If true, any secondary keys are dropped from the table definitions on the target shard(s) as we first initialize the
tables for the [copy phase](../internal/life-of-a-stream/#copy). The exact same key definitions
are then re-added when the copy phase completes for each table.

With this method all secondary index records for the table are generated in one bulk operation. This should significantly
improve the overall copy phase execution time on large tables with many secondary keys — especially with
[MySQL 8.0.31](https://dev.mysql.com/doc/relnotes/mysql/8.0/en/news-8-0-31.html) and later due to InnoDB's support for
parallel index builds. This is logically similar to the
[`mysqldump` `--disable-keys` option](https://dev.mysql.com/doc/refman/en/mysqldump.html#option_mysqldump_disable-keys).

</div>

#### --drop_foreign_keys
**optional**
**default** false

<div class="cmd">

If true, tables in the target keyspace will be created without any foreign keys that exist on the source.

</div>

#### --dry_run
**optional**\
**default** false

<div class="cmd">

For the `SwitchTraffic`, `ReverseTraffic`, and `Complete` actions, you can do a dry run where no actual steps are taken
but the command logs all the steps that would be taken.

</div>

#### --exclude
**optional** only applies if `--all` is specified

<div class="cmd">

If moving all tables, specifies tables to be skipped.

</div>

#### --keep_data
**optional**\
**default** false

<div class="cmd">

Usually, the target tables are deleted by `Cancel`. If this flag is used the target tables will not be deleted.

</div>

#### --keep_routing_rules
**optional**\
**default** false

<div class="cmd">

Usually, any routing rules created by the workflow in the source and target keyspace are removed by `Complete` or `Cancel`. If this flag is used the routing rules will be left in place.

</div>

#### --max_replication_lag_allowed
**optional**\
**default**  the value used for `--timeout`

<div class="cmd">

While executing `SwitchTraffic` we ensure that the VReplication lag for the workflow is less than this duration, otherwise report an error and don't attempt the switch. The calculated VReplication lag is the estimated maximum lag across workflow streams between the last event seen at the source and the last event processed by the target (which would be a heartbeat event if we're fully caught up). Usually, when VReplication has caught up, this lag should be very small (under a second).

While switching write traffic, we temporarily make the source databases read-only, and wait for the targets to catchup. This means that the application can effectively be partially down for this cutover period as writes will pause or error out. While switching write traffic this flag can ensure that you only switch traffic if the current lag is low, thus limiting this period of write-unavailability and avoiding it entirely if we're not likely to catch up within the `--timeout` window.

While switching read traffic this can also be used to set an approximate upper bound on how stale reads will be against the replica tablets when using `@replica` shard targeting.

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
  * You may want a different schema on the target
  * You may want to apply the DDL in a different way on the target
  * The DDL may take a long time to apply on the target and may disrupt replication, performance, and query execution while it is being applied (if serving traffic from the target)
{{< /warning >}}

</div>

#### --reverse_replication
**optional**\
**default** true

<div class="cmd">

`SwitchTraffic` for primary tablet types, by default, starts a reverse replication stream with the current target as the source, replicating back to the original source. This enables a quick and simple rollback mechanism using `ReverseTraffic`. This reverse workflow name is that of the original workflow concatenated with \_reverse.

If set to false these reverse replication streams will not be created and you will not be able to rollback once you have switched write traffic over to the target.

</div>

#### --stop_after_copy

**optional**
**default** false

<div class="cmd">

If set, the workflow will stop once the Copy phase has been completed i.e. once
all tables have been copied and VReplication decides that the lag
is small enough to start replicating, the workflow state will be set to Stopped.

</div>

###### Uses
* If you just want a consistent snapshot of all the tables you can set this flag. The workflow
will stop once the copy is done and you can then mark the workflow as `Complete`d

#### --source_shards
**mandatory**

<div class="cmd">

Comma separated shard names to reshard from.

</div>

#### --tablet_types 
**optional**\
**default** `--vreplication_tablet_type` parameter value for the tablet. `--vreplication_tablet_type` has the default value of "in_order:REPLICA,PRIMARY".\
**string**

<div class="cmd">

Source tablet types to replicate from (e.g. PRIMARY, REPLICA, RDONLY). The value
specified impacts [tablet selection](../tablet_selection/) for the workflow.

</div>

#### --target_shards
**mandatory**

<div class="cmd">

Comma separated shard names to reshard to.

</div>

#### --timeout
**optional**\
**default** 30s

<div class="cmd">

For primary tablets, SwitchTraffic first stops writes on the source primary and waits for the replication to the target to
catchup with the point where the writes were stopped. If the wait time is longer than timeout
the command will error out. For setups with high write qps you may need to increase this value.

</div>


#### workflow identifier

<div class="cmd">

All workflows are identified by `targetKeyspace.workflow` where `targetKeyspace` is the name of the keyspace to which the tables are being moved. `workflow` is a name you assign to the `Reshard` workflow to identify it.

</div>


### The most basic Reshard Workflow lifecycle

1. Initiate the migration using `Create`<br/>
`Reshard -- --source_shards=<source_shards> --target_shards=<target_shards> Create <keyspace.workflow>`
1. Monitor the workflow using `Show` or `Progress`<br/>
`Reshard Show <keyspace.workflow>` _*or*_ <br/>
`Reshard Progress <keyspace.workflow>`<br/>
1. Confirm that data has been copied over correctly using [VDiff](../vdiff)
1. Cutover to the target keyspace with `SwitchTraffic`<br/>
`Reshard SwitchTraffic <keyspace.workflow>`
1. Cleanup vreplication artifacts and source shards with `Complete`<br/>
`Reshard Complete <keyspace.workflow>`
