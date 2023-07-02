---
title: Vschema
description: Frequently Asked Questions about Vitess
weight: 5
---

## How do you select your primary key for Vitess?

It is important to choose a strong primary Vindex when creating your VSchema, so the qualities should you look at are the following:
- Frequency in WHERE clause of queries
- Uniqueness (of the mapping function) 
	- This means that a vindex will map a column value to only one keyspace ID (or none at all)
- Co-locating rows for joins and for single-shard transactions
	- This means using the same primary vindex for multiple tables, as all rows tied to the same primary index will automatically be located in the same shard due to the uniqueness property of the vindex map
- High cardinality
	- This means producing a sufficiently large number of keyspace IDs, which will give you finer control for rebalancing load through resharding

You can read more detail about how to select your primary key [here](https://vitess.io/blog/2019-02-07-choosing-a-vindex/).

## How can you update or change your vschema?

We recommend using ApplySchema and ApplyVSchema in order to make updates to schemas within Vitess. It is also important to note that you will need to update both your MySQL database schema as well as your VSchema. 

The [ApplySchema](https://vitess.io/docs/reference/programs/vtctl/#applyvschema) command applies a schema change to the specified keyspace on every primary tablet, running in parallel on all shards. Changes are then propagated to replicas. The ApplyVSchema command applies the specified VSchema to the keyspace. The VSchema can be specified as a string or in a file. You can read more about the process to use these commands [here](https://vitess.io/docs/reference/features/schema-management/#changing-your-schema). 

There are a few ways that changes can be made to your schemas within Vitess. If you don’t want to use ApplySchema you can read more about the different methods to make updates [here](https://vitess.io/docs/user-guides/schema-changes/).

## Without a Vschema how can table and schema routing work?

There are a couple of special cases for when you don’t have a VSchema in place. 

For example, if you add a table called foo to an unsharded keyspace called ks1 the following routing will enable you to access the table:
1. USE ks1; select * from foo; 
2. From the unqualified schema using select * from ks1.foo; 
3. As long as you have only one keyspace, you can use select * from foo in anonymous mode 

However, if you have more than one keyspace you will not be able to access the table from the unqualified schema using select * from foo until you add the table to VSchema. 

For a sharded keyspace will not be able to access the table until you have a VSchema for it. However, you will be able to see it in show tables.
