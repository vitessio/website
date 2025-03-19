---
title: "How do you select your sharding key for Vitess?"
shorten_nav_links: true
notoc: true
weight: 1
---

It is important to choose a strong sharding key aka primary Vindex when creating your VSchema, so the qualities you should look at are the following:
- Frequency in WHERE clause of queries
- Uniqueness (of the mapping function) 
	- This means that a vindex will map a column value to only one keyspace ID (or none at all)
- Co-locating rows for joins and for single-shard transactions
	- This means using the same primary vindex for multiple tables, as all rows tied to the same primary index will automatically be located in the same shard due to the uniqueness property of the vindex map
- High cardinality
	- This means producing a sufficiently large number of keyspace IDs, which will give you finer control for rebalancing load through re-sharding

You can read more about how to select your primary vindex in this [blog post](https://vitess.io/blog/2019-02-07-choosing-a-vindex/).
