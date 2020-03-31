---
title: Shard
---

A *shard* is a division within a keyspace. A shard typically contains one MySQL master and many MySQL slaves.

Each MySQL instance within a shard has the same data (excepting some replication lag). The slaves can serve read-only traffic (with eventual consistency guarantees), execute long-running data analysis tools, or perform administrative tasks (backup, restore, diff, etc.).

An unsharded keyspace has effectively one shard. Vitess names the shard `0` by convention. When sharded, a keyspace has `N` shards with non-overlapping data.

## Resharding

Vitess supports [dynamic resharding](../../reference/sharding#resharding), in which the number of shards is changed on a live cluster. This can be either splitting one or more shards into smaller pieces, or merging neighboring shards into bigger pieces.

During dynamic resharding, the data in the source shards is copied into the destination shards, allowed to catch up on replication, and then compared against the original to ensure data integrity. Then the live serving infrastructure is shifted to the destination shards, and the source shards are deleted.

