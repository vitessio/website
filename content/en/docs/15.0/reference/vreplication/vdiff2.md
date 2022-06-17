---
title: VDiff2
description: Compare the source and target in a workflow to ensure integrity
weight: 40
---

{{< warning >}}
This is the new _experimental_ version of VDiff which runs on `vttablets` as compared with [VDiff1](../vdiff/) which runs on `vtctld`.
{{< /warning >}}

{{< info >}}
Even before it's marked as production-ready (feature complete and tested widely in 1+ releases), it should be safe to use and is likely to provide much better results for very large tables. It also offers the ability to resume a VDiff that may have encountered an error which is extremely helpful when working with very large tables.
{{< /info >}}

For additional details, please see the [RFC](https://github.com/vitessio/vitess/issues/10134) and the [README](https://github.com/vitessio/vitess/tree/main/go/vt/vttablet/tabletmanager/vdiff/README.md).

### Command

VDiff2 takes different sub-commands or actions similar to how the [`MoveTables`](../movetables/)/[`Reshard`](../reshard/) commands work. The first argument
is the <keyspace.workflow> followed by <action>. The following actions are supported:

#### Start a new VDiff

These take the same parameters as VDiff1 and schedule VDiff to run on the primary tablet of each target shard to verify
the subset of data that will live on the given shard. Please note that if you do not specify a sub-command or action
then `create` is assumed (this eases the transition from VDiff1 to VDiff2). If you do not pass a specific UUID then one
will be generated.

```
VDiff -- --v2 [-source_cell=<cell>] [--target_cell=<cell>] [--tablet_types=in_order:RDONLY,REPLICA,PRIMARY]
       [--limit=<max rows to diff>] [--tables=<table list>] [--format=json] [--max_extra_rows_to_compare=1000]
       [--filtered_replication_wait_time=30s] [--debug_query] [--only_pks] <keyspace.workflow>  create [<uuid>]
```

Each scheduled VDiff has an associated VDiff UUID which is returned by the `create` action. You can use it
to monitor progress. Example:

```
$ vtctlclient --server=localhost:15999 VDiff -- --v2 customer.commerce2customer
VDiff bf9dfc5f-e5e6-11ec-823d-0aa62e50dd24 scheduled on target shards, use show to view progress
```

#### Resume a previous VDiff

This allows you to explicitly resume an existing VDiff workflow. VDiff will then resume, picking up where it left off and comparing the records where the Primary Key column(s) are greater than the last record processed — with the progress and other status information saved when the run ends. This allows you to:
  1. Resume a VDiff that may have encountered an ephemeral error
  2. Do approximate rolling or differential VDiffs (e.g. done after MoveTables finishes the initial copy phase and then again just before SwitchTraffic)

```
VDiff -- --v2 [-source_cell=<cell>] [--target_cell=<cell>] [--tablet_types=in_order:RDONLY,REPLICA,PRIMARY]
       [--limit=<max rows to diff>] [--tables=<table list>] [--format=json] [--max_extra_rows_to_compare=1000]
       [--filtered_replication_wait_time=30s] [--debug_query] [--only_pks] <keyspace.workflow> resume <uuid>
```

Example:

```
$ vtctlclient --server=localhost:15999 VDiff -- --v2 customer.commerce2customer resume 4c664dc2-eba9-11ec-9ef7-920702940ee0
VDiff 4c664dc2-eba9-11ec-9ef7-920702940ee0 resumed on target shards, use show to view progress
```

#### Show progress/status of a VDiff

```
VDiff  -- --v2  <keyspace.workflow> show [<uuid> | last | all]
```

You can either show a specific UUID or use the `last` convenience shorthand to look at the most recently created VDiff. Example:

```
$ vtctlclient --server=localhost:15999 VDiff -- --v2 customer.commerce2customer show last

VDiff Summary for customer.commerce2customer (4c664dc2-eba9-11ec-9ef7-920702940ee0)
State: completed
RowsCompared: 196
CompletedAt:  2022-06-17 14:37:25
HasMismatch:  false

Use "--format=json" for more detailed output.

$ vtctlclient --server=localhost:15999 VDiff -- --v2 --format=json customer.commerce2customer show last
{
	"Workflow": "commerce2customer",
	"Keyspace": "customer",
	"State": "completed",
	"UUID": "4c664dc2-eba9-11ec-9ef7-920702940ee0",
	"RowsCompared": 196,
	"HasMismatch": false,
	"Shards": "0",
	"CompletedAt": "2022-06-17 14:37:25"
}
```

`show all` lists all vdiffs created for the specified keyspace and workflow.

### Description

VDiff does a row by row comparison of all tables associated with the workflow, diffing the
source keyspace and the target keyspace and reporting counts of missing/extra/unmatched rows.

It is highly recommended that you do this before you finalize a workflow with `SwitchTraffic`.

The actions supported

### Parameters

#### --source_cell
**optional**\
**default** all

<div class="cmd">
VDiff will choose a tablet from this cell to diff the source tables with the target tables
</div>

#### --target_cell
**optional**\
**default** all

<div class="cmd">
VDiff will choose a tablet from this cell to diff the target tables with the source tables
</div>

#### --tablet_types
**optional**\
**default** in_order:RDONLY,REPLICA,PRIMARY

<div class="cmd">
A comma separated list of tablet types that are used while picking a tablet for sourcing data.
One or more from PRIMARY, REPLICA, RDONLY.<br><br>
</div>

#### --filtered_replication_wait_time
**optional**\
**default** 30s

<div class="cmd">
VDiff finds the current position of the source primary and then waits for the target replication to reach
that position for `--filtered_replication_wait_time`. If the target is much behind the source or if there is
a high write qps on the source then this time will need to be increased.
</div>

#### --limit
**optional**\
**default** 9223372036854775807

<div class="cmd">
Maximum number of rows to run vdiff on (across all tables specified).
This limit is usually set while diffing a large table as a quick consistency check.
</div>

#### --tables
**optional**\
**default** all tables in the workflow

<div class="cmd">
A comma separated list of tables to run vdiff on.
</div>

#### --format
**optional**\
**default** unstructured text output

<div class="cmd">
Only other format supported is json
</div>

#### --max_extra_rows_to_compare
**optional**\
**default** 1000

<div class="cmd">
Limits the number of extra rows on both the source and target that we will perform a second compare pass on to confirm that the rows are in fact different in content and not simply returned in a different order on the source and target (which can happen when there are collation differences, e.g. different MySQL versions).
</div>

#### --debug_query
**optional**

<div class="cmd">
Adds the MySQL query to the report that can be used for further debugging
</div>

#### --only_pks
**optional**

<div class="cmd">
When reporting missing rows, only show primary keys in the report.
</div>

#### keyspace.workflow
**mandatory**

<div class="cmd">
Name of target keyspace and the associated workflow to run VDiff on.
</div>
