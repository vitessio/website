---
title: VStream Skew Minimization
description: Aligning streams from different shards in the VStream API
weight: 7
aliases: ['/docs/design-docs/vreplication/vstream/skew-detection/']
---

## VStream Skew Detection

### Motivation

When the [VStream API](../../vstream/) is streaming from multiple shards we have multiple sources of events: one `PRIMARY`
or `REPLICA` tablet for each shard in the provided [`VGTID`](https://pkg.go.dev/vitess.io/vitess/go/vt/proto/binlogdata#VGtid).
The rate at which the events will be streamed from the underlying sources can vary depending on various factors, such as:

* The replication lag on the source tablets (if a `REPLICA` tablet is selected as the source for the vstream)
* The CPU load on the source tablet
* Possible network partitions or network delays

This can result in the events in the vstream from some shards being well ahead of other shards. So, for example, if a
row moves from the faster shard to a slower shard we might see the `DELETE` event in the vstream from the faster shard
long before the `INSERT` from the second. This would result in the row going "invisible" for the duration of the skew.
This can affect the user experience in applications where the vstream events are used to refresh a UI, for example.

For most applications where [VStream API](../../vstream/) events feed into change data capture systems for auditing or
reporting purposes these delays may be acceptable. However, for applications which are using these events for user-facing
functions this can cause unexpected behavior. See https://github.com/vitessio/vitess/issues/7402 for one such case.

### Goal

It is not practically possible to provide exact ordering of events across Vitess shards. The [VStream API](../../vstream/)
will inherently stream events from one shard independently of another. However, vstream events
([`VEvent`](https://pkg.go.dev/vitess.io/vitess/go/vt/proto/binlogdata#VEvent)) do keep track of the binlog event
timestamps which we can use to loosely coordinate the streams. Since binlog timestamp granularity is only to the nearest
second, and we attempt to align the streams to within a second.

### Implementation

The skew minimization feature adds a [`MinimizeSkew` flag](../../vstream/#minimizeskew) that the client can set. This flag
enables skew detection between the various streams. Once a skew is detected, events for streams that are ahead are held back
until the lagging streams catch up causing the skew to reach an acceptable level.

Each vstream event ([`VEvent`](https://pkg.go.dev/vitess.io/vitess/go/vt/proto/binlogdata#VEvent)) contains two timestamps:
one when the database transaction occurred, and the other the current time on the source tablet where the
[`VEvent`](https://pkg.go.dev/vitess.io/vitess/go/vt/proto/binlogdata#VEvent) was created. This lets us compute how far in
the past the event we just received was created. We use this to determine which shard has the most recent event and which one
has the oldest. Note that for shards where there is no activity, the vstreamer sends a heartbeat event every second and the
transaction time for a heartbeat is the same as the current time on the source. (These heartbeats are not forwarded to clients
in the vstream since they are synthetic/internal VReplication events.)

If the difference between the fastest and slowest streams is greater than a threshold, we declare that we have detected
a skew. MySQL binlogs store the transaction timestamp in seconds. Also, on the `vtgate` serving the vstream, we adjust
this time for clock skews between the `vtgate` and the source tablet's `mysqld` server. When the user sets the `MinimizeSkew`
flag we want to keep the events across shards within the same second: each transaction timestamp is within 1 second of each
other. To account for rounding-off of the transaction timestamp and the clock-skew we set the threshold to be 2 seconds,
instead of 1 second, so that we don't keep stalling the streams due to cumulative round-offs.

### Possible Unexpected Behavior

If there are no events for a second in a shard then a heartbeat is sent. On receiving a heartbeat we reset the skew.
This is necessary to avoid shards with no events starving other shards. The current logic will align streams only if
they are all getting events faster than the heartbeat frequency.

This means that we cannot guarantee the skew alignment feature will work as expected in certain conditions. This could
happen mainly while streaming from `REPLICA` tablets with high replication lag, say, due to high write QPS or a network
partition.

Thus it is recommended that you stream from `PRIMARY` tablets when using the [VStream feature](../../vstream/).
Note, however, that even `PRIMARY` tablets with skewed loads could potentially trigger such a situation.

### API

This is how you would turn on the skew detection and alignment feature in a [VStream](../../vstream/) client:

```go
    import vtgatepb "vitess.io/vitess/go/vt/proto/vtgate"
    ...
    ...
    flags := &vtgatepb.VStreamFlags{};
    flags.MinimizeSkew = true;

    reader, err := conn.VStream(ctx, topodatapb.TabletType_PRIMARY, vgtid, filter, flags)

```
