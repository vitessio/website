---
title: MoveTables
description: Move tables between keyspaces without downtime
weight: 10
aliases: ['/docs/reference/vreplication/v2/movetables/']
---

{{< warning >}}
These workflows can have a significant impact on the source tablets (which are often in production) — especially when a PRIMARY tablet is used as a source. You can limit the impact on the source tablets using the [`--vreplication_copy_phase_max_*` vttablet flags](../flags/#vreplication_copy_phase_max_innodb_history_list_length)
{{< /warning >}}

## Description

[`MoveTables`](../../programs/vtctldclient/vtctldclient_movetables/) is used to start and manage workflows to move one or more tables from an external database or an existing Vitess keyspace into a new Vitess keyspace. The target keyspace can be unsharded or sharded.

[`MoveTables`](../../programs/vtctldclient/vtctldclient_movetables/)  is typically used for migrating data into Vitess or to implement vertical sharding. You might use the former when you first start using Vitess and the latter if you want to distribute your load across servers without sharding tables.

## Command

Please see the [`MoveTables` command reference](../../programs/vtctldclient/vtctldclient_movetables/) for a full list of sub-commands and their flags.

## The Basic MoveTables Workflow Lifecycle

1. Initiate the migration using `create`<br/>
`MoveTables --workflow <workflow> --target-keyspace <target-keyspace> create --source-keyspace <source-keyspace> --tables <tables>`
1. Monitor the workflow using `show` or `status`<br/>
`MoveTables --workflow <workflow> --target-keyspace <target-keyspace> show`<br/>
`MoveTables --workflow <workflow> --target-keyspace <target-keyspace> status`<br/>
1. Confirm that data has been copied over correctly using [VDiff](../vdiff)
1. Cutover to the target keyspace with `switchtraffic`<br/>
`MoveTables --workflow <workflow> --target-keyspace <target-keyspace> switchtraffic`
1. Cleanup vreplication artifacts and source tables with `complete`<br/>
`MoveTables --workflow <workflow> --target-keyspace <target-keyspace> complete`

## Common Use Cases for MoveTables

### Adopting Vitess

For those wanting to try out Vitess for the first time, `MoveTables` provides an easy way to route part of their workload to Vitess with the ability to migrate back at any time without any risk. You point a vttablet to your existing MySQL installation, spin up an unsharded Vitess cluster and use a `MoveTables` workflow to start serving some tables from Vitess. You can also go further and use a Reshard workflow to experiment with a sharded version of a part of your database.

See this [user guide](../../../user-guides/configuration-advanced/unmanaged-tablet/#move-legacytable-to-the-commerce-keyspace) for detailed steps.

### Vertical Sharding

For existing Vitess users you can easily move one or more tables to another keyspace, either for balancing load or as preparation for sharding your tables.

See this [user guide](../../../user-guides/migration/move-tables/) which describes how `MoveTables` works in the local example provided in the Vitess repo.

## Parameters

### Action

[`MoveTables`](../../programs/vtctldclient/vtctldclient_movetables/) is an "umbrella" command. The [`action` or sub-command](../../programs/vtctldclient/vtctldclient_movetables/#see-also) defines the operation on the workflow.

#### Create
<div class="cmd">

[`create`](../../programs/vtctldclient/vtctldclient_movetables/vtctldclient_movetables_create/) sets up and creates a new workflow. The workflow name should not conflict with that of an existing workflow.

</div>

#### Show
<div class="cmd">

[`show`](../../programs/vtctldclient/vtctldclient_movetables/vtctldclient_movetables_show/) displays useful information about a workflow – including recent logs.

</div>

#### Status
<div class="cmd">

[`status`](../../programs/vtctldclient/vtctldclient_movetables/vtctldclient_movetables_status/) (or `progress`) reports the progress of a workflow by showing the percentage of data copied across targets, if workflow is in copy state, and the replication lag between the target and the source once the copy phase is completed. It also shows the current state of traffic for the tables involved in the workflow.

It is too expensive to get real-time row counts of tables, using _count(*)_, say. So we use the statistics available in the `information_schema` to approximate copy progress. This data can be significantly off (up to 50-60%) depending on the utilization of the underlying mysql server resources. You can manually run `ANALYZE TABLE` to update the statistics if so desired.

</div>

#### SwitchTraffic
<div class="cmd">

[`switchtraffic`](../../programs/vtctldclient/vtctldclient_movetables/vtctldclient_movetables_switchtraffic/) switches traffic forward for the `tablet-types` specified. You can switch all traffic with just one command, and this is the default behavior. Note that you can now switch replica, rdonly, and primary traffic in any order.

{{< info >}}
Note that VTGate can [buffer queries](../../features/vtgate-buffering/) when switching traffic which can virtually eliminate any visible impact on application users.
{{</ info >}}

</div>

#### ReverseTraffic
<div class="cmd">

[`reversetraffic`](../../programs/vtctldclient/vtctldclient_movetables/vtctldclient_movetables_reversetraffic/) switches traffic in the reverse direction for the `tablet-types` specified. The traffic should have been previously switched forward using `SwitchTraffic` for the `cells` and `tablet-types` specified.

{{< info >}}
Note that VTGate can [buffer queries](../../features/vtgate-buffering/) when switching traffic which can virtually eliminate any visible impact on application users.
{{</ info >}}

</div>

#### Cancel
<div class="cmd">

[`cancel`](../../programs/vtctldclient/vtctldclient_movetables/vtctldclient_movetables_cancel/) can be used if a workflow was created in error or was misconfigured and you prefer to create a new workflow instead of fixing this one. `cancel` can only be called if no traffic has been switched. It removes vreplication-related artifacts like rows from the vreplication and copy_state tables in the sidecar `_vt` database along with routing rules and blacklisted tables from the topo and, by default, the target tables on the target keyspace
(see `--keep-data` and `--rename-tables`).

</div>

#### Complete
<div class="cmd">

{{< warning >}}
This is a destructive command
{{< /warning >}}

[`complete`](../../programs/vtctldclient/vtctldclient_movetables/vtctldclient_movetables_complete/) is used after all traffic has been switched. It removes vreplication-related artifacts like rows from vreplication and copy_state tables in the sidecar `_vt` database along with routing rules and and blocklisted tables from the topo. By default, the source tables are also dropped on the target keyspace
(see `--keep-data` and `--rename-tables`).

</div>

### Options

Each [`action` or sub-command](../../programs/vtctldclient/vtctldclient_movetables/#see-also) has additional options/parameters that can be used to modify its behavior. Please see the [command's reference docs](../../programs/vtctldclient/vtctldclient_movetables/) for the full list of command options or flags. Below we will add additional information for a subset of key options.

#### --auto-start
**optional**\
**default** true

<div class="cmd">

Normally the workflow starts immediately after it is created. If this flag is set
to false then the workflow is in a Stopped state until you explicitly start it.

</div>

###### Uses

* Allows updating the rows in `_vt.vreplication` after `MoveTables` has setup the
streams. For example, you can add some filters to specific tables or change the
projection clause to modify the values on the target. This
provides an easier way to create simpler Materialize workflows by first using
`MoveTables` with auto_start false, updating the BinlogSource as required by your
`Materialize` and then start the workflow.
* Changing the `copy_state` and/or `pos` values to restart a broken `MoveTables` workflow
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

#### --initialize-target-sequences
**optional**\
**default** false

<div class="cmd">

If specified, when switching write (primary tablet) traffic for tables that are being moved from an unsharded keyspace to a
sharded one, initialize any sequences being used by those tables on the target. They are initialized using the current
maximum value for the column across all shards on the target.

</div>

###### Uses

* It's common that users import unsharded data into Vitess — sharding it in the process — or move
tables from an unsharded keyspace to a sharded one as they become too large for a single MySQL instance.
When doing either of these you would typically be leveraging [MySQL auto_increment](https://dev.mysql.com/doc/refman/en/example-auto-increment.html)
columns for primary keys on the unsharded tables (source). On the sharded target, however, you will then
need to use [Vitess Sequences](../../features/vitess-sequences/) in order to ensure that you continue having
automatically generated incrementing unique primary keys _across all shards_. When it comes to [switching the write traffic](#switchtraffic)
during this move you would need to manually ensure that you [initialize the sequences](../../features/vitess-sequences/#initializing-a-sequence)
so that the next values they provide are higher than any already used on the source (with ample buffer in between
to avoid potential identifier reuse and duplicate key errors immediately following the cutover). This flag tells Vitess
to manage this sequence initialization for you as part of the `SwitchTraffic` operation to ensure a seamless cutover
without any additional manual steps. For more information, please see [the feature request](https://github.com/vitessio/vitess/issues/13685).

{{< info >}}
You will still need to take the manual step of [creating each backing sequence table](../../features/vitess-sequences/#creating-a-sequence)
in an unsharded keyspace of your choosing prior to the `SwitchTraffic` operation.
{{< /info>}}

#### --max-replication-lag-allowed
**optional**\
**default**  the value used for [`--timeout`](#--timeout)

<div class="cmd">

While executing `SwitchTraffic` we ensure that the VReplication lag for the workflow is less than this duration, otherwise report an error and don't attempt the switch. The calculated VReplication lag is the estimated maximum lag across workflow streams between the last event seen at the source and the last event processed by the target (which would be a heartbeat event if we're fully caught up). Usually, when VReplication has caught up, this lag should be very small (under a second).

While switching write traffic, we temporarily make the source databases read-only, and wait for the targets to catchup. This means that the application can effectively be partially down for this cutover period as writes will pause or error out. While switching write traffic this flag can ensure that you only switch traffic if the current lag is low, thus limiting this period of write-unavailability and avoiding it entirely if we're not likely to catch up within the [`--timeout`](#--timeout)) window.

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

#### --no-routing-rules
**optional**\
**default** false

<div class="cmd">
Do not create routing rules for the tables being moved when the workflow is created. This implies that you should
not use global routing or send traffic to the target keyspace through a vtgate.
See https://github.com/vitessio/vitess/pull/13895 and https://github.com/vitessio/vitess/issues/13851 for a use-case
and more details.
</div>

#### --rename-tables
**optional**\
**default** false

<div class="cmd">

During `Complete` or `Cancel` operations, the tables are renamed instead of being deleted. Currently the new name is _&lt;table_name&gt;_old.

We use the same renaming logic used by [`pt-online-schema-change`](https://docs.percona.com/percona-toolkit/pt-online-schema-change.html).
Such tables are automatically skipped by VReplication if they exist on the source.

</div>

#### --enable-reverse-replication
**optional**\
**default** true

<div class="cmd">

`SwitchTraffic` for primary tablet types, by default, starts a reverse replication stream with the current target as the source, replicating back to the original source. This enables a quick and simple rollback mechanism using `ReverseTraffic`. This reverse workflow name is that of the original workflow concatenated with \_reverse.

If set to false these reverse replication streams will not be created and you will not be able to rollback once you have switched write traffic over to the target.

</div>

#### --source-time-zone
**optional**\
**default** ""

<div class="cmd">

Specifying this flag causes all `DATETIME` fields to be converted from the given time zone into `UTC`. It is expected that the application has
stored *all* `DATETIME` fields, in all tables being moved, in the specified time zone. On the target these `DATETIME` values will be stored in `UTC`.

As a best practice, Vitess expects users to run their MySQL servers in `UTC`. So we do not specify a target time zone for the conversion.
It is expected that the [time zone tables have been pre-populated](https://dev.mysql.com/doc/refman/en/time-zone-support.html#time-zone-installation) on the target mysql servers. 

Any reverse replication streams running after a SwitchWrites will do the reverse date conversion on the source.

Note that selecting the `DATETIME` columns from the target will now give the times in UTC. It is expected that the application will
perform any conversions using, for example, `SET GLOBAL time_zone = 'US/Pacific'`or `convert_tz()`.

Also note that only columns of `DATETIME` data types are converted. If you store `DATETIME` values as `VARCHAR` or `VARBINARY` strings,
setting this flag will not convert them. 

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
will stop once the copy is done and you can then mark the workflow as `Complete`.

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

### More Reading

* [`MoveTables` in practice](../../../concepts/move-tables/)
* [`MoveTables` reference docs](../../programs/vtctldclient/vtctldclient_movetables/)
