---
title: Life of a stream
description: How VReplication replicates data
weight: 1
aliases: ['/docs/reference/vreplication/internals']
---

### Introduction

When a VReplication workflow runs, data is copied from source to target shards. Each target primary runs one
vreplication stream (vstream) for each source shard that the
target's [keyrange](https://vitess.io/docs/16.0/reference/features/sharding/#key-ranges-and-partitions) overlaps with.

The diagram below outlines how one such stream operates. VReplication can be asked to start from a specific
GTID or from the start. When starting from a GTID the _replication_ mode is used where it streams events from the
binlog.

![VReplication Flow](/img/VReplicationFlow.png)

#### Full table copy

If an entire table data is requested simple streaming done by _replication_ can create an avalanche of events (think 10s
of millions of rows). Moreover, it is highly likely that earlier binlogs are no longer available.

So a _copy/catchup_ mode is initiated first: data in the tables are copied over in
a consistent manner using bulk inserts. Once we have copied enough data so that we are close enough to the current
position (when replication lag is low) it switches over to, and stays in, the _replication_ mode. All future replication
is done only by streaming binlog events.

While we may have multiple database sources in a workflow each vstream has just one source and one target. The source is
always a vttablet (and hence one mysql instance). The target could be another vttablet (resharding) or a streaming grpc
response (vstream api clients).

#### Transformation and Filtering

Note that for all steps the data selected from the source will only be from the tables specified
in the [Match](https://github.com/vitessio/vitess/blob/main/proto/binlogdata.proto#LL128C5) field of the Rule
specification of the VReplication workflow. Furthermore, if a
[Filter](https://github.com/vitessio/vitess/blob/main/proto/binlogdata.proto#LL133C5) is specified for a table it will
be applied before being sent to the target. Columns may also be transformed based on the Filter’s select clause.

#### Source and Sink

Each stream has two actors: the target initiates streaming by making grpc calls to the source tablet and the source
tablet sources the data by connecting to its underlying mysql server as a replica (while replicating) or using sql
queries (in the coy phase) and streams it to the target. The target takes appropriate action: in case of resharding it
will convert the events into CRUD sql statements and apply them to the target database. In case of vstream clients the
events are forwarded by vtgate to the client.

Note that the target always pulls data. If the source pushes data, there are chances of buffer overruns if the target is
not able to process them in time. For example, in resharding workflows we need to convert the events to sql insert
statements and execute them on the target's mysql server, which are usually much slower than just selecting data on the
source.

### Modes, in detail

#### Replicate

This is the easiest to understand. The source stream just acts like a mysql replica and processes events as they are
received. Events, after any necessary filtering and transformation, are sent to the target. Replication runs
continuously with short sleeps when there are no more events to source. Periodic heartbeats are sent to the target to
signal liveliness.

#### Initialize

Initialize is called at the start of the copy phase. For each table to be copied an entry is created in \_vt.copy_state
with a null primary key. As each table copy is completed the related entry is deleted and when there are no more entries
for this workflow the copy phase is considered complete and the workflow moves into the Replication mode.

#### Copy

Copy works on one table at a time. The source selects a set of rows from the table, for primary keys greater than the
ones copied so far, using a consistent snapshot. This results in a stream of rows to be sent to the target which
generates a bulk insert of these rows.

However, there are a couple of factors which complicate our story:

* Each copy selects all rows until the current position of the binlog, but,
* Since transactions continue to be applied (presuming the database is online) the gtid positions are continuously
  moving forward

Consider this example.

We have two tables X and Y. Each table has 20 rows and we copy 10 rows at a time.
(The queries below simplified for readability).

The queries for the copy phase of X will be:

```
T1: select * from X where pk > 0 limit 10. GTID: 100, Last PK 10

   send rows to target

T2: select * from X where pk > 10 limit 10  GTID: 110, Last PK 20

   send rows to target
```

There is a gotcha here: onsider that there are 10 new txs between times T1 and T2. Some of these can potentially modify
the rows returned from the query at T1. Hence if we just return the rows from T2 (which have only rows from pk 11 to 20)
we will have an inconsistent state on the target: the updates to rows with PK between 1 and 10 will not be present.

This means that we need to first stream the events between GTIDs 100 and 110 for primary keys between 1 and 10 first and
then do the second select:

```
T1: select * from X where pk > 0 limit 10. GTID: 100, Last PK 10

   send rows to target

T2: replicate from 100 to current position (110 from previous example),

   only pass events for pks 1 to 10 of X

T3: select * from X where pk > 10 limit 10  GTID: 112, Last PK 20

   send rows to target
```

Another gotcha!: note that at time T3 when we selected the pks from 11 to 20 the gtid position could have moved further!
This could be due to transactions that were applied between T2 and T3. So if we just applied the rows from T3 we would
still have an inconsistent state, if transactions 111 and 112 affected the rows from pks 1 to 10.

This leads us to the following flow:

```
T1: select * from X where pk > 0 limit 10. GTID: 100, Last PK 10

   send rows to target

T2: replicate from 100 to current position (110 from previous example),

   only pass events for pks 1 to 10

T3: select * from X where pk > 10 limit 10  GTID: 112, Last PK 20

T4: replicate from 111 to 112  

   only pass events for pks 1 to 10

T5: Send rows for pks 11 to 20 to target
```

This flow actually works and is the one used in Vitess VReplication!

The transactions to be applied at T1 can take a long time (due to the bulk inserts). T3 (which is just a snapshot) is
quick. So the position can diverge much more at T2 than at T4. Hence, we call the step in T2 as Catchup and Step T4 as a
Fast Forward.

#### Catchup

As detailed above the catchup phase runs between two copy phases. During the copy phase the gtid position can move
significantly ahead. So we run a replicate till we come close to the current position i.e.the replication lag is small.
At this point we call Copy again.

#### Fast forward

During the copy phase we first take a snapshot. Then we fast forward: we run another replicate from the gtid position
where we stopped the Catchup to the position of the snapshot.

Finally once we have finished copying all the tables we proceed to replicate until our job is done: for example if we
have resharded and switched over the reads and writes to the new shards or when the vstream client closes its
connection.
