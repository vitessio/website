---
author: 'Andrés Taylor'
date: 2024-07-22
slug: '2024-09-05-grouping-and-aggregations-on-vitess'
tags: ['Vitess', 'PlanetScale', 'MySQL', 'Query Serving', 'Vindex', 'plan', 'execution plan', 'explain', 'optimizer']
title: 'Grouping and Aggregations on Vitess'
description: "How I implemented an optimization by delaying another optimization"
---

I love my job. One of the best feelings is when I find an interesting paper and use it to solve a real problem. It feels like I found a cheat code. Instead of having to do a lot of hard thinking, I can just stand on the shoulders of really big people and take a shortcut. Here, I want to share a recent project that I could solve using a public paper.

## Sharding databases

Vitess is a database proxy that creates an illusion of a single database, when in reality the query is sent to multiple MySQL instances. This is called [sharding](https://vitess.io/docs/reference/features/sharding/).

Vitess is not just a dumb proxy layer though — it can also run some of the operations instead of sending them on. We want to delegate as much work as possible to MySQL — it is much faster than Vitess at doing all the database operations, including grouping and aggregation. When possible, we want work to be done there. While planning a query, the planner tries pushing as much work down to MySQL as possible. Sometimes it’s not possible to push work into any single MySQL instance because no single instance has all the data necessary.

In these cases, we can actually perform most of the normal database operations at the proxy level (called [VTGate](https://vitess.io/docs/13.0/concepts/vtgate/) in Vitess lingo) — we can do joins, filter out rows, sort data, and much more. We can also do grouping and aggregation in VTGate. We have a module, called 'evalengine', that is built to exactly mimic the logic of MySQL expressions. So when needed, we can do almost anything on the VTGate, we just need the base data from MySQL.

## Think globally, act locally

Back to aggregations across shards. Let’s say you have a `user` table that is too large to fit into a single database, so you have sharded it. Now a Vitess user asks for the number of users in the whole logical, sharded database. We could fetch all the rows and just count them, but that would be slow and inefficient. So instead we break aggregation into local and global aggregation. The local part is what we can send down to MySQL, and the global aggregation is aggregating the aggregates. So, if the user asked for `SELECT count(*) FROM user`, Vitess will send down a `count(*)` to each shard, and then do a SUM on all incoming answers.

This is something that Vitess has been able to do for a long time. But if you had joins or subqueries or anything else other than a simple `SELECT ... FROM ... GROUP BY`, with a single table, most of the time you were out of luck.

During one of our paper reading sessions, we looked at the paper [Orthogonal Optimization of Subqueries and Aggregation](https://dl.acm.org/doi/abs/10.1145/376284.375748), by Cesar A. Galindo-Legaria and Milind M. Joshi from Microsoft. It talks about how it’s sometimes preferable to do aggregation before performing joins. In some cases this could save on how much work the join operator had to do and so lowered the total cost of the plan. In the paper, they spent some time talking about what needed to be done to be able to push aggregation under a join.

To us, this was exactly what we were looking for. We had to do the join at the VTGate — no going around that fact. But by using the algorithm described in this paper, we were able to break the aggregation into smaller pieces (local aggregates) that could be pushed down under the join to the MySQL layer.

## An example would be helpful here

So, what is the secret sauce? How do you push down `count(*)` under a join? I’ll use a very simple database as an example.

The database has two tables: **order** and **order_line**.

Each `order` comes from a single office, and each order can have one or more `order_line` corresponding rows. The database is sharded, and when sharding one has to choose a sharding key. This is the column value that will be used to decide which shard the row should live in.

`order` is shared by id, and `order_line` is sharded by its own id. If it was sharded by order_id, the join could be pushed down to MySQL, since we would know that the corresponding rows existed in the same shard. Unfortunately, it isn’t, so we will have to do joins between these two tables at the VTGate level.

Let’s use this example query. It creates a report with how much has been sold per office:

```sql
SELECT order.office, sum(order_line.amount)
FROM order JOIN
    order_line ON order.id = order_line.order_id
GROUP BY order.office
```

Route is the operator that sends a query to one or more shards. The `order` and the `order_line` join cannot be merged into a single route, so we have to do the joining and some of the aggregation at the VTGate level. The routing planner has decided that the best plan is to first query the `order` table and then for each row in this table, we’ll issue a query against the `order_line` table. So after planning how to send the queries, we have this plan:

This is a VTGate execution plan for the query above. Everything under a Route is going to be sent to the underlying MySQL as a single query. Everything above the route is evaluated at the VTGate level. The plan so far says that we’ll have to send a scatter query to the `orders` keyspace, hitting all shards.

The join is a nested loop join, which means that we’ll execute the query on the left-hand side (LHS) of the Join, and using that result we’ll issue queries on the right-hand side (RHS), one query per row. Now it’s time to do the aggregation planning.

We’ll take the example query and go over it from back to front. While doing this, we’ll figure out what we should send to the LHS of the join.

The original query was grouping on `order.office` — we can keep that column in the LHS grouping.

Since we are doing a join on `order.id`, we need to add that column to the select list and to the grouping. Otherwise, this column would not be available to the join.

The `SUM` aggregation can’t be sent to the LHS — we’ll send that to the RHS.

Since we are grouping on the left side, we need to keep track of how many rows were included in each group. It’ll make more sense when we later use these numbers to produce the final result. So the execution plan so far looks like:

## Show me the results

To make it easier to follow, I’ll show what each operator will produce, and how we go about merging the separate results into the result the user asked for.

The query on the LHS route will produce results that look something like this:

| order.office | order.id | count(\*) |
| ------------ | -------- | --------- |
| 1            | 1        | 2         |
| 2            | 2        | 3         |

Ignore the fact that we have multiple rows per `order.id`. Not really important, it’s just so we can have a more interesting result to work with.

From these two rows, VTGate will issue two queries against the RHS, only changing the `__order_id` argument between the two.

The two results will be:

> For order.id = 1,

| sum(order_line.amount) |
| ---------------------- |
| 5                      |
| 3                      |

> For order.id = 2,

| sum(order_line.amount) |
| ---------------------- |
| 10                     |
| 7                      |

So finally, the join will produce the joined results:

| order.office | count(\*) | sum(order_line.amount) |
| ------------ | --------- | ---------------------- |
| 1            | 2         | 5                      |
| 1            | 2         | 3                      |
| 2            | 3         | 10                     |
| 2            | 3         | 7                      |

It’s not returning `order.id`, since we only needed it for the join. This is still not the result we want. The user did not ask for `count(*)`, and the grouping looks wrong. We can’t return multiple rows with the same `order.office` value.

The next step is to combine the `count(*)` from the LHS, and the `sum(order_line.amount)` from the RHS. We simply multiply them together. This is what the `Project` operator will take care of; it allows the use of the evalengine mentioned above to evaluate arithmetic operations at the vtgate level.

![](/assets/blog/content/vitess-grouping/Vitess-step-6.svg)

The results coming out from the Project operator will look something like this:

| order.office | sum(order_line.amount)\*count(\*) |
| ------------ | --------------------------------- |
| 1            | 10                                |
| 1            | 6                                 |
| 2            | 30                                |
| 2            | 21                                |

Finally, we just have to do a bit of grouping and sum the sums.

| order.office | sum(sum(order_line.amount)\*count(\*)) |
| ------------ | -------------------------------------- |
| 1            | 16                                     |
| 2            | 51                                     |

This is the result that the user asked for.

The final plan ended up being:

![](/assets/blog/content/vitess-grouping/Vitess-step-7.svg)

## Parting words

This experience is one I’ve had many times in the past. Someone out there has done a ton of work on something closely related to what we are doing, and all we have to do is adapt the algorithm to our circumstances. For the type of work that we are doing, trying to keep up to date with academia just makes sense.

More often than not, we are not even actively looking for a solution when we stumble across it while reading papers. If I remember correctly, I suggested this paper because I was looking for a way to rewrite subqueries to other operations, and came across the splitting of aggregations across joins. If you are curious, [review vitessio/vitess #9643](https://github.com/vitessio/vitess/pull/9643).

(This blog post was earlier published on the [PlanetScale blog](https://planetscale.com/blog/grouping-and-aggregations-on-vitess).)
```
