---
title: Throttling
weight: 200
---

### Introduction

VReplication moves potentially massiva amounts of data from one place to another, whether within the same keyspace and shard or across keyspaces. It copies data of entire tables and follows up to apply ongoing changes on those tables by reading the binary logs (aka the changelog).

This places load on both the source side (where VReplication reads data from) as well as on target side (where VReplication writes data to). 

On the source side, VReplication reads the full content of tables. This typically means loading pages from disk contending for disk IO, and "polluting" the MySQL buffer pool. The operation competes with normal production traffic on both IO and memory resources. If the source is a replica, the operation may lead to replication lag. If on a primary, this may lead to write contention.

On the target side, VReplication writes massive amount of data. If the target server is a primary with replicas, then the replicas may incur replication lag.

To address the above issues, VReplication uses the [tablet throttler](../../features/tablet-throttler/) mechanism to push back both reads and writes.

### Target throttling

On the target side, VReplication wishes to consult the overall health of the target shard (there can be multiple shards to a VReplication workflow, and here we discuss the single shard at the end of a single VReplication stream). That shard may serve production traffic unrelated to VReplication. VReplication therefore consults the internal equivalent of `/throttler/check` when writing data to the shard's primary. This checks the replication lag on relevant replicas in the shard. The throttler will push back VReplication writes of both table-copy and changelog events.

### Source throttling

On the source side, VReplication only affects the single MySQL server it reads from, and has no impact on the overall shard. VStreamer, the source endpoint of VReplication, consults the equivalent of `/throttlet/check-self`, which looks for replication lag on the source host.

As log as `check-self` fails, VStreamer will not read table data, nor will it pull events from the changelog.

### Impact of throttling

VReplication throttling is designed to give way to normal production traffic while operating in the background. Production traffic will see less contention. The downside is that VReplication can take longer to operate. Under high load in production VReplication may altogether stall, to resume when the load subsides.

Throttling will push back VReplication on replication lag. On systems where replication lag is normally high this can bring VReplication down to a grinding halt. In such systems consider configuring `-throttle_threshold` to a value that agrees with your constraints. The default throttling threshold is at `1` second replication lag.
