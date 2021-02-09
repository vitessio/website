---
title: VStream Copy
description: Streaming events from the beginning
weight: 1
---

## VStream Copy

### Allow vstreams to stream entire databases or tables

## Motivation

Currently, the vstream API streams events starting either from the current position of the binlog or from a position specified by the client. The VStream Copy feature adds support to send all events starting from the first position of the binlog.

A naive extension of the current mechanism is to stream from the starting position. However, this is impractical for any database/table of a reasonable size. We will extend VStream to make use of the bulk copy based mechanism similar to vreplication streams, used in MoveTables or Reshard sharding workflows.

Note that with vstream copy the client vstream will not faithfully reproduce the events from the binlog. The aim is to be eventually (and rapidly) consistent with the current database snapshot. This improves performance since we will be merging multiple row updates into a single transaction.
Once we have caught up (i.e. the replication lag is small) binlog events will again be directly streamed similar to the current implementation.

### Current API

Clients create vstreams by grpc-ing to VTGate using the Vstream API call. In golang:

```
conn, _ := 	VTGate.Dial(ctx, "localhost:15991")
// tabletType is one of replica/master/rdonly, filter,vgtid: see below
reader, _ := 	VStream(ctx, tabletType, vgtid, filter)
e, _  := 	reader.Recv() //receive VEvents in a loop until io.EOF
```

It is possible for network errors to occur or for the client process to fail. In addition, the vstreamer itself might fail at VTGate or VTTablet. Thus, VTGate needs to send state frequently allowing VTGate to be stateless and clients to recover properly from failures.

Also, while creating the stream the client can specify multiple shards and/or keyspaces from which to stream events.

The vgtid structure facilitates both: determining the stream sources and maintaining state. vgtid is a list of tuples: (keyspace, shard, gtid). When a stream is created, gtid can either be “current” or a valid binlog position at which the vstream starts streaming events.

Some examples:
```
// stream from current position from two shards
vgtid := &binlogdatapb.VGtid{
         		ShardGtids: []*binlogdatapb.ShardGtid{{
         			Keyspace: "ks",
         			Shard:    "-40",
         			Gtid:     "current",
         		},{
         			Keyspace: "ks",
         			Shard:    "80-c0",
         			Gtid:     "current",
         		}}
         }

// stream from specific position from all shards in keyspace ks
vgtid := &binlogdatapb.VGtid{
         		ShardGtids: []*binlogdatapb.ShardGtid{{
         			Keyspace: "ks",
         			Gtid:     "MariaDB/0-41983-20",
                }}
         }

// stream from current position from all keyspaces
vgtid := &binlogdatapb.VGtid{
         		ShardGtids: []*binlogdatapb.ShardGtid{{
         			Gtid:     "current",
                }}
         }
```

The data streamed is sourced from the list of keyspace/shards after applying the specified filter.

To achieve this VTGate sends a vgtid event whenever it encounters a gtid event with the current vgtid state at VTGate. Thus if the stream is broken, for any reason, the client needs to simply create a new vstream using the last vgtid that it received.


## Architecture/Design

During a copy there will two distinct phases:

1. Copy phase: where the vstreamer is sending row data in bulk using the primary key to “paginate” the table
1. Replication phase: once copying is completed and going forward we only stream events

The copy phase is nuanced: we copy a batch of rows until a particular PK using a consistent snapshot. However, once the copy is completed the binlog position would have moved possibly containing updates to the rows already transmitted.
Hence we need to perform a “catchup” where we play the events up to the current position. We can only send updates to rows that we have already sent to the stream.

After the catchup, we send the next batch of rows and perform the related catchup. This copy-catchup loop continues until all tables are copied, after which it is business as usual and events are streamed as they appear in the binlog.

### API Changes for VStream Copy

To use VStream Copy you just need to pass an empty string as the position.
The only other change is in the vgtid structure. It now becomes a list of

`(keyspace, shard, gtid,[]LastTablePK)`

While the copy is in progress, the LastPK list contains the last seen primary key for each table in that shard. Once the copy is completed and we are replicating the stream this parameter will be nil.

Note that the vgtid is opaque to the consumer of the vstream API once the vstream starts and the ongoing state does not need to be interpreted on the client.

To start a VStream Copy user is expected to provide an empty gtid along with a list of tables to copy
 (essentially a LastTablePK list with a nil PK for each). Some examples
 (see https://github.com/vitessio/contrib/blob/master/vstream_client/vstream_client.go for a sample client):

```
// vstream copy two tables table from two shards
filter := &binlogdatapb.Filter{
		Rules: []*binlogdatapb.Rule{{
			Match: "t2",
            Filter: "select id, val from t2",
		},{
			Match: "t1",
            Filter: "select * from t1",
        }},
	}
vgtid := &binlogdatapb.VGtid{
         		ShardGtids: []*binlogdatapb.ShardGtid{{
         			Keyspace: "ks",
         			Shard:    "-40",
         			Gtid:     "",
         		},{
         			Keyspace: "ks",
         			Shard:    "80-c0",
         			Gtid:     "",
         		}}
         }

// stream the entire database: vstream copy from all tables in all keyspaces
filter := &binlogdatapb.Filter{
		Rules: []*binlogdatapb.Rule{{
			Match: "/.*/",
		}},
	}
vgtid := &binlogdatapb.VGtid{
         		ShardGtids: []*binlogdatapb.ShardGtid{{
         			Gtid:     "",
                }}
         }
```
