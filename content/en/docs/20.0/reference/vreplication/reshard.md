---
title: Reshard
description: Reshard a keyspace to achieve horizontal scaling
weight: 20
aliases: ['/docs/reference/vreplication/v2/reshard/']
---

{{< warning >}}
These workflows can have a significant impact on the source tablets (which are often in production) — especially when a PRIMARY tablet is used as a source. You can limit the impact on the source tablets using the [`--vreplication_copy_phase_max_*` vttablet flags](../flags/#vreplication_copy_phase_max_innodb_history_list_length)
{{< /warning >}}

## Description

[`Reshard`](../../programs/vtctldclient/vtctldclient_reshard/) is used to create and manage workflows to horizontally shard an existing keyspace. The source keyspace can be unsharded or sharded.

## Command

Please see the [`Reshard` command reference](../../programs/vtctldclient/vtctldclient_reshard/) for a full list of sub-commands and their flags.

### The Basic Reshard Workflow Lifecycle

1. Initiate the migration using `create`<br/>
`Reshard --workflow <workflow> --target-keyspace <target-keyspace> create --source-shards <source-shards> --target-shards <target-shards>`
1. Monitor the workflow using `show` or `status`<br/>
`Reshard --workflow <workflow> --target-keyspace <target-keyspace> show`<br/>
`Reshard --workflow <workflow> --target-keyspace <target-keyspace> status`<br/>
1. Confirm that data has been copied over correctly using [VDiff](../vdiff)
1. Cutover to the target keyspace with `SwitchTraffic`<br/>
`Reshard --workflow <workflow> --target-keyspace <target-keyspace> switchtraffic`
1. Cleanup vreplication artifacts and source shards with `complete`<br/>
`Reshard --workflow <workflow> --target-keyspace <target-keyspace> complete`

## Parameters

### Action

[`Reshard`](../../programs/vtctldclient/vtctldclient_reshard/) is an "umbrella" command. The [`action` or sub-command](../../programs/vtctldclient/vtctldclient_reshard/#see-also) defines the operation on the workflow.

#### Create
<div class="cmd">

[`create`](../../programs/vtctldclient/vtctldclient_movetables/vtctldclient_movetables_create/) sets up and creates a new workflow. The workflow name should not conflict with that of an existing workflow.

</div>

#### Show
<div class="cmd">

[`show`](../../programs/vtctldclient/vtctldclient_movetables/vtctldclient_movetables_show/) displays useful information about a workflow — including recent logs.

</div>

#### Status
<div class="cmd">

[`status`](../../programs/vtctldclient/vtctldclient_movetables/vtctldclient_movetables_status/) (or `progress`) reports the progress of a workflow by showing the percentage of data copied across targets, if workflow is in copy state, and the replication lag between the target and the source once the copy phase is completed. It also shows the current state of traffic for the tables involved in the workflow.

It is too expensive to get real-time row counts of tables, using _count(*)_, say. So we use the statistics available in the `information_schema` to approximate copy progress. This data can be significantly off (up to 50-60%) depending on the utilization of the underlying mysql server resources. You can manually run `ANALYZE TABLE` to update the statistics if so desired.

</div>

#### SwitchTraffic
<div class="cmd">

[`SwitchTraffic`](../../programs/vtctldclient/vtctldclient_movetables/vtctldclient_movetables_switchtraffic) switches traffic forward for the `tablet-types` specified. This replaces the previous `SwitchReads` and `SwitchWrites` commands with a single one. It is now possible to switch all traffic with just one command, and this is the default behavior. Also, you can now switch replica, rdonly and primary traffic in any order: earlier you needed to first `SwitchReads` (for replicas and rdonly tablets) first before `SwitchWrites`.

{{< info >}}
Note that VTGate can [buffer queries](../../features/vtgate-buffering/) when switching traffic which can virtually eliminate any visible impact on application users.
{{</ info >}}

</div>

#### ReverseTraffic
<div class="cmd">

[`ReverseTraffic`](../../programs/vtctldclient/vtctldclient_movetables/vtctldclient_movetables_reversetraffic/) switches traffic in the reverse direction for the `tablet-types` specified. The traffic should have been previously switched forward using `SwitchTraffic` for the `cells` and `tablet_types` specified.

{{< info >}}
Note that VTGate can [buffer queries](../../features/vtgate-buffering/) when switching traffic which can virtually eliminate any visible impact on application users.
{{</ info >}}

</div>

#### Cancel
<div class="cmd">

[`cancel`](../../programs/vtctldclient/vtctldclient_movetables/vtctldclient_movetables_cancel/) can be used if a workflow was created in error or was misconfigured and you prefer to create a new workflow instead of fixing this one. Cancel can only be called if no traffic has been switched. It removes vreplication-related artifacts like rows from vreplication and copy_state tables in the sidecar `_vt` database along with the new target shards from the topo and, by default, the target tables on the target keyspace
(see `--keep-data` and `--rename-tables`).

</div>

#### Complete
<div class="cmd">

{{< warning >}}
This is a destructive command
{{< /warning >}}

[`complete`](../../programs/vtctldclient/vtctldclient_movetables/vtctldclient_movetables_complete/) is used after all traffic has been switched. It removes vreplication-related artifacts like rows from vreplication and copy_state tables in the sidecar `_vt` database along with the original source shards from the topo. By default, the source tables are also dropped on the source shards
(see `--keep-data` and `--rename-tables`) .

</div>

### options

Each [`action` or sub-command](../../programs/vtctldclient/vtctldclient_reshard/#see-also) has additional options/parameters that can be used to modify its behavior. Please see the [command's reference docs](../../programs/vtctldclient/vtctldclient_reshard/) for the full list of command options or flags. `actions` are common to both `MoveTables` and `Reshard` workflows. Only the `create` action has different parameters, all other actions have common options and similar semantics. Below we will add additional information for a subset of key options.

#### --auto-start
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

{{< info >}}
You can alternatively specify `--all-cells` if you want to replicate from source tablets in any existing cell (the local cell of the target tablet will be preferred).
{{< /info >}}

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

#### --dry-run
**optional**\
**default** false

<div class="cmd">

For the `SwitchTraffic`, `ReverseTraffic`, and `complete` actions, you can do a dry run where no actual steps are taken
but the command logs all the steps that would be taken.

</div>

#### --keep-data
**optional**\
**default** false

<div class="cmd">

Usually, the target tables are deleted by `Cancel`. If this flag is used the target tables will not be deleted.

</div>

#### --keep-routing-rules
**optional**\
**default** false

<div class="cmd">

Usually, any routing rules created by the workflow in the source and target keyspace are removed by `Complete` or `Cancel`. If this flag is used the routing rules will be left in place.

</div>

#### --max-replication-lag-allowed
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

#### --enable-reverse-replication
**optional**\
**default** true

<div class="cmd">

`SwitchTraffic` for primary tablet types, by default, starts a reverse replication stream with the current target as the source, replicating back to the original source. This enables a quick and simple rollback mechanism using `ReverseTraffic`. This reverse workflow name is that of the original workflow concatenated with \_reverse.

If set to false these reverse replication streams will not be created and you will not be able to rollback once you have switched write traffic over to the target.

</div>

#### --stop-after-copy

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

#### --source-shards
**mandatory**

<div class="cmd">

Comma separated shard names to reshard from.

</div>

#### --tablet-types 
**optional**\
**default** "in_order:REPLICA,PRIMARY"\
**string**

<div class="cmd">

Source tablet types to replicate from (e.g. PRIMARY, REPLICA, RDONLY). The value
specified impacts [tablet selection](../tablet_selection/) for the workflow.

</div>

#### --timeout
**optional**\
**default** 30s

<div class="cmd">

For primary tablets, SwitchTraffic first stops writes on the source primary and waits for the replication to the target to
catchup with the point where the writes were stopped. If the wait time is longer than timeout
the command will error out. For setups with high write qps you may need to increase this value.

</div>
