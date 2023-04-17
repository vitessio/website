---
title: VDiff
description: Compare the source and target in a workflow to ensure integrity
weight: 40
aliases: ['/docs/reference/vreplication/vdiff2/']
---

{{< info >}}
This is VDiff v2 which runs on `vttablets` as compared with the legacy [VDiff v1](../vdiffv1/) which runs on `vtctld`.
{{< /info >}}

### Command

VDiff takes different sub-commands or actions similar to how the [`MoveTables`](../movetables/)/[`Reshard`](../reshard/) commands work. The first argument
is the &lt;keyspace.workflow&gt; followed by an &lt;action&gt;. The following actions are supported:

#### Start a New VDiff

These take the same parameters as VDiff1 and schedule VDiff to run on the primary tablet of each target shard to verify the subset of data that will live on the given shard. Please note that if you do not specify a sub-command or action then `create` is assumed (this eases the transition from VDiff1 to VDiff2). If you do not pass a specific UUID then one will be generated.

```
VDiff -- [--source_cell=<cell>] [--target_cell=<cell>] [--tablet_types=in_order:RDONLY,REPLICA,PRIMARY]
       [--limit=<max rows to diff>] [--tables=<table list>] [--format=json] [--auto-retry] [--verbose] [--max_extra_rows_to_compare=1000]
       [--update-table-stats] [--filtered_replication_wait_time=30s] [--debug_query] [--only_pks] [--wait] [--wait-update-interval=1m]
       <keyspace.workflow> create [<UUID>]
```

Each scheduled VDiff has an associated UUID which is returned by the `create` action. You can use it
to monitor progress. Example:

```
$ vtctlclient --server=localhost:15999 VDiff -- customer.commerce2customer
VDiff bf9dfc5f-e5e6-11ec-823d-0aa62e50dd24 scheduled on target shards, use show to view progress
```

#### Resume a Previous VDiff

The `resume` action allows you to resume a previously completed VDiff, picking up where it left off and comparing the records where the Primary Key column(s) are greater than the last record processed — with the progress and other status information saved when the run ends. This allows you to do approximate rolling or differential VDiffs (e.g. done after MoveTables finishes the initial copy phase and then again just before SwitchTraffic).

```
VDiff -- [--source_cell=<cell>] [--target_cell=<cell>] [--tablet_types=in_order:RDONLY,REPLICA,PRIMARY]
       [--limit=<max rows to diff>] [--tables=<table list>] [--format=json] [--auto-retry] [--verbose] [--max_extra_rows_to_compare=1000]
       [--update-table-stats] [--filtered_replication_wait_time=30s] [--debug_query] [--only_pks] [--wait] [--wait-update-interval=1m]
       <keyspace.workflow> resume <UUID>
```

Example:

```
$ vtctlclient --server=localhost:15999 VDiff -- customer.commerce2customer resume 4c664dc2-eba9-11ec-9ef7-920702940ee0
VDiff 4c664dc2-eba9-11ec-9ef7-920702940ee0 resumed on target shards, use show to view progress
```

