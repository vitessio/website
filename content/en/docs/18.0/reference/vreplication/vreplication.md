---
title: Overview
description: VReplication features, design and options in a nutshell
weight: 2
aliases: ['/docs/reference/features/vreplication/']
---

VReplication is a core component of Vitess that can be used to compose
many features. It can be used for the following use cases:

* **Data Migrations**: Use [`MoveTables`](../movetables/) to migrate tables into
  Vitess or across [`Keyspaces`](../../../concepts/keyspace/) with online revertable workflows.
* **Resharding**: Use [`Reshard`](../reshard/) to scale [`Keyspaces`](../../../concepts/keyspace/)
  up or down as needed with automated online revertable workflows.
* **Materialized Views**: Use [`Materialize`](../materialize/) to create
  a view of the source table in a target keyspace. This materialization
  can use a different primary [`vindex`](../../features/vindexes/) than the source.
  It can also materialize a subset of the source columns, or add new expressions from
  the source. This view will be kept up-to-date in real time. One can also materialize
  reference tables onto all shards for improved data locality, allowing
  Vitess to perform efficient local joins with those materialized tables.
* **Realtime Rollups**: Use [`Materialize`](../materialize/) with aggregation
  expressions in which case Vitess will create a rolled up version of the
  source table which can be used for realtime analytics.
