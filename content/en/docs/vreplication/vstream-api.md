---
title: The VStream API
aliases: ['/docs/vreplication/vstream-api']
weight: 2000
---

The VStream API is a grpc API provided by VTGate. It lets you stream events for one or more
tables in Vitess in a shard-aware and customized way. You can think of it as a filtered binlog streamer.

Here is a high-level design of how VStream works:

![VStream Design](../img/VStream.svg)

VStreams can work in one of two modes:

1. Where you specify a GTID position to stream from.
*current* is also a valid position
which maps to last GTID. Note that if the data you request belongs to multiple shards, each
shard will have its own GTID position.

2. When you want to stream from the start (i.e. the "first" GTID)
This mode is referred to as VStream Copy

Let's look at a few examples of VStreams to get a better understanding

1. Streaming a set of tables

TBD
