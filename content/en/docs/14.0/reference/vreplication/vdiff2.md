---
title: VDiff2
description: Compare the source and target in a workflow to ensure integrity
weight: 40
---

_Experimental_ version of VDiff which run on tablets as compared with VDiff1 (./vdiff.md) which runs on `vtctld`.

NOTE: even before it's marked as production-ready (feature complete and tested widely in 1+ releases), it should be safe to use and is likely to provide much better results for very large tables.

For additional details, please see the [RFC](https://github.com/vitessio/vitess/issues/10134) and the [README](https://github.com/vitessio/vitess/tree/main/go/vt/vttablet/tabletmanager/vdiff/README.md).

### Command

VDiff2 takes different sub-commands similar to how MoveTables/Reshard work. The first argument
is the <keyspace.workflow> followed by <action>. The following actions are supported:

#### Start a new vdiff

These take the same parameters as VDiff1 and schedule vdiff to run on the primary of each target shard to verify
data that will be part of that shard.

```
VDiff  -- --v2 [-source_cell=<cell>] [-target_cell=<cell>] [-tablet_types=primary,replica,rdonly]
       [-limit=<max rows to diff>] [-tables=<table list>] [-format=json]
       [-filtered_replication_wait_time=30s] [-debug_query] [-only_pks] <keyspace.workflow>  Create
```

Each scheduled VDiff has an associated VDiff uuid which is returned by the Create command. You can use it
to monitor progress. Example:

```
$ vtctlclient --server=localhost:15999 VDiff -- --v2 customer.commerce2customer
VDiff bf9dfc5f-e5e6-11ec-823d-0aa62e50dd24 scheduled on target shards, use show to view progress
```

#### Show progress/status of a vdiff

```
VDiff  -- --v2  <keyspace.workflow> Show [<vdiff uuid> | last | all]

```

You can either Show a specific uuid or use the `last` convenience shortcut to look at the most recent created vdiff. Example:

```
$ vtctlclient --server=localhost:15999 VDiff -- --v2 customer.commerce2customer show last

VDiff Summary for customer.commerce2customer (bf9dfc5f-e5e6-11ec-823d-0aa62e50dd24)
State: completed
HasMismatch: false

Use "--format=json" for more detailed output.

$ vtctlclient --server=localhost:15999 VDiff -- --v2 --format=json customer.commerce2customer show last
{
	"Workflow": "commerce2customer",
	"Keyspace": "customer",
	"State": "completed",
	"UUID": "bf9dfc5f-e5e6-11ec-823d-0aa62e50dd24",
	"HasMismatch": false,
	"Shards": "0"
}
```


`Show all` shows all vdiffs created for the specified keyspace and workflow.

### Description

VDiff does a row by row comparison of all tables associated with the workflow, diffing the
source keyspace and the target keyspace and reporting counts of missing/extra/unmatched rows.

It is highly recommended that you do this before you finalize a workflow with `SwitchTraffic`.

The actions supported

### Parameters

#### -source_cell
**optional**\
**default** all

<div class="cmd">
VDiff will choose a tablet from this cell to diff the source table(s) with the target tables
</div>

#### -target_cell
**optional**\
**default** all

<div class="cmd">
VDiff will choose a tablet from this cell to diff the source table(s) with the target tables
</div>

#### -tablet_types
**optional**\
**default** primary,replica,rdonly

<div class="cmd">
A comma separated list of tablet types that are used while picking a tablet for sourcing data.
One or more from PRIMARY, REPLICA, RDONLY.<br><br>
</div>

#### -filtered_replication_wait_time
**optional**\
**default** 30s

<div class="cmd">
VDiff finds the current position of the source primary and then waits for the target replication to reach
that position for _filtered_replication_wait_time_. If the target is much behind the source or if there is
a high write qps on the source then this time will need to be increased.
</div>

#### -limit
**optional**\
**default** 9223372036854775807

<div class="cmd">
Maximum number of rows to run vdiff on (across all tables specified).
This limit is usually set while diffing a large table as a quick consistency check.
</div>

#### -tables
**optional**\
**default** all tables in the workflow

<div class="cmd">
A comma separated list of tables to run vdiff on.
</div>


#### -format
**optional**\
**default** unstructured text output

<div class="cmd">
Only other format supported is json
</div>

#### -debug_query
**optional**\

<div class="cmd">
Adds a MySQL query to the report that can be used for further debugging
</div>

#### -only_pks
**optional**\

<div class="cmd">
When reporting missing rows, only show primary keys in the report.
</div>

#### keyspace.workflow
**mandatory**

<div class="cmd">
Name of target keyspace and the associated workflow to run VDiff on.
</div>
