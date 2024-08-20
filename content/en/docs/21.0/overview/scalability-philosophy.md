---
title: Scalability Philosophy
weight: 3 
aliases: ['/docs/launching/scalability-philosophy/']
---

Scalability problems can be solved using many approaches. This document describes Vitess' approach to address these problems.

## Small Instances

When deciding to shard or break databases up into smaller parts, it's tempting to break them just enough that they fit in one machine. In the industry, it’s common to run only one MySQL instance per host.

Vitess recommends that instances be broken up into manageable chunks (250GB per MySQL server), and not to shy away from running multiple instances per host. The net resource usage would be about the same. But the manageability greatly improves when MySQL instances are small. There is the complication of keeping track of ports, and separating the paths for the MySQL instances. However, everything else becomes simpler once this hurdle is crossed.

There are fewer lock contentions to worry about, replication is a lot happier, production impact of outages is smaller, backups and restores run faster, and a lot more secondary advantages can be realized. For example, you can shuffle instances around to get better machine or rack diversity leading to even smaller production impact on outages, and improved resource usage.

## Durability Through Replication

Traditional data storage software treated data as durable as soon as it was flushed to disk. However, this approach is impractical in today’s world of commodity hardware. Such an approach also does not address disaster scenarios.

The new approach to durability is achieved by copying the data to multiple machines, and even geographical locations. This form of durability addresses the modern concerns of device failures and disasters.

Many of the workflows in Vitess have been built with this approach in mind. For example, turning on semi-sync replication is highly recommended. This allows Vitess to failover to a new replica when a primary goes down, with no data loss. Vitess also recommends that you avoid recovering a crashed database. Instead, create a fresh one from a recent backup and let it catch up.

Relying on replication also allows you to loosen some of the disk-based durability settings. For example, you can turn off `sync_binlog`, which greatly reduces the number of IOPS to the disk thereby increasing effective throughput.

## Consistency Model

Before sharding or moving tables to different keyspaces, the application needs to be verified (or changed) such that it can tolerate the following changes:

* Cross-shard reads may not be consistent with each other. Conversely, the sharding decision should also attempt to minimize such occurrences because cross-shard reads are more expensive.
* In "best-effort mode", cross-shard transactions can fail in the middle and result in partial commits. You could instead use "2PC mode" transactions that give you distributed atomic guarantees. However, choosing this option increases the write cost by approximately 50%.

Single shard transactions continue to remain ACID, just like MySQL supports it.

If there are read-only code paths that can tolerate slightly stale data, the queries should be sent to REPLICA tablets for OLTP, and RDONLY tablets for OLAP workloads. This allows you to scale your read traffic more easily, and gives you the ability to distribute them geographically.

This trade-off allows for better throughput at the expense of stale or possibly inconsistent reads, since the reads may be lagging behind the primary, as data changes (and possibly with varying lag on different shards). To mitigate this, VTGate servers are capable of monitoring replica lag and can be configured to avoid serving data from instances that are lagging beyond X seconds.

For a true snapshot, queries must be sent to the primary within a transaction. For read-after-write consistency, reading from the primary without a transaction is sufficient.

To summarize, these are the various levels of consistency supported:

* `REPLICA/RDONLY` read: Servers can be scaled geographically. Local reads are fast, but can be stale depending on replica lag.
* `PRIMARY` read: There is only one worldwide primary per shard. Reads coming from remote locations will be subject to network latency and reliability, but the data will be up-to-date (read-after-write consistency). The isolation level is `READ_COMMITTED`.
* `PRIMARY` transactions: These exhibit the same properties as PRIMARY reads. However, you get REPEATABLE_READ consistency and ACID writes for a single shard. Support is planned for cross-shard Atomic transactions.

As for atomicity, the following levels are supported:

* `SINGLE`: disallow multi-db transactions.
* `MULTI`: multi-db transactions with best effort commit.
* `TWOPC`: multi-db transactions with 2PC commit.

### No active-active Replication

Vitess doesn’t support active-active replication setup (previously called multi-master). It has alternate ways of addressing most of the use cases that are typically solved by such a configuration.

* Scalability: There are situations where active-active gives you a little bit of additional runway. However, since all writes have to eventually be applied to all writable servers, it’s not a sustainable strategy. Vitess addresses this problem through sharding, which can scale indefinitely.
* High availability: Vitess has native capability for detecting primary failures and performing a failover to a new primary within seconds of failure detection. This is usually sufficient for most applications.
* Low-latency geographically distributed writes: This is one case that is not addressed by Vitess. The current recommendation is to absorb the latency cost of long-distance round-trips for writes. If the data distribution allows, you still have the option of sharding based on geographic affinity. You can then setup primaries for different shards to be in different geographic locations. This way, most of the primary writes can still be local.

## Multi-cell

Vitess is meant to run in multiple data centers / regions / cells. In this part, we'll use "cell" to mean a set of servers that are very close together, and share the same regional availability.

A cell typically contains a set of tablets, a vtgate pool, and app servers that use the Vitess cluster. With Vitess, all components can be configured and brought up as needed:

* The primary for a shard can be in any cell. If cross-cell primary access is required, vtgate can be configured to do so easily (by passing the cell that contains the primary as a cell to watch).
* It is not uncommon to have the cells that can contain the primary be more provisioned than read-only serving cells. These *primary-capable* cells may need one more replica to handle a possible failover, while still maintaining the same replica serving capacity.
* Failing over from a primary in one cell to a primary in a different cell is no different than a local failover. It has an implication on traffic and latency, but if the application traffic also gets re-directed to the new cell, the end result is stable.
* It is also possible to have some shards with a primary in one cell, and some other shards with their primary in another cell. vtgate will just route the traffic to the right place, incurring extra latency cost only on the remote access. For instance, creating U.S. user records in a database with primaries in the U.S. and European user records in a database with primaries in Europe is easy to do. Replicas can exist in every cell anyway, and serve the replica traffic quickly.
* Replica serving cells are a good compromise to reduce user-visible latency: they only contain replica servers, and primary access is always done remotely. If the application profile is mostly reads, this works really well.
* Not all cells need `rdonly` (or batch) instances. Only the cells that run batch jobs, or OLAP jobs, really need them.

Note that Vitess uses local-cell data first, and is very resilient to any cell going down (most of our processes handle that case gracefully).
