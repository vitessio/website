---
title: MoveTables
description: Move tables between keyspaces without downtime
weight: 10
---

{{< info >}}
Starting with Vitess 11.0 you should use the [VReplication v2 commands](../../movetables)
{{< /info >}}

### Command

```
MoveTables -- --v1 [--cells=<cells>] [--tablet_types=<source_tablet_types>] --workflow=<workflow>
            [--all] [--exclude=<tables>]  [--auto_start] [--stop_after_copy] [--on-ddl=<action>]
            <source_keyspace> <target_keyspace> <table_specs>
```

### Description

MoveTables is used to start a workflow to move one or more tables from an external database or an existing Vitess keyspace into a new Vitess keyspace.
The target keyspace can be unsharded or sharded.

MoveTables is used typically for migrating data into Vitess or to implement vertical sharding. You might use the former when you
first start using Vitess and the latter if you want to distribute your load across servers.

### Parameters

#### --cells
**optional**\
**default** local cell

<div class="cmd">

A comma-separated list of cell names or cell aliases. This list is used by VReplication to determine which
cells should be used to pick a tablet for selecting data from the source keyspace.<br><br>

###### Uses

* Improve performance by using picking a tablet in cells in network proximity with the target
* To reduce bandwidth costs by skipping cells that are in different availability zones
* Select cells where replica lags are lower
</div>

#### --tablet_types
**optional**\
**default** replica

<div class="cmd">

A comma-separated list of tablet types that are used while picking a tablet for sourcing data.
One or more from PRIMARY, REPLICA, RDONLY.<br><br>

###### Uses

* To reduce the load on PRIMARY tablets by using REPLICAs or RDONLYs
* Reducing lags by pointing to PRIMARY
</div>

#### workflow
**mandatory**
<div class="cmd">

Unique name for the MoveTables-initiated workflow, used in later commands to refer back to this workflow

</div>

#### source_keyspace
**mandatory**
<div class="cmd">

Name of existing keyspace that contains the tables to be moved

</div>

#### target_keyspace
**mandatory**
<div class="cmd">

Name of existing keyspace to which the tables will be moved

</div>

#### table_specs
**optional**  one of `table_specs` or `--all` needs to be specified
<div class="cmd">

_Either_

* a comma-separated list of tables
  * if target keyspace is unsharded OR
  * if target keyspace is sharded AND the tables being moved are already defined in the target's vschema

  Example: `MoveTables -workflow=commerce2customer commerce customer customer,corder`

_Or_

* the JSON table section of the vschema for associated tables
  * if target keyspace is sharded AND
  * tables being moved are not yet present in the target's vschema

  Example: `MoveTables -- --workflow=commerce2customer commerce customer '{"t1":{"column_vindexes": [{"column": "id", "name": "hash"}]}}}'`

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

###### Uses
* allows updating the rows in `_vt.vreplication` after MoveTables has setup the
streams. For example, you can add some filters to specific tables or change the
projection clause to modify the values on the target. This
provides an easier way to create simpler Materialize workflows by first using
MoveTables with auto_start false, updating the BinlogSource as required by your
Materialize and then start the workflow.
* changing the `copy_state` and/or `pos` values to restart a broken MoveTables workflow
from a specific point of time.

</div>

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

### A MoveTables Workflow

Once you select the set of tables to move from one keyspace to another you need to initiate a VReplication workflow as follows:

1. Initiate the migration using MoveTables
2. Monitor the workflow using [Workflow](../../workflow)
3. Confirm that data has been copied over correctly using [VDiff](../../vdiff)
4. Start the cutover by routing all reads from your application to those tables using [SwitchReads](../switchreads)
5. Complete the cutover by routing all writes using [SwitchWrites](../switchwrites)
6. Optionally clean up the source tables using [DropSources](../dropsources)


### Common use cases for MoveTables

#### Adopting Vitess

For those wanting to try out Vitess for the first time, MoveTables provides an easy way to route part of their workload
to Vitess with the ability to migrate back at any time without any risk. You point a vttablet to your existing MySQL installation,
spin up an unsharded Vitess cluster and use a MoveTables workflow to start serving some tables from Vitess. You can also go
further and use a Reshard workflow to experiment with a sharded version of a part of your database.

See [user guide](../../../../user-guides/configuration-advanced/unmanaged-tablet/#move-legacytable-to-the-commerce-keyspace) for detailed steps

#### Vertical Sharding

For existing Vitess users you can easily move one or more tables to another keyspace, either for balancing load or
as preparation for sharding your tables.

See [user guide](../../../../user-guides/migration/move-tables/) which describes how MoveTables works in the local example provided
in the Vitess repo.

#### More Reading

* [MoveTables in practice](../../../../concepts/move-tables/)
