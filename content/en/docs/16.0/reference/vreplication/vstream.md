---
title: VStream
description: Change event streams
weight: 75
aliases: ['/docs/design-docs/vreplication/vstream/vscopy/']
---

[Vitess Gateways](../../../concepts/vtgate/) (`vtgate`) provide a [`VStream` service](../../../concepts/vstream/)
that allows clients to subscribe to a change event stream for a set of tables.

## Use Cases

 * **Change Data Capture (CDC)**: `VStream` can be used to capture changes to a
   table and send them to a downstream system. This is useful for building
   real-time data pipelines.

## Overview

`VStream` supports copying the current contents of a table — as you will often not
have the binary logs going back to the creation of the table — and then begin streaming
new changes to the table from that point on. It also supports resuming this initial copy
phase if it's interrupted for any reason.

Events in the stream are [MySQL row based binary log events](https://dev.mysql.com/doc/refman/en/mysqlbinlog-row-events.html) — with [extended metadata](https://pkg.go.dev/vitess.io/vitess/go/vt/proto/binlogdata#VEvent)
— and can be processed by event bridges which support Vitess such as
[Debezium](https://debezium.io/documentation/reference/stable/connectors/vitess.html).
Other products such as [AirByte](https://airbyte.com) can also be used with [custom
Vitess connectors](https://docs.airbyte.com/connector-development/).

{{< warning >}}
We recommend Debezium as it has native Vitess support and has been used in production
environments by many Vitess users.
{{< /warning >}}

## API Details

[`VStream` is a gRPC](https://pkg.go.dev/vitess.io/vitess/go/vt/vtgate/vtgateconn#VTGateConn.VStream)
that is part of the [`vtgate`](../../../concepts/vtgate/) service and is accessible via a
[`vtgate`](../../../concepts/vtgate/) process's `--grpc_port`.

### RPC Parameters

#### Context

**Type** [Context](https://pkg.go.dev/context#Context)\
**Required**\
**Default** none

In addition to the typical `Context` usage, it can contain a custom key-value pair where the key is `1` and the value is a
[`CallerID`](https://pkg.go.dev/vitess.io/vitess/go/vt/proto/vtrpc#CallerID). This value is then passed along to
[tablets](../../../concepts/tablet/) to identify the originating client for the request. It is not meant to be secure, but
primarily informational. The client can provide whatever info they want in the
[`CallerID`](https://pkg.go.dev/vitess.io/vitess/go/vt/proto/vtrpc#CallerID) fields and they will be trusted by the servers
as this information is primarily used to aid in monitoring and debugging. The [`vtgate`](../../../concepts/vtgate/) propagates
the value to the source [`vttablet`](../../../concepts/tablet/) processes and the tablets may use this information for various
monitoring, metrics, and logging purposes. It can, however, also be used for other purposes such as denying the client
access to tables during a migration ([`MoveTables`](../movetables/) or [`Reshard`](../reshard/)).

#### TabletType

**Type** [TabletType](https://pkg.go.dev/vitess.io/vitess/go/vt/proto/topodata#TabletType)\
**Required**\
**Default** UNKNOWN (you must specify a valid type)

The tablet type to use [when selecting stream source tablets](../tablet_selection/).

#### VGtid

**Type** [VGtid](https://pkg.go.dev/vitess.io/vitess/go/vt/proto/binlogdata#VGtid)\
**Required**

The keyspace, shard, and GTID position list to start streaming from. If no `ShardGtid.Gtid` value is provided
then a [table copy phase](https://github.com/vitessio/vitess/issues/6277) will be initiated for the tables matched
by the provided [filter](#filter) on the given shard.

#### Filter

**Type** [Filter](https://pkg.go.dev/vitess.io/vitess/go/vt/proto/binlogdata#Filter)\
**Required**

The tables which you want to subscribe to change events from — in the given keyspace(s) and shard(s) contained
in the provided [VGtid](#vgtid) — and any query predicates to use when filtering the rows for which change
events will be generated.

#### VStreamFlags

##### MinimizeSkew

**Type** bool\
**Default** false

When enabled the `vtgate` will keep the events in the stream roughly time aligned — it is aggregating streams coming
from each of the shards involved — using the event timestamps to ensure the maximum time skew between the source
tablet shard streams is kept under 10 minutes. When it detects skew between the source streams it will pause sending
the client more events and allow the lagging shard(s) to catch up.

{{< info >}}
There is no strict ordering of events across shards and the client will need to examine the event timestamps.
{{</ info >}}

##### HeartbeatInterval

**Type** unsigned integer\
**Default** 0 (none)

How frequently, in seconds, to send heartbeat events to the client when there are no other events in the stream to
send.

##### StopOnReshard

**Type** bool\
**Default** false

When enabled the `vtgate` will send a reshard event to the client along with an `EOF`
`error` in the [`VStreamReader.Recv`](https://pkg.go.dev/vitess.io/vitess/go/vt/vtgate/vtgateconn#VStreamReader)
response and stop sending any further events.

##### Cells

**Type** string\
**Default** ""

If specified, these cells (comma-separated list) are used
[when selecting stream source tablets](../tablet_selection/). When no value is specified the `vtgate` will
default to looking for source tablets within its own local cell.

### RPC Response

The [`VStream` gRPC](https://pkg.go.dev/vitess.io/vitess/go/vt/vtgate/vtgateconn#VTGateConn.VStream) returns
a [`VStreamReader`](https://pkg.go.dev/vitess.io/vitess/go/vt/vtgate/vtgateconn#VStreamReader) and a non-nil `error` if
the stream could not be initialized. You would call the `Recv` method on that
[`VStreamReader`](https://pkg.go.dev/vitess.io/vitess/go/vt/vtgate/vtgateconn#VStreamReader) in a for loop and
responses will be sent when available. Each response consisting of the following two parameters:
  * An array of [`VEvent`](https://pkg.go.dev/vitess.io/vitess/go/vt/proto/binlogdata#VEvent) objects — the new messages to process in the stream
  * An `error` — an error that, if non-nil, indicates the stream has been closed (`EOF`) or an error occurred

### API Types
 * [TabletType](https://pkg.go.dev/vitess.io/vitess/go/vt/proto/topodata#TabletType)
 * [VGtid](https://pkg.go.dev/vitess.io/vitess/go/vt/proto/binlogdata#VGtid)
 * [ShardGtid](https://pkg.go.dev/vitess.io/vitess/go/vt/proto/binlogdata#ShardGtid)
 * [Filter.Rule](https://pkg.go.dev/vitess.io/vitess/go/vt/proto/binlogdata#Rule)
 * [LastPKEvent](https://pkg.go.dev/vitess.io/vitess/go/vt/proto/binlogdata#LastPKEvent)
 * [TableLastPK](https://pkg.go.dev/vitess.io/vitess/go/vt/proto/binlogdata#TableLastPK)
 * [VStreamFlags](https://pkg.go.dev/vitess.io/vitess/go/vt/proto/vtgate#VStreamFlags)
 * [VStreamReader](https://pkg.go.dev/vitess.io/vitess/go/vt/vtgate/vtgateconn#VStreamReader)
 * [VEvent](https://pkg.go.dev/vitess.io/vitess/go/vt/proto/binlogdata#VEvent)

### Example Usage

You can find a full example go client [here](https://github.com/vitessio/vitess/blob/main/examples/local/vstream_client.go).

Below is a snippet showing how to use the `VStream` API in go:
```go
gconn, err := vtgateconn.Dial(ctx, grpcAddress)
if err != nil {
    t.Fatal(err)
}
defer gconn.Close()

// lastPK is id1=4
lastPK := sqltypes.Result{
    Fields: []*query.Field{{Name: "id1", Type: query.Type_INT64}},
    Rows:   [][]sqltypes.Value{{sqltypes.NewInt64(4)}},
}
tableLastPK := []*binlogdatapb.TableLastPK{{
    TableName: "t1",
    Lastpk:    sqltypes.ResultToProto3(&lastPK),
}}

var shardGtids []*binlogdatapb.ShardGtid
var vgtid = &binlogdatapb.VGtid{}
shardGtids = append(shardGtids, &binlogdatapb.ShardGtid{
    Keyspace: "ks",
    Shard:    "-80",
    Gtid:     "MySQL56/89f66ef2-863a-11ed-9bdf-3d270fd3f552:1-30219"
    TablePKs: tableLastPK,
})
shardGtids = append(shardGtids, &binlogdatapb.ShardGtid{
    Keyspace: "ks",
    Shard:    "80-",
    Gtid:     "MySQL56/2174b383-5441-11e8-b90a-c80aa9429562:1-29516,24da167-0c0c-11e8-8442-00059a3c7b00:1-19"
    TablePKs: tableLastPK,
})
vgtid.ShardGtids = shardGtids
filter := &binlogdatapb.Filter{
    Rules: []*binlogdatapb.Rule{{
        Match:  "t1",
        Filter: "select * from t1",
    }},
}
flags := &vtgatepb.VStreamFlags{}
reader, err := gconn.VStream(ctx, topodatapb.TabletType_PRIMARY, vgtid, filter, flags)

var evs []*binlogdatapb.VEvent
for {
    e, err := reader.Recv()
    ...
```

## Debugging

There is also an SQL interface that can be used for testing and debugging from a `vtgate`. Here's an example:
```mysql
$ mysql --quick <vtgate params>

mysql> SET WORKLOAD=OLAP;

mysql> VSTREAM * FROM commerce.corder\G
*************** 1. row ***************
         op: +
   order_id: 1
customer_id: 1
        sku: NULL
      price: 10
************** 2. row ***************
         op: *
   order_id: 1
customer_id: 1
        sku: NULL
      price: 7
************** 3. row ***************
         op: -
   order_id: 1
customer_id: 1
        sku: NULL
      price: 7
…
```

## More Reading

  * [VStream Copy](https://github.com/vitessio/vitess/issues/6277)
  * [VStream API and Resharding](../internal/vstream-stream-migration/)
  * [VStream Skew Minimization](../internal/vstream-skew-detection/)
  * Debezium Connector for Vitess
    * [Docs](https://debezium.io/documentation/reference/stable/connectors/vitess.html)
    * [Source](https://github.com/debezium/debezium-connector-vitess/)
  * Blog posts
    * [Streaming Vitess at Bolt](https://medium.com/bolt-labs/streaming-vitess-at-bolt-f8ea93211c3f)
