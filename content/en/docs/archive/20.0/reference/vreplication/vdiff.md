---
title: VDiff
description: Compare the source and target in a workflow to ensure integrity
weight: 40
aliases: ['/docs/reference/vreplication/vdiff2/']
---

### Description

VDiff does a row by row comparison of all tables associated with the workflow, diffing the
source keyspace and the target keyspace and reporting counts of missing/extra/unmatched rows.

It is highly recommended that you do this before you finalize a workflow with `SwitchTraffic` and `complete`.

{{< warning >}}
VDiff supports diffing tables without a defined [Primary Key (PK)](https://dev.mysql.com/doc/refman/en/primary-key-optimization.html)
and it will use a Primary Key equivalent (PKE: index on non-NULL unique column(s)) if one exists.
However, be aware of the additional overhead and time required to do the comparison in these
cases, particularly if there is no PK _or_ PKE as diffing the table will then require a full table
scan to read every row and a filesort to sort all of them before the diff can start (and this will
have to be done every time it's restarted/resumed). If the table is of any significant size then
it's strongly recommended that you define a PK for the table.
{{</ warning >}}

### Command

VDiff takes different sub-commands or actions similar to how the [`MoveTables`](../movetables/)/[`Reshard`](../reshard/) commands work. Please see [the command's reference docs](../../../reference/programs/vtctldclient/vtctldclient_vdiff/) for additional info. The following sub-commands or actions are supported:

#### Start a New VDiff

The [`create` action](../../../reference/programs/vtctldclient/vtctldclient_vdiff/vtctldclient_vdiff_create/) schedules a VDiff to run on the primary tablet of each target shard to verify the subset of data that will live on the given shard. If you do not pass a specific UUID then one will be generated.

Each scheduled VDiff has an associated UUID which is returned by the `create` action. You can use it
to monitor progress. Example:

```shell
$ vtctldclient --server=localhost:15999 VDiff --target-keyspace customer --workflow commerce2customer create
VDiff a35b0006-e6d9-416e-bea9-917795dc5bf3 scheduled on target shards, use show to view progress
```

#### Resume a Previous VDiff

The [`resume` action](../../../reference/programs/vtctldclient/vtctldclient_vdiff/vtctldclient_vdiff_resume/) allows you to resume a previously completed VDiff, picking up where it left off and comparing the records where the Primary Key column(s) are greater than the last record processed — with the progress and other status information saved when the run ends. This allows you to do approximate rolling or differential VDiffs (e.g. done after `MoveTables` finishes the initial copy phase and then again just before `SwitchTraffic`).

Example:

```shell
$ vtctldclient --server=localhost:15999 VDiff --target-keyspace customer --workflow commerce2customer resume 4c664dc2-eba9-11ec-9ef7-920702940ee0
VDiff 4c664dc2-eba9-11ec-9ef7-920702940ee0 resumed on target shards, use show to view progress
```

{{< warning >}}
We cannot guarantee accurate results for `resume` when different collations are used for a table between the source and target keyspaces (more details can be seen [here](https://github.com/vitessio/vitess/pull/10497)).
{{< /warning >}}

#### Show Progress/Status of a VDiff

Using the [`show` action](../../../reference/programs/vtctldclient/vtctldclient_vdiff/vtctldclient_vdiff_show/) you can either `show` a specific UUID or use the `last` convenience shorthand to look at the most recently created VDiff. Example:

```shell
$ vtctldclient --server=localhost:15999 VDiff --target-keyspace customer --workflow commerce2customer show last

VDiff Summary for customer.commerce2customer (4c664dc2-eba9-11ec-9ef7-920702940ee0)
State:        completed
RowsCompared: 196
HasMismatch:  false
StartedAt:    2022-06-26 22:44:29
CompletedAt:  2022-06-26 22:44:31

Use "--format=json" for more detailed output.

$ vtctldclient --server=localhost:15999 VDiff --format=json --target-keyspace customer --workflow commerce2customer show last
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

$ vtctldclient --server=localhost:15999 VDiff --format=json --target-keyspace customer --workflow p1c2 show daf1f03a-03ed-11ed-9ab8-920702940ee0
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
the age of the tables. You can specify the `create` `--update-table-stats` flag so that VDiff
will run [`ANALYZE TABLE`](https://dev.mysql.com/doc/refman/en/analyze-table.html) to update the
statistics for the tables involved on the target primary tablet(s) before executing the
VDiff in order to improve the accuracy of the progress report.
{{< /info >}}

#### Stopping a VDiff

The [`stop` action](../../../reference/programs/vtctldclient/vtctldclient_vdiff/vtctldclient_vdiff_stop/) allows you to stop a running VDiff for any reason — for example, the load on the system(s) may be too high at the moment and you want to postpone the work until off hours. You can then later use the [`resume` action](../../../reference/programs/vtctldclient/vtctldclient_vdiff/vtctldclient_vdiff_resume/) to start the VDiff again from where it left off. Example:

```shell
$ vtctldclient --server=localhost:15999 VDiff --format=json --target-keyspace customer --workflow commerce2customer stop ad9bd40e-0c92-11ed-b568-920702940ee0
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

You use the [`delete` action](../../../reference/programs/vtctldclient/vtctldclient_vdiff/vtctldclient_vdiff_delete/) to either `delete` a specific UUID or use the `all` shorthand to delete all VDiffs created for the specified keyspace and workflow. Example:

```shell
$ vtctldclient --server=localhost:15999 VDiff --target-keyspace customer --workflow commerce2customer delete all
VDiff delete completed

$ vtctldclient --server=localhost:15999 VDiff --format=json --target-keyspace customer --workflow commerce2customer delete all
{
	"Action": "delete",
	"Status": "completed"
}
```

{{< info >}}
Deletes are idempotent, so attempting to `delete` VDiff data that does not exist is a no-op.

All VDiff data associated with a VReplication workflow is deleted when the workflow is deleted.
{{< /info >}}
