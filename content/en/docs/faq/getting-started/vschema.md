---
title: VSchema
description: Frequently Asked Questions about Vitess
weight: 5
---

## What is a VSchema?

VSchema is short for Vitess Schema and it describes how to shard data within Vitess. 

In contrast to a traditional database schema that contains metadata about tables, a VSchema contains metadata about how tables are organized across shards. This information is used for routing queries and also during resharding operations. 

Simply put, it contains the information needed to make Vitess look and act like a single database server.

For example, the VSchema will contain the information about the sharding key for each sharded table. When the application issues a query with a WHERE clause that references the key, the VSchema information will be used to route the query to the appropriate shard.

## What is a primary Vindex and how does it work?

The Primary Vindex for a table is analogous to a database primary key. 

Every sharded table must have one defined. A Primary Vindex must be unique: given an input value, it must produce a single keyspace ID. At the time of an insert to the table, the unique mapping produced by the Primary Vindex determines the target shard for the inserted row.

In Vitess, the choice of Vindex allows control of how a column value maps to a keyspace ID. In other words, a Primary Vindex in Vitess not only defines the Sharding Key, but also decides the Sharding Strategy.

Uniqueness for a Primary Vindex does not mean that the column has to be a primary key or unique key in the MySQL schema for the underlying shard. You can have multiple rows that map to the same keyspace ID. The Vindex uniqueness constraint only ensures that all rows for a keyspace ID end up in the same shard.

## What is a Vindex and how does it work?

A Vindex provides a way to map a column value to a keyspace ID. Since each shard in Vitess covers a range of keyspace ID values, this mapping can be used to identify which shard contains a row. 

The advantages of Vindexes stem from their flexibility:

* A table can have multiple Vindexes.
* Vindexes can be NonUnique, which allows a column value to yield multiple keyspace IDs.
* Vindexes can be a simple function or be based on a lookup table.
* Vindexes can be shared across multiple tables.
* Custom Vindexes can be created and used, and Vitess will still know how to reshard using such Vindexes.

The Vschema contains the Vindex for any sharded tables. Every Vschema must have at least one Vindex, called the Primary Vindex, defined. A variety of other Vindexes are also available to choose from, with different trade-offs, and you can choose one that best suits your needs. You can read more about other Vindexes [here](https://vitess.io/docs/reference/features/vindexes/).

## How do I create a VSchema?

The ease of creation of a VSchema depends heavily on now your data model is constructed. 

For some data models, especially smaller and less complex ones, it can be less challenging to determine how to split the data between shards. A clear sharding key would be a column that is on most of the tables in your data model. If there is a clear sharding key then creating VSchema is as straightforward as specifying that column as the primary Vindex for each table. Common primary Vindexes tend to be user ID or customer ID.

For more complex data models most will have to investigate the patterns of common queries in order to determine what sharding keys to use. When investigating the most common queries you must identify what you want to optimize, as this influences heavily the determination of the sharding keys.

For example if you have a query accessing a table with two or more distinct query keys then it may be necessary to create a lookupvindex for the table to accommodate that query pattern.

Please do keep in mind that you don’t have to have Vindex to cover every query pattern;  just the most common. If you adhere to an 80:20 rule, where you scatter 20% of your queries across shards you shouldn’t see any major impacts depending on how you optimized your sharding keys.

## When do I need to use a VSchema?

For a very trivial setup where there is only one unsharded keyspace, there is no need to specify a VSchema because Vitess will know that there is nowhere to route a query except to the single shard.

However, once you have sharding, having a VSchema becomes a necessity. This is because a VSchema is needed to locate and place rows row each table in a sharded keyspace.

The Vitess distribution has a demo of VSchema operation [here](https://github.com/vitessio/vitess/tree/master/examples/demo).