---
author: 'Andrés Taylor'
date: 2025-01-25
slug: 'optimizing-sharding-strategies-vitess'
tags: ['Vitess', 'Sharding', 'MySQL', 'Query Optimization', 'Database Scaling', 'Vindex', 'VExplain', 'Performance Analysis', 'SQL Planning']
title: 'Mastering Sharding in Vitess: Tools, Strategies, and Best Practices'
description: "Explore how to optimize sharding strategies in Vitess for scalable query performance, leveraging tools like `vexplain` and `vt` for deep analysis and schema design."
---

## From Single MySQL to Sharded Vitess: A Hands-On Guide to VSchema Design

So you have a successful application that is using a large database that keeps growing?
Congratulations! That's a nice problem to have.

In this blog post, I'll share how you can go from an existing database and query log to a vschema, and some pitfalls to watch out for.
I'm going to assume you already know what database sharding is and how Vitess does it.
If you haven’t read Ben’s excellent [post about sharding](https://planetscale.com/blog/database-sharding), I recommend checking it out first to get the background—you can always return here afterward.

### Analyzing joins, filtering, grouping and transactions

When the Vitess planner analyses queries, it looks at joins, the `WHERE` clause, and the `GROUP BY` clause to figure out how to split up a query across shards.
Additionally, it's important to make sure that transactions don't span multiple shards. If they do, they will be upgraded to distributed atomic transactions that are much more expensive that single shard transaction.

Using the `vt` tooling, these things are easy to analyze: `vt keys` and `vt transactions` take a query log as input and produces json outputs that can then be viewed using `vt summarize` which will produce a markdown report from the json input files.

#### `vt keys`

In Vitess, we have `vexplain keys <query>`, a command that takes a query and analyses it:

```sql
vexplain keys select *
  from orders o 
    join customers c on o.customer_id = c.id
```

This will output columns used by the query that might be interesting to test as sharding keys.

```json
{
  "statementType": "SELECT",
  "joinColumns": [
    "customers.id =",
    "orders.customer_id ="
  ],
  "selectColumns": [
    "customers.`name`",
    "customers.created_at",
    "customers.email",
    "customers.id",
    "orders.`status`",
    "orders.created_at",
    "orders.customer_id",
    "orders.id",
    "orders.total_amount"
  ]
}
```

To do this on a full query log, we use `vt keys`. Without having to start a Vitess cluster, you get the `vexplain keys` output for all queries in a log.

