---
title: "What is a Vindex and how does it work?"
shorten_nav_links: true
notoc: true
weight: 2
---

A Vindex provides a way to map a column value to a keyspace ID. Since each shard in Vitess covers a range of keyspace ID values, this mapping can be used to identify which shard contains a row.

The advantages of Vindexes stem from their flexibility:

* A table can have multiple Vindexes.
* Vindexes can be NonUnique, which allows a column value to yield multiple keyspace IDs.
* Vindexes can be a simple function or be based on a lookup table.
* Vindexes can be shared across multiple tables.
* Custom Vindexes can be created and used, and Vitess will still know how to reshard using such Vindexes.

The Vschema contains the Vindex for any sharded tables. Every Vschema must have at least one Vindex, called the Primary Vindex, defined. A variety of other Vindexes are also available to choose from, with different trade-offs, and you can choose one that best suits your needs. You can read more about other Vindexes [here](https://vitess.io/docs/reference/features/vindexes/).
