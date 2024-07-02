---
author: 'Andrés Taylor'
date: 2024-07-02
slug: '2024-07-02-an-interesting-optimisation'
tags: ['Vitess', 'PlanetScale', 'MySQL', 'Query Serving', 'Vindex', 'plan', 'execution plan', 'explain', 'optimizer']
title: 'Consistent Lookup Vindex: Achieving Data Consistency without 2PC'
description: "How I implemented an optimisation by delaying another optimisation"
---

# An Interesting Optimization

## Introduction

I recently encountered an intriguing bug. A user reported that their query was causing vtgate to fetch a large amount of data, sometimes resulting in an Out Of Memory (OOM) error.
For a deeper understanding of grouping and aggregations on Vitess, I recommend reading [this blog post](https://planetscale.com/blog/grouping-and-aggregations-on-vitess) I wrote earlier.

## About Vitess

Vitess is a database clustering system for horizontal scaling of MySQL through a proxy. It handles various tasks such as sharding, replication, and topology management, providing high availability and scalability for large-scale database applications.

## The Query

The problematic query was:

```sql
select sum(user.type)
from user
    join user_extra on user.team_id = user_extra.id
group by user_extra.id
order by user_extra.id;
```

The planner was unable to delegate aggregation to MySQL, leading to the fetching of a significant amount of data for aggregation.

## Planning and Tree Rewriting

During planning, we perform extensive tree rewriting to push as much work down under `Route`s as possible. The rewriting process aims to optimize query execution by pushing operations closer to the data.

### Initial Plan

The first plan after horizon expansion looked like this:

```
Ordering (user_extra.id)
└── Aggregator (ORG sum(`user`.type), user_extra.id group by user_extra.id)
    └── ApplyJoin on [`user`.team_id | :user_team_id = user_extra.id | `user`.team_id = user_extra.id]
        ├── Route (Scatter on user)
        │   └── Table (user.user)
        └── Route (Scatter on user)
            └── Filter (:user_team_id = user_extra.id)
                └── Table (user.user_extra)
```

## Trying to Optimize the Plan

We don't split aggregation between MySQL and vtgate in the initial phases, so we couldn't immediately push down the aggregation through the join. However, we can push down ordering under the aggregation.

### Pushing Ordering Under Aggregation

By pushing ordering under aggregation, the plan changes to:

```
>>>>>>>> push ordering under aggregation
Aggregator (ORG sum(`user`.type), user_extra.id group by user_extra.id)
└── Ordering (user_extra.id)
    └── ApplyJoin on [`user`.team_id | :user_team_id = user_extra.id | `user`.team_id = user_extra.id]
```

We can't push the ordering further down since it's sorted by the RHS of the join. Ordering can only be pushed down to the LHS.
This leaves us in an unfortunate situation - ordering is blocking the aggregator from being pushed down, which means we have to fetch all that data, _and_ sort it to do the aggregation.

### The Solution

The solution I typically use in these situations involves leveraging the phases we have in the planner.

### Phases

We have several phases that run sequentially. After completing a phase, we run the push-down rewriters until we reach a fixed point, then move to the next phase, and so on.

Rewriters perform one of two functions:

1. Running a rewriter over the plan to perform a specific task. For example, the "pull distinct from UNION" rewriter extracts the DISTINCT part from UNION and uses a separate operator for it.
2. Enabling and disabling rewriters. Many rewriters are only enabled after reaching a certain point.

By delaying the "ordering under aggregation" rewriter until the "split aggregation" phase, we can push down the aggregation without causing issues by pushing down ordering under the top aggregator.

The final tree looks like this:

```
Aggregator (sum(`user`.type) group by user_extra.col)
└── Projection (sum(`user`.type) * count(*), user_extra.col)
    └── Ordering (user_extra.col)
        └── ApplyJoin (on [`user`.team_id = user_extra.id])
            ├── Route (Scatter on user)
            │   └── Aggregator (sum(type) group by team_id)
            │       └── Table (user)
            └── Route (Scatter on user_extra)
                └── Aggregator (count(*) group by user_extra.col)
                    └── Filter (:user_team_id = user_extra.id)
                        └── Table (user_extra)
```

Most of the aggregation has been pushed down to MySQL, and at the vtgate level, we are left with only SUMming the SUMs we get from each shard.


## Conclusion

This optimization demonstrates the complexity of query planning and the importance of efficient tree rewriting in Vitess. By carefully pushing operations closer to the data, we can significantly improve query performance and resource utilization.

For more details on the implementation, you can check out the [pull request on GitHub](https://github.com/vitessio/vitess/pull/16278) that addresses this optimization.
