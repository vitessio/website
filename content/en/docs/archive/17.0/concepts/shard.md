---
title: Shard
---

A *shard* is a subset of a keyspace. A keyspace will always contain one or more shards. A shard typically contains one MySQL primary and potentially many MySQL replicas.

Each MySQL instance within a shard has identical data (if we ignore any replication lag). The replicas can serve read-only traffic (with eventual consistency guarantees), execute long-running data analysis queries, or perform administrative tasks (backup, restore, diff, etc.).

An *unsharded* keyspace is a keyspace with only a single shard. Vitess names the shard `0` (or sometimes `-`) by convention. When sharded, a keyspace has `N` shards with non-overlapping data. The number of shards in a keyspace can vary depending on the use-case and load characteristics, some Vitess users have hundreds of shards in some keyspaces.

## Shard Naming

Shard names have the following characteristics:

* They represent a range in unsigned integer space, where the left number is included, but the right is not.
* Their notation is hexadecimal.
* They are left justified, and right-padded with zeros.
* A `-` prefix means: anything less than the right value.
* A `-` postfix means: anything greater than or equal to the LHS value.
* A plain `-` denotes the full keyrange.

Thus: `-80` == `00-80` == `0000-8000` == `000000-800000` == `0000000000000000-8000000000000000`

`80-` is not the same as `80-FF`. This is why:

`80-FF` == `8000-FF00`. Therefore `FFFF` will be out of the `80-FF` range.

`80-` means: ‘anything greater than or equal to `0x80`

A `hash` type vindex produces an unsigned 64 bit integer as output. This means that all integers **less** than `0x8000000000000000` will fall in shard `-80`. Any number with the highest bit set will be >= `0x8000000000000000`, and will therefore belong to shard `80-`.

This left-justified approach allows you to have keyspace ids of arbitrary length. However, the most significant bits are the ones on the left.

For example an `md5` hash produces 16 bytes. That can also be used as a keyspace id.

A `varbinary` of arbitrary length can also be mapped as is to a keyspace id. This is what the `binary` vindex does.

## Resharding

Vitess supports [resharding](../../user-guides/configuration-advanced/resharding), in which the number of shards is changed on a live cluster. This can be either splitting one or more shards into smaller pieces, or merging neighboring shards into bigger pieces.

During resharding, the data in the source shards is copied into the destination shards, allowed to catch up on replication, and then compared against the original to ensure data integrity. Then the live serving infrastructure is shifted to the destination shards, and the source shards are deleted.

**Related Vitess Documentation**

* [Resharding User Guide](../../user-guides/configuration-advanced/resharding)
