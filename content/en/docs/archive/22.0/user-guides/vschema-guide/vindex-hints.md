---
title: Vindex Hints in Vitess
weight: 20
---

Vindex hints provide a way for users to influence the shard routing of queries in Vitess by specifying which vindexes should be considered or ignored by the query planner. This feature enhances the control over query execution, allowing for potentially more efficient data access patterns in sharded databases.

## Overview

Vindex hints are inspired by MySQL's index hints but are designed specifically for Vitess's shard routing mechanism. They offer a way to guide the Vitess query planner's decisions regarding which shards to target for a given query.

## Syntax

The syntax for using vindex hints in a query is as follows:

```
tbl_name [[AS] alias] [vindex_hint_list]

vindex_hint_list:
vindex_hint [vindex_hint] ...

vindex_hint:
  USE VINDEX ([vindex_list])
| IGNORE VINDEX ([vindex_list])


vindex_list:
vindex_name [, vindex_name] ...
```

## Usage

### Using Vindex Hints

When you want to route a table in query to shards based only on a specific set of vindexes, use the `USE VINDEX` hint.
This can be particularly useful when you know the distribution of your data and want to optimize for query performance.
You can list multiple vindexes separated by commas, and the planner will consider all of them and use the one producing the best query plan.

Example:

```sql
SELECT * FROM user USE VINDEX (hash_user_id, secondary_vindex) WHERE user_id = 123;
```

It's important to note that the Vitess query planner may decide to merge the table specified in the query with a different table if it determines that such a merge would result in a more efficient query execution plan.
In such cases, the vindex actually used for routing the query may come from the other table, which means the vindex hint provided in the original query might not be followed.

Additionally, if the query does not contain a usable predicate for the specified vindex, the planner will not use the hinted vindex for routing.
This ensures that vindex hints complement the query planner's optimization process rather than enforce routing decisions that could potentially degrade performance.

### Ignoring Vindex Hints

If you wish to prevent the query planner from using a specific vindex for routing, you can use the `IGNORE VINDEX` hint.
This might be useful when the default vindex choice is suboptimal for certain query patterns.

Example:

```sql
SELECT * FROM order IGNORE VINDEX (range_order_id) WHERE order_date = '2021-01-01';
```

## Considerations

- Vindex hints are advisory. The query planner will make the final decision on routing, based on the available vindexes and the query's constraints.
- Specifying both `USE VINDEX` and `IGNORE VINDEX` for the same table in a single query is not valid and will result in an error.
- Vindex hints do not apply to internal indexes within the MySQL instances of each shard. They only influence the choice of shard routing.

## Best Practices

- Use vindex hints judiciously, as incorrect usage can lead to suboptimal query performance.
- Monitor query performance and experiment with different vindexes to find the best routing strategies for your use cases.

## Conclusion

Vindex hints offer a powerful tool for optimizing shard routing in Vitess, providing users with greater control over their query execution strategies. By carefully applying these hints, users can improve query efficiency and performance in their Vitess deployments.
