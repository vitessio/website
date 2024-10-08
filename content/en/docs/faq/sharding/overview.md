---
title: Overview
description: Frequently Asked Questions about Vitess
weight: 1
---

## Why do auto-increment columns not work in sharded Vitess?

Auto-increment columns do not work very well for sharded tables. Vitess sequences solve this problem. Sequence tables must be specified in the VSchema and then tied to table columns. At the time of insert, if no value is specified for such a column, VTGate will generate a number for it using the sequence table.

Vitess also supports sequence generators that can be used to generate new ids that work like MySQL auto increment columns. The VSchema allows you to associate table columns to sequence tables.

## What is resharding? How does it work?

Vitess supports resharding, in which the number of shards is changed on a live cluster. This can be either splitting one or more shards into smaller pieces, or merging neighboring shards into bigger pieces.

During resharding, the data in the source shards is copied into the destination shards, allowed to catch up on replication, and then compared against the original to ensure data integrity. Then the live serving infrastructure is shifted to the destination shards, and the source shards are deleted.

## How do reparents work in Vitess?

Reparenting is the process of changing a shard’s primary tablet from one host to another or changing a replica tablet to have a different primary. Reparenting can be initiated manually or it can occur automatically in response to particular database conditions. Vitess supports two types of reparenting: [Active reparenting](https://vitess.io/docs/user-guides/configuration-advanced/reparenting/#active-reparenting) and [External reparenting](https://vitess.io/docs/user-guides/configuration-advanced/reparenting/#external-reparenting).
- Active reparenting occurs when Vitess manages the entire reparenting process. There are two types of active reparenting that can be done: [Planned reparenting](https://vitess.io/docs/user-guides/configuration-advanced/reparenting/#plannedreparentshard-planned-reparenting) and [Emergency reparenting](https://vitess.io/docs/user-guides/configuration-advanced/reparenting/#emergencyreparentshard-emergency-reparenting).
- External reparenting occurs when another tool handles the reparenting process, and Vitess just updates its components to accurately reflect the new primary-replica relationships.

You can read more about reparenting in Vitess [here](https://vitess.io/docs/user-guides/configuration-advanced/reparenting/).

## How are shards named?

Shard names have the following characteristics:

- They represent a range, where the left number is included, but the right is not.
- Their notation is hexadecimal.
- They are left justified.
- A - prefix means: anything less than the right value.
- A - postfix means: anything greater than or equal to the LHS value.
- A plain - denotes the full keyrange.

An example of a shard name is -80 and following the rules above this means:  -80 == 00-80 == 0000-8000 == 000000-800000

Similarly 80- is not the same as 80-FF because 80-FF == 8000-FF00. Therefore FFFF will be out of the 80-FF range as 80- means: ‘anything greater than or equal to 0x80

A hash vindex produces an 8-byte number. This means that all numbers less than 0x8000000000000000 will fall in shard -80. Any number with the highest bit set will be >= 0x8000000000000000, and will therefore belong to shard 80-.

## What does “/0” or “-”mean?

“0” or “-” indicates that the keyspace in question is unsharded. Or phrased in a slightly different manner this indicates that a single shard covers the entire keyrange. Note, the reason both “0” and “-” are used is because you can’t merge into shard “0” only “-”.

On the other hand a sharded cluster will have multiple keyranges, for example “-80” and “80-” if you have two shards. Note, that you can still manually target a single shard from your sharded cluster. You can read more about that [here](https://vitess.io/docs/faq/operating-vitess/queries/#can-i-address-a-specific-shard-if-i-want-to).