---
title: VStream Skew Minimization
description: Aligning streams from different shards in the VStream API
weight: 3
---

## VStream Skew Detection

### Motivation

When the VStream API is streaming from multiple shards we have multiple sources of events: one primary or replica tablet for each shard in the provided vgtid. The rate at which the events will be streamed by the source depend on:
* the replication lag on the source tablets (if a replica is selected)
* the cpu load on the source tablet
* possible network partitions or network delays

This can result in the events from some shards being well ahead of other shards. So, for example, if a row moves from the faster shard to a slower shard we might see the delete event in the faster shard much before the insert in the second, resulting in the row going "invisible" for the duration of the skew. This can affect user experience in applications where these events are used to refresh UI, for example.

For most applications where vstream api events feed into change data capture systems for auditing or reporting purposes these delays may be acceptable. However for applications which are using these events for user-facing functions this can cause unexpected behavior. See https://github.com/vitessio/vitess/issues/7402 for one such case.

### Goal

It is not practically possible to provide exact ordering of events across Vitess shards. The VStream API will inherently stream events from one shard independently of another. However vstreamer events do keep track of the binlog event timestamps which we can use to loosely coordinate the streams. Since binlog timestamps granularity is seconds we attempt to align the streams to within a second.


### Implementation

The skew minimization feature adds a flag that the client can set. This flag enables skew detection between the various streams. Once a skew is detected, events for streams that are ahead are held back until the lagging streams catch up causing the skew to reach an acceptable level.

Each vstreamer event (_vevent_) contains two timestamps: one when the database transaction occurred, and the other, the current time on the source tablet where the vevent was created. This lets us compute how far in the past the event we just received was created. We use this to determine which shard has the most recent and which one has the oldest event. Note that, for shards where there is no activity, vstreamer sends a heartbeat event every second. The transaction time for an heartbeat is the same as the current time on the source. (These heartbeats are not forwarded to the vstream since they are synthetic vreplication events).

If the difference between the fastest and slowest streams is greater than a threshold, we declare that we have detected a skew. MySQL binlogs store the transaction timestamp in seconds. Also, on the vtgate serving the vstream, we adjust this time for clock skews between the vtgate and the source MySQL server. When the user sets the `MinimizeSkew` flag we want to keep the events across shards to be in the same second: each transaction timestamp is within 1 second of each other. To account for rounding-off of the transaction timestamp and the clock-skew we set the threshold to be 2 seconds, instead of 1 second, so that we don't keep stalling the streams due to cumulative round-offs.

### Possible unexpected behavior

If there are no events for a second in a shard then a heartbeat is sent. On receiving a heartbeat we reset the skew. This is necessary to avoid shards with no events starving other shards. The current logic will align streams only if they are all getting events faster than the heartbeat frequency.

This means that we cannot guarantee the skew alignment feature will work as expected in certain conditions. This could happen mainly while streaming from replicas with high replication lags, say, due to high write qps or a network partition.

Thus it is recommended that you stream from primaries when using this feature. Note however that even primaries with skewed loads could trigger such a situation.

### API

This is how you would turn on the skew alignment feature.

```
    import vtgatepb "vitess.io/vitess/go/vt/proto/vtgate"
    ...
    ...
    flags := &vtgatepb.VStreamFlags{};
    flags.MinimizeSkew = true;

    reader, err := conn.VStream(ctx, topodatapb.TabletType_MASTER, vgtid, filter, flags)

```
