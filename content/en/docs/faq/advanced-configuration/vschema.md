---
title: Vschema
weight: 5
---

## How do you select your sharding key for Vitess?

It is important to choose a strong sharding key aka primary Vindex when creating your VSchema, so the qualities you should look at are the following:
- Frequency in WHERE clause of queries
- Uniqueness (of the mapping function) 
	- This means that a vindex will map a column value to only one keyspace ID (or none at all)
- Co-locating rows for joins and for single-shard transactions
	- This means using the same primary vindex for multiple tables, as all rows tied to the same primary index will automatically be located in the same shard due to the uniqueness property of the vindex map
- High cardinality
	- This means producing a sufficiently large number of keyspace IDs, which will give you finer control for rebalancing load through re-sharding

You can read more about how to select your primary vindex in this [blog post](https://vitess.io/blog/2019-02-07-choosing-a-vindex/).

## How can you update or change your vschema?

Vitess provides a CLI command [ApplyVSchema](https://vitess.io/docs/reference/programs/vtctldclient/vtctldclient_applyvschema/) to make updates to the vschema within Vitess.

## Without a Vschema how can table and schema routing work?

There are a couple of special cases for when you don’t have a VSchema in place. 

For example, if you add a table called foo to an unsharded keyspace called ks1 the following routing will enable you to access the table:
1. `use ks1; select * from foo;`
2. From the unqualified schema using `select * from ks1.foo;`
3. As long as you have only one keyspace, you can use `select * from foo;` in anonymous mode.

However, if you have more than one keyspace you will not be able to access the table from the unqualified schema using `select * from foo` until you add the table to the VSchema.

For a sharded keyspace you will not be able to access the table until you have a VSchema for it. However, you will be able to see it in `show tables`.
