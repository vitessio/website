---
author: 'Andrés Taylor'
date: 2024-09-13
slug: '2024-09-13-an-interesting-optimization'
tags: ['Vitess', 'PlanetScale', 'MySQL', 'Query Serving', 'Vindex', 'plan', 'execution plan', 'explain', 'optimizer']
title: 'A Tale of Two Plans: Exploring Query Execution with vexplain Trace'
description: "Database query optimization is a complex process, often operating behind the scenes. In this post, we use vexplain trace to examine how turning off a single rewrite rule in the query planner affects execution plans. By comparing two different plans for the same query, we'll demonstrate how vexplain can provide insights into the decision-making process of the query optimizer. This exploration will be useful for database administrators, developers, and anyone interested in understanding query performance. Join us as we use vexplain to shed light on the subtle yet impactful changes in query execution strategies."
---

## Introduction

SQL is by far the most dominating query language for databases. One of the reasons for this is because it allows for declarative querying, where you specify what you want, not how to get it. This is in contrast to imperative programming languages, where you specify the steps to get the result. The database query planner is responsible for figuring out the best way to execute a query, given the schema, indexes, and statistics.

The output of the planning process is an execution plan that describes how the database will execute the query. The plan is a tree of operations, where each node represents a step in the query execution. The database query optimizer is responsible for generating the best plan possible, given the constraints and statistics available.

## The Vitess Query Optimizer

The planner we use works by first constructing an pretty naive execution plan from the query. Then, it applies a series of rewrite rules to transform the plan into a more efficient one. The goal is to push as much work as possible down to the data sources, MySQL, and to minimize the amount of data that needs to be fetched and processed.

The best execution plan we can produce is one where all work is performed by MySQL, and vtgate just routes the queries to the right MySQL instances.

This is not always possible, and sometimes we have to perform some work in vtgate. This is the case when we have to join data from different shards, or when we have to aggregate data from multiple shards.

## Comparing Two Execution Plans
In order to make it easier to easy to view execution plans, we have developed a tool called `vexplain`. This tool takes a query and returns information about how the query would be executed. 

It's not always easy to compare execution plans and understand the differences between them. This is where `vexplain trace` comes in handy. It allows you to see the execution plan for a query, and see how the data flows through the plan.

## An Example Would Be Nice

To illustrate how `vexplain trace` can be used to compare two execution plans, let's consider a query: TPCH Query #8. The TPCH benchmark is a standard benchmark for testing the performance of database systems. Query #8 is a complex query that involves multiple joins and aggregations.

Running it with the normal planning rules, we get the following execution plan:

```json
```


## Performance Impact
To quantify the impact of our query plan changes, we ran benchmarks comparing the performance of our query with and without the pushdown optimization. The results are quite revealing:

```goos: darwin
goarch: arm64
pkg: vitess.io/vitess/go/test/endtoend/vtgate/queries/tpch
cpu: Apple M1 Ultra
│   without    │            with-pushdown             │
│    sec/op    │    sec/op     vs base                │
Query-20   1237.2m ± 6%   856.5m ± 22%  -30.77% (p=0.000 n=10)
```

These benchmark results demonstrate a significant performance improvement when the pushdown optimization is enabled:

*Execution Time*: Without the optimization, the query took an average of 1237.2 milliseconds to execute. With the pushdown enabled, this dropped to 856.5 milliseconds.
*Performance Gain*: This represents a 30.77% reduction in execution time, a substantial improvement that could have significant real-world impact, especially for frequently run queries or in high-load scenarios.