* **Lookup Vindexes**: Use [`CreateLookupVindex`](../../../user-guides/vschema-guide/backfill-vindexes/#createlookupvindex) to create a new
  [`lookup vindex`](../../features/vindexes/#functional-and-lookup-vindex)
  and backfill it from the existing data.
* **Online Schema Changes**: Use [`ddl_stragegy=vitess`](../../../user-guides/schema-changes/ddl-strategies/) for native [online non-blocking schema
  migrations](../../../user-guides/schema-changes/managed-online-schema-changes/) that are trackable, cancellable, revertible, and retryable.
  All being safe to run in production due to intelligent throttling and
  resource management.
* **Change Notifications (CDC)**: The [`VStream`](../../../concepts/vstream/)
  component of VReplication can be used for the application or a systems
  operator to subscribe to change notifications and use it to keep downstream
  systems up-to-date with the source.
* **Job Queues**: VReplication can also be used to provide a job queue for
  asynchronous processing of data using the [Messaging](../../features/messaging/)
  feature.

## Feature Description

VReplication works as [a stream or set of streams](../internal/life-of-a-stream/).
Each stream establishes replication from a source keyspace/shard to a
target keyspace/shard.

A given stream can replicate multiple tables. For each table, you can
specify a `SELECT` statement that represents both the transformation
rule and the filtering rule. The `SELECT` expressions specify the
transformation, and the `WHERE` clause specifies the filtering.

The `SELECT` expressions can be any non-aggregate MySQL expression, or
they can also be `COUNT` or `SUM` as aggregate expressions. Aggregate
expressions combined with the corresponding `GROUP BY` clauses will
allow you to materialize real-time rollups of the source table, which
can be used for analytics. The target table can have a different name
from the source.

For a sharded system like Vitess, multiple VReplication streams
may be needed to achieve the objective. This is because there
can be multiple source shards and multiple destination shards, and
the relationship between them may not be one to one.

VReplication performs the following essential functions:

* [Copy data](../internal/life-of-a-stream/#copy)
  from the source to the destination table in a consistent
  fashion. For a large table, this copy can be long-running. It can be
  interrupted and resumed. If interrupted, VReplication can keep
  the copied portion up-to-date with respect to the source, and it can
  resume the copy process at a point that is consistent with the
  current replication position.
* After copying is finished, it can continuously [replicate](../internal/life-of-a-stream/#replicate)
  the data from the source to destination.
* The copying rule can be expressed as a `SELECT` statement. The
  statement should be simple enough that the materialized table can
  be kept up-to-date from the data coming from the binlog. For
  example, joins in the `SELECT` statement are not supported today.
* Correctness verification: VReplication supports the [VDiff](../vdiff) command
  which verifies that the target table is an exact representation of
  the `SELECT` statement from the source by capturing consistent
  snapshots of the source and target and comparing them against each
  other.
* Journaling: If there is any kind of traffic cut-over where we
  start writing to a different table than we used
  to before, VReplication will save the current binlog positions
  into a journal table. This can be used by other streams to resume
  replication from the new source.
* Routing rules: Although this feature is itself not a direct
  functionality of VReplication, it works hand in hand with it. It
  automatically manages sophisticated rules about where to route queries
  depending on the type of workflow being performed. For example,
  it is used to control the cut-over during [`MoveTables`](../movetables/).

<a name="exec"></a>

## Other Properties of VReplication

### Fast Replay

VReplication has the capability to batch transactions if the send rate of the source
exceeds the replay rate of the destination.  This allows it to catch up very quickly
when there is a backlog. Load tests have shown a 3-20X improvement over traditional
MySQL replication depending on the workload.

### Accurate Lag Tracking

The source [`VTTablet`](../../../concepts/vtgate/) sends its current time along with every event. This allows the
target to correct for clock skew while estimating replication lag. Additionally,
the source starts sending heartbeats if there is nothing to send. If the target
receives no events from the source at all, it knows that it's definitely lagged
and starts reporting itself accordingly.

### Self-Replication

VReplication allows you to set the source keyspace/shard to be the same as the target.
This is especially useful for performing schema rollouts: you can create the target
table with the intended schema and vreplicate from the source table to the new
target. Once caught up, you can cutover to write to the target table.
In this situation, an apply on
the target generates a binlog event that will be picked up by the source and
sent to the target. Typically, it will be an empty transaction. In such cases,
the target does not generally apply these transactions, because such an application
will generate yet another event. However, there are situations where one needs
to apply empty transactions, especially if it's a required stopping point.
VReplication can differentiate between these situations and apply events
only as needed.

### Deadlocks and Lock Wait Timeouts

It is possible that multiple streams can conflict with each other and cause
deadlocks or lock waits. When such things happen, VReplication silently retries
such transactions without reporting an error. It does increment a counter so
that the frequency of such occurrences can be tracked.

### Automatic Retries

If any other error is encountered, the replication is retried after a short wait.
Each time, the stream searches from the full list of available sources and picks
one at random.

### Handle DDL

The [`MoveTables`](../movetables/) and [`Reshard`](../reshard/) commands allow you to
specify a value for `on-ddl`. This allows you to specify what to do with DDL SQL
 statements when they are encountered
in the replication stream from the source. The values can be as follows:

* `IGNORE`: Ignore all DDLs (this is also the default, if a value for `on-ddl`
  is not provided).
* `STOP`: Stop when DDL is encountered. This allows you to make any necessary
  changes to the target. Once changes are made, updating the state to `Running`
  will cause VReplication to continue from just after the point where it
  encountered the DDL.
* `EXEC`: Apply the DDL, but stop if an error is encountered while applying it.
* `EXEC_IGNORE`: Apply the DDL, but ignore any errors and continue replicating.

{{< warning >}}
We caution against against using `EXEC` or `EXEC_IGNORE` for the following reasons:
  * You may want a different schema on the target
  * You may want to apply the DDL in a different way on the target
  * The DDL may take a long time to apply on the target and may disrupt replication, performance, and query execution while it is being applied (if serving traffic from the target)
{{< /warning >}}

### Failover Continuation

If a failover is performed on the target keyspace/shard, the new primary will
automatically resume VReplication from where the previous primary left off.

### Tablet Selection

VReplication automatically chooses viable tablets for the source and target of a given stream. See [tablet selection](../../vreplication/tablet_selection).

### Throttling

VReplication throttles operations when the source or target appear to be overloaded, indicated by replication lag. See [throttling](../../vreplication/throttling).

## Monitoring and Troubleshooting

### VTAdmin

VTAdmin provides views into the current workflows running within a Vitess cluster.
See [`VTAdmin`](../../vtadmin).

### VTTablet /debug/status

The first place to look at is the `/debug/status` page of the target primary
[`VTtablet`](../../../concepts/tablet/). The bottom of the page shows the status
of all the VReplication streams.

Typically, if there is a problem, the `Last Message` column will display the
error. Sometimes, it's possible that the stream cannot find a source. If so,
the `Source Tablet` would be empty.

### VTTablet Logfile

If the errors are not clear or if they keep disappearing, the VTTablet's INFO logfile
will contain information about what it's been doing with each stream.

### Workflow Show

The current status of the workflows and streams can also be fetched by using
the `vtctl` client [`Workflow Show`](../workflow/) command.

### Monitoring Variables

VReplication also reports [a set of metrics](../metrics/) that can be scraped by
monitoring tools like [Prometheus](https://prometheus.io).

Thresholds and alerts can be set to draw attention to potential problems.
