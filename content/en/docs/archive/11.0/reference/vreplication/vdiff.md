---
title: VDiff
description: Compare the source and target in a workflow to ensure integrity
weight: 40
---

### Command

```
VDiff  [-source_cell=<cell>] [-target_cell=<cell>] [-tablet_types=primary,replica,rdonly]
       [-limit=<max rows to diff>] [-tables=<table list>] [-format=json]
       [-filtered_replication_wait_time=30s] [-debug_query] [-only_pks] <keyspace.workflow>
```

### Description

VDiff does a row by row comparison of all tables associated with the workflow, diffing the
source keyspace and the target keyspace and reporting counts of missing/extra/unmatched rows.

It is highly recommended that you do this before you finalize a workflow with `SwitchTraffic`.

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

###### _Example:_

```
[{
  "ProcessedRows": 5,
  "MatchingRows": 5,
  "MismatchedRows": 0,
  "ExtraRowsSource": 0,
  "ExtraRowsTarget": 0
},{
  "ProcessedRows": 3,
  "MatchingRows": 3,
  "MismatchedRows": 0,
  "ExtraRowsSource": 0,
  "ExtraRowsTarget": 0
}]
```

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

#### Example

```
$ vtctlclient VDiff customer.commerce2customer

Summary for corder: {ProcessedRows:10 MatchingRows:10 MismatchedRows:0 ExtraRowsSource:0 ExtraRowsTarget:0}
Summary for customer: {ProcessedRows:11 MatchingRows:11 MismatchedRows:0 ExtraRowsSource:0 ExtraRowsTarget:0}
```

### Using VDiff with huge tables

Currently VDiff runs within vtctd. Each VDiff will stream rows from all sources and targets and then compare them row by row after assembling the rows in order. Since there are no database transactions, VDiff will run much faster than the actual workflow. However, for huge tables (billions of rows or terabytes in size) this can take several hours or even days depending on the number of rows, row composition, server configurations and the topology of the cluster. If your sources and/or targets are across multiple cells, for example, this can slow down the VDiff considerably.

Actual VDiff speeds are of course dependent on several factors in your cluster. But as a reference, we have seen VDiffs run as fast as 400mrph (million rows per hour) (~9B rows/day) for tables with short rows, or as slow as 60mrph (~1.5B rows/day), for tables with larger width and complex columns.

You may need to use one or more of the following recommendations while running long VDiffs:

* If VDiff takes more than an hour `vtctlclient` will hit grpc/http timeouts of 1 hour. In that case you can use `vtctl` (the bundled `vctlclient` + `vtctld`) instead.
* VDiff also synchronizes sources and targets to get consistent snapshots. If you have a high write QPS then you may encounter timeouts during the sync. Use higher values of `-filtered_replication_wait_time` to prevent that, for example `-filtered_replication_wait_time=4h`.
* If VDiff takes more than a day set the `-wait-time` parameter, which is the maximum time a vtctl command can run for, to a value comfortably higher than the expected run time, for example `-wait-time=168h`.
* You can follow the progress of the command by tailing the vtctld logs. VDiff logs progress every 10 million rows. This can also give you an early indication of how long it will run for, allowing you to increase your settings if needed.

### Note

* There is no throttling, so you might see an increased lag in the replica used as the source.
* VDiff is currently not resumable, so any timeouts or errors mean that you will need to rerun the entire VDiff again.
* VDiff runs one table at a time.

_VReplication and VDiff performance improvements, resumability and throttling support are on the roadmap!_
