---
title: VStream
description: Change event streams
weight: 75
---

Vitess Gateways (`vtgate`) provide a [`VStream` service](../../../concepts/vstream/)
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

Events in the stream are [MySQL row based binary log events](https://dev.mysql.com/doc/refman/en/mysqlbinlog-row-events.html)
and can be processed by event bridges which support Vitess such as
[Debezium](https://debezium.io/documentation/reference/stable/connectors/vitess.html)
and to some extent bridges that support MySQL such as
[GoldenGate](https://docs.oracle.com/en/middleware/goldengate/core/21.3/gghdb/using-oracle-goldengate-mysql.html).
Other products such as [AirByte](https://airbyte.com) can also be used with [custom
Vitess connectors](https://docs.airbyte.com/connector-development/).

{{< warning >}}
We recommend Debezium as it has native Vitess support and has been used in production
environments by many Vitess users.
{{< /warning >}}

## API Details

`VStream` is a gRPC service that is part of the `vtgate` service.

#### RPC Calls
 * VTGate `Vstream` gRPC

#### Types
 * [VStreamRequest](https://pkg.go.dev/vitess.io/vitess/go/vt/proto/vtgate#VStreamRequest)
 * [VStreamResponse](https://pkg.go.dev/vitess.io/vitess/go/vt/proto/vtgate#VStreamResponse)
 * [VStreamFlags](https://pkg.go.dev/vitess.io/vitess/go/vt/proto/vtgate#VStreamFlags)
 * [VGtid](https://pkg.go.dev/vitess.io/vitess/go/vt/proto/binlogdata#VGtid)
 * [LastPKEvent](https://pkg.go.dev/vitess.io/vitess/go/vt/proto/binlogdata#LastPKEvent)
 * [TableLastPK](https://pkg.go.dev/vitess.io/vitess/go/vt/proto/binlogdata#TableLastPK)
 * [VEvent](https://pkg.go.dev/vitess.io/vitess/go/vt/proto/binlogdata#VEvent)

#### Example Usage
```
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
    Gtid:     fmt.Sprintf("%s/%s", mpos.GTIDSet.Flavor(), mpos),
    TablePKs: tableLastPK,
})
shardGtids = append(shardGtids, &binlogdatapb.ShardGtid{
    Keyspace: "ks",
    Shard:    "80-",
    Gtid:     fmt.Sprintf("%s/%s", mpos.GTIDSet.Flavor(), mpos),
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
```
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

  * [VStream Copy design doc](https://vitess.io/docs/design-docs/vreplication/vstream/vscopy/)
  * Debezium Connector for Vitess
    * [Docs](https://debezium.io/documentation/reference/stable/connectors/vitess.html)
    * [Source](https://github.com/debezium/debezium-connector-vitess/)
  * Blog posts
    * [Streaming Vitess at Bolt](https://medium.com/bolt-labs/streaming-vitess-at-bolt-f8ea93211c3f)
