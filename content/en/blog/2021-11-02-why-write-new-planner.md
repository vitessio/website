---
author: 'Andres Taylor'
date: 2021-11-02
slug: '2021-11-02-why-write-new-planner'
tags: ['Vitess','MySQL', 'DDL', 'query', 'plan', 'examine', 'explain', 'optimizer']
title: 'Why write a new planner'
description: "Better query planning made possible with a new generation planner" 
---
## Query planning is hard
Have you ever wondered what goes on behind the scenes when you execute a SQL query? What steps are taken to access your data?

In this article, I'll talk about the history of Vitess's V3 query planner, why we created a new query planner, and the development of the new Gen4 query planner.

[Vitess](https://vitess.io) is a horizontally scalable database solution which means that a single table can be spread out across multiple database instances. In SQL, queries are declarative. In other words, they don’t specify how to access the data, just what data is sought. To actually run the query, it needs to first be planned.

For simple queries touching a single or a pair of tables, the plan is usually pretty straightforward. But for more complicated queries using lots of joins, and maybe derived tables, subqueries, and aggregations - the task is daunting. There may be thousands of possible ways to execute a query.

Just like a normal database server, Vitess has its own query planner. The query planner is a big part of the SQL magic - it frees developers from having to understand how to select the best access strategy, and they can focus on what they need. For simple queries, this may not be of much value, but for complicated queries, this saves developers a lot of time and energy.

When I started working on Vitess, the V3 query planner had recently been finished. It was a really big step up from its predecessor, making it possible for users to not have to think about which shard they needed to get data from. It was mostly written by one of the Vitess' founders - Sugu Sougoumarane.

I've had the good fortune to have worked on a couple of different query planners before I started working on Vitess. I wrote my first query planner without first studying what the academics had to say about how to do it. It was a very difficult task, and the end result was not great. 

## Standing on the shoulders of giants

Some time later, the team I was working with had the chance to start a cooperation with [Andrey Gubichev](https://scholar.google.com/citations?user=7qyHAfAAAAAJ) from TUM, the technical university in München, Germany. He helped us read the appropriate papers and implement them. To me, who had just written a planner without really knowing what I was doing, this felt like cheating. I did not have to reinvent the wheel for every problem - there were tons of papers that we could just read and implement for most problems we came across.

The Vitess V3 planner was similarly written without using the benefit of decades of papers on query planning. An incredible feat, but the planner was not using a lot of the clever tricks that people have come up with over the years.


In the beginning of 2021, I felt like I understood Vitess well enough to start writing a new planner for it. At first, it was just my own curiosity that got me started. I started in my spare time and weekends at first, and I was soon joined by the query serving team working on Vitess.

A few months later, PlanetScale decided that this was important enough to make it our main project.

## We need a new planner

Why did we choose to work on a new planner if V3 was already performing well? One of the big selling points of Vitess is that it is a drop-in replacement for MySQL. You can take your single instance database, stick [Vitess with a good vschema](https://vitess.io/docs/reference/features/vschema/) in front of it, and the application should not really notice a difference. The app can use the same connection library, the same queries and hopefully receive the same results.

Unfortunately, the V3 planner has a long list of unsupported queries that it does not handle. We needed to expand the supported set of queries, but V3 was getting really difficult to work on. So we decided that a new planner was needed. To make sure that the different planner versions would not be confused with the version of Vitess, we switched to talk about “Generation 4”. 

Thus, the “Gen4” planner was born.

In order to create a planner that we could work with in the long run, we had to split the planner into several smaller parts. This decomposition was designed to make the whole development cycle easier and faster.  For example, semantic analysis makes the rest of the planner simpler since it can answer the questions around scoping, types, and which tables columns belong to. We can improve the semantic analysis without having to change anything else in the planner.

In the old V3 planner, this information was produced while planning the query, making it much harder to test and improve in isolation. We have, in a similar vein, introduced intermediate representations along the way. The query is transformed and worked on using different data structures. This makes it easier to test and work on small parts of the system.

With the release of Vitess V12.0, the Gen4 planner is finally at parity with the V3 planner, meaning that all the queries that the old planner could handle, the new planner can also plan. There are already quite a few queries that the new planner can tackle that the old planner would not take on, and that list is quickly growing. Here are a couple of examples:

```sql
select user.id 
from user left join 
	user_extra on user.col = user_extra.col 
where user_extra.foobar = 5

```

The V3 planner is unable to plan this query, but Gen4 realises that the **WHERE** predicate actually turns the outer join into an inner join, and has no problem planning it.

```sql
select user.a, count(user_extra.a) 
from user join 
	user_extra on user.id = user_extra.friend_id
group by user.a
```

Here the V3 engine is struggling to do aggregation after having to do a cross-shard query - the new planner doesn’t mind.

The last example:

```sql
select col 
from user 
where exists(
	select user_id 
	from user_extra 
	where user_id = 3 and 
user_id < user.id)
```

This is a correlated subquery - the user_id < user.id  in the subquery can’t be evaluated independently, and this trips up the V3 planner. The new planner correctly produces a semi-join to solve this type of query.

In terms of performance, the new planner takes about double the time that the old planner took to plan queries. This is not great, but since we cache plans, this cost is not prohibitive - as long as the plans are good, the cost/value tradeoff should still be positive. Most of the time, a query is planned a single time and then reused for hundreds or thousands of times.

The other side of performance is how fast the plans actually run. The V3 planner used a left-to-right strategy to plan queries, which is similar to using the [`JOIN_FIXED_ORDER` planner hint in MySQL](https://dev.mysql.com/doc/refman/8.0/en/optimizer-hints.html) - the first table in the FROM clause is joined with the second, and the second with the third, etc, etc. Gen4, on the other hand, evaluates a lot more options. It tries joining all tables with all other tables, and in both directions. This means that it often finds better plans than the old planner would.

## Final thoughts
The query planner in Vitess is a critical part of the processing pipeline that is involved in answering SQL queries. With the Gen4 planner, we have invested considerable time into making sure we have a planner that can produce good plans today, and can grow to handle many more types of queries in the future.