{{< warning >}}
We cannot guarantee accurate results for `resume` when different collations are used for a table between the source and target keyspaces (more details can be seen [here](https://github.com/vitessio/vitess/pull/10497)).
{{< /warning >}}

#### Show Progress/Status of a VDiff

```
VDiff -- <keyspace.workflow> show {<UUID> | last | all}
```

You can either `show` a specific UUID or use the `last` convenience shorthand to look at the most recently created VDiff. Example:

```
$ vtctlclient --server=localhost:15999 VDiff -- customer.commerce2customer show last

VDiff Summary for customer.commerce2customer (4c664dc2-eba9-11ec-9ef7-920702940ee0)
State:        completed
RowsCompared: 196
HasMismatch:  false
StartedAt:    2022-06-26 22:44:29
CompletedAt:  2022-06-26 22:44:31

Use "--format=json" for more detailed output.

$ vtctlclient --server=localhost:15999 VDiff -- --format=json customer.commerce2customer show last
{
	"Workflow": "commerce2customer",
	"Keyspace": "customer",
	"State": "completed",
	"UUID": "4c664dc2-eba9-11ec-9ef7-920702940ee0",
	"RowsCompared": 196,
	"HasMismatch": false,
	"Shards": "0",
	"StartedAt": "2022-06-26 22:44:29",
	"CompletedAt": "2022-06-26 22:44:31"
}

$ vtctlclient --server=localhost:15999 VDiff -- --format=json customer.p1c2 show daf1f03a-03ed-11ed-9ab8-920702940ee0
{
	"Workflow": "p1c2",
	"Keyspace": "customer",
	"State": "started",
	"UUID": "daf1f03a-03ed-11ed-9ab8-920702940ee0",
	"RowsCompared": 51,
	"HasMismatch": false,
	"Shards": "-80,80-",
	"StartedAt": "2022-07-15 03:26:03",
	"Progress": {
		"Percentage": 48.57,
		"ETA": "2022-07-15 03:26:10"
	}
}
```

`show all` lists all VDiffs created for the specified keyspace and workflow.

{{< info >}}
It is too expensive to get exact real-time row counts for tables, using e.g. `SELECT COUNT(*)`.
So we instead use the statistics available in the
[`information_schema`](https://dev.mysql.com/doc/refman/en/information-schema-tables-table.html)
to approximate the number of rows in each table when initializing a VDiff on the target
primary tablet(s). This data is then used in the progress report and it can be significantly
off (up to 50-60+%) depending on the utilization of the underlying MySQL server resources and
the age of the tables. You can manually run
[`ANALYZE TABLE`](https://dev.mysql.com/doc/refman/en/analyze-table.html) to update the
statistics for the tables involved on the target primary tablet(s) before creating the
VDiff, if so desired, in order to improve the accuracy of the progress report.
{{< /info >}}

#### Stopping a VDiff

```
VDiff -- <keyspace.workflow> stop <UUID>
```

The `stop` action allows you to stop a running VDiff for any reason — for example, the load on the system(s) may be too high at the moment and you want to postpone the work until off hours. You can then later use the `resume` action to start the VDiff again from where it left off. Example:

```
$ vtctlclient --server=localhost:15999 VDiff -- --format=json customer.commerce2customer stop ad9bd40e-0c92-11ed-b568-920702940ee0
{
	"UUID": "ad9bd40e-0c92-11ed-b568-920702940ee0",
	"Action": "stop",
	"Status": "completed"
}
```

{{< info >}}
Attempting to `stop` a VDiff that is already completed is a no-op.
{{< /info >}}

#### Delete VDiff Results

```
VDiff -- <keyspace.workflow> delete {<UUID> | all}
```

You can either `delete` a specific UUID or use the `all` shorthand to delete all VDiffs created for the specified keyspace and workflow. Example:

```
$ vtctlclient --server=localhost:15999 VDiff -- customer.commerce2customer delete all
VDiff delete status is completed on target shards

$ vtctlclient --server=localhost:15999 VDiff -- --format=json customer.commerce2customer delete all
{
	"Action": "delete",
	"Status": "completed"
}
```

{{< info >}}
Deletes are idempotent, so attempting to `delete` VDiff data that does not exist is a no-op.

All VDiff data associated with a VReplication workflow is deleted when the workflow is deleted.
{{< /info >}}

### Description

VDiff does a row by row comparison of all tables associated with the workflow, diffing the
source keyspace and the target keyspace and reporting counts of missing/extra/unmatched rows.

It is highly recommended that you do this before you finalize a workflow with `SwitchTraffic`.

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
that position for --filtered_replication_wait_time. If the target is much behind the source or if there is
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
**default** text (unstructured text output)

<div class="cmd">
Only other format supported is JSON
</div>

#### --auto-retry
**optional**\
**default** true

<div class="cmd">
Automatically retry vdiffs that end with an error
</div>

#### --verbose
**optional**

<div class="cmd">
Show verbose vdiff output in summaries
</div>

#### --wait
**optional**

<div class="cmd">
When creating or resuming a vdiff, wait for the vdiff to finish before exiting. This will print the current status of the vdiff every --wait-update-interval.
</div>

#### --wait-update-interval
**optional**\
**default** 1m (1 minute)

<div class="cmd">
When waiting for a vdiff to finish, check and display the current status this often.
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

#### --update-table-stats
**optional**

<div class="cmd">
When specified, ANALYZE TABLE is run on each table in the target keyspace when initializing the VDiff. This helps to ensure that the table statistics are
up-to-date and thus that the progress reporting is as accurate as possible.
</div>

{{< warning >}}
[`ANALYZE TABLE`](https://dev.mysql.com/doc/refman/en/analyze-table.html) takes a table level READ lock on the table while it runs — effectively making the
table read-only. While [`ANALYZE TABLE`](https://dev.mysql.com/doc/refman/en/analyze-table.html) does not typically take very long to run it can still
potentially interfere with serving queries from the *target* keyspace.
{{< /warning >}}

#### keyspace.workflow
**mandatory**

<div class="cmd">
Name of target keyspace and the associated workflow to run VDiff on.
</div>
