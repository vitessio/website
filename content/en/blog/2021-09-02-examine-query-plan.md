---
author: 'Andres Taylor'
date: 2021-09-07
slug: '2021-09-07-examine-query-plan'
tags: ['Vitess','MySQL', 'DDL', 'query', 'plan', 'examine', 'explain', 'optimizer']
title: 'Examining query plans in MySQL and Vitess'
description: "How to examine query plans by Vitess optimizer plan" 
---
Originally posted at [Andres's blog.](http://systay.github.io/2021/08/27/explain-a-query.htm)

Traditional query optimizing is mostly about two things: first, in which order and from where to access data, and then how to then combine it.

You have probably seen the tree shapes execution plans that are produced from query planning. I’ll use an example from the MySQL docs, using `FORMAT=TREE` which was introduced in MySQL 8.0:
```sql
mysql> EXPLAIN FORMAT=TREE
    -> SELECT *
    ->     FROM t1
    ->     JOIN t2
    ->         ON (t1.c1 = t2.c1 AND t1.c2 < t2.c2)
    ->     JOIN t3
    ->         ON (t2.c1 = t3.c1)\G
*************************** 1. row ***************************
EXPLAIN: -> Inner hash join (t3.c1 = t1.c1)  (cost=1.05 rows=1)
    -> Table scan on t3  (cost=0.35 rows=1)
    -> Hash
        -> Filter: (t1.c2 < t2.c2)  (cost=0.70 rows=1)
            -> Inner hash join (t2.c1 = t1.c1)  (cost=0.70 rows=1)
                -> Table scan on t2  (cost=0.35 rows=1)
                -> Hash
                    -> Table scan on t1  (cost=0.35 rows=1)
```
Here we can see that the MySQL optimizer thinks the best plan is to start reading from `t1` using a table scan. It could have used an index, but since we are projecting every column `(SELECT *)`, it’s reading the full table.

This is hashed in the next step, and we know it is hashing on the `c1` column. This is then read by the hash join step, which will use the hash map to join data from t1 and t2 using the `t2.c1 = t1.c1` predicate.

Next we need to hash the results again, and the hash map created in the last step is used to join with `t3`.

The goal of the optimizer is to produce a plan that is as efficient as possible, touching as little data as possible to answer the query. This is done using statistics about table sizes and index content.

Finally, one more thing to take note of about the MySQL plans - the leaf operators table and index operations. That means pretty low level functionality - they can be scans, seeks and for indexes also lookups.

Planning in Vitess is very similar to this, but at the same time quite different.

Let me show you what a Vitess plan can look like:
```sql
mysql> EXPLAIN FORMAT=VITESS
    -> SELECT *
    ->     FROM t1
    ->     JOIN t2
    ->         ON (t1.c1 = t2.c1 AND t1.c2 < t2.c2)
    ->     JOIN t3
    ->         ON (t2.c1 = t3.c1)\G


+--------------+-----------------+----------+-------------+------------+-------+
| operator     | variant         | keyspace | destination | tabletType | query |
+--------------+-----------------+----------+-------------+------------+-------+
| Join         | Join            |          |             | UNKNOWN    |       |
| ├─ Route     | SelectScatter   | ks1      |             | UNKNOWN    | Q1    |
| └─ Route     | SelectUnsharded | ks2      |             | UNKNOWN    | Q2    |
+--------------+-----------------+----------+-------------+------------+-------+

Q1: select t1.c1, t1.c2, t2.c1 from t1, t2 where t1.c1 = t2.c2 AND t1.c2 < t2.c2
Q2: select t3.c1 from t3 where t3.c1 = :t2_c1
```
The Vitess optimizer is also looking for efficient plans, but since Vitess is a proxy, efficient mostly means interacting as little as possible with the underlying MySQL systems.

For this query, Vitess needs to fetch data from two keyspaces. `t1` and `t2` are sharded tables that are on the `ks1` keyspace, and accessing that data is done by sending the join between `t1` and `t2` to all the shards of `ks1`. The `t3` table is unsharded on the `ks2` keyspace, so the join has to be performed on the vtgate layer, and can’t be pushed down to MySQL.

What are some differences between these plans? The leaf operators of the Vitess plans are MySQL engines. The leaves also specify which shards need to be queried. In the plan above, we are doing a scatter for the query to `ks1`, which means that we’ll query all shards and then combine the results. For the `ks2` query, we are dealing with an unsharded (also known as single-sharded) keyspace, so we just send the query to that single shard.

How can we combine access to `t1` and `t2` into a single route? Is there not a chance that some rows on `t1` would match `t2` rows that are on a separate shard? The Vitess planner knows how the data is sharded, and knows when it is safe to merge queries like this, by inspecting the columns being compared.

Tables have sharding keys, and when the comparisons are on the same sharding key, we know that the rows from both tables will be placed in the same shard.

If the equality comparison between `t1` and `t2` was not between the sharding columns for these tables, the join would have been performed at the vtgate level.

When doing performance tuning on Vitess, `EXPLAIN FORMAT=VITESS` is a very helpful tool to fine tune individual queries.


