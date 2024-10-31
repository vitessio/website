---
author: 'Andrés Taylor'
date: 2024-11-05
slug: '2024-11-05-optimizing-query-planning-in-vitess-a-step-by-step-approach'
tags: ['Vitess', 'PlanetScale', 'MySQL', 'Query Serving', 'Vindex', 'plan', 'execution plan', 'explain', 'optimizer', "aggregate", "group by", "order by"]
title: 'Choosing sharding keys in Vitess: Tools and best practices'
description: "See how Vitess acts as a database proxy that creates an illusion of a single database when technically, the query is sent to multiple MySQL instances."
---

Vitess can split the content in tables across multiple MySQL instances.
This is called sharding the data.
Sharding is the process of splitting a large database into smaller, more manageable parts called shards.
Each shard is stored on a separate MySQL instance.
Vitess acts as a database proxy that creates an illusion of a single database when technically, the query is sent to multiple MySQL instances.

When sharding a table, you need to choose a sharding key.
The sharding key is a column or set of columns that determine how the data is split across the shards.
The sharding key is used to route queries to the correct shard.
It's similar to a primary key, but it's used for sharding instead of indexing.
Choosing the right sharding keys is crucial for the performance of your application.

When inspecting a query, if Vitess can see that a join is being performed on columns that are sharded with the same rules, it knows that the join between these tables can be pushed down to the shard and solved there.
This is the best case scenario, as it minimizes the amount of data that needs to be transferred between shards.

Say we have two tables, `orders` and `customer`, and both are sharded by their primary keys (order_id and customer_id respectively).

```sql
select *
from orders o
       join customers c on o.customer_id = c.id
```

Since the join is not being done on the sharding key, Vitess will need to perform the join in the vtgate layer, which is the query router that sits between the application and the MySQL instances.
This is not ideal, as it means that all the data from both tables will need to be transferred to the vtgate layer, and the join will be performed there.

If we were to shard the `orders` table by `customer_id` instead of `order_id`, the join could be pushed down to the shard, and the join would be performed there.
This would be much more efficient, as only the data that is needed for the join would need to be transferred between shards.

## Analyzing How Queries Execute

When you're choosing sharding keys, it's important to understand how your queries will execute.
Vitess provides a tool called `vexplain` that can help you analyze how your queries will be executed.
It's similar to mysql's `explain` command, showing the query plan that Vitess will use to execute the query.

```sql
vexplain plan select *
  from orders o 
    join customers c on o.customer_id = c.id
```

This will output the query plan that Vitess will use to execute the query. It's represented as a JSON tree:

```json
{
  "OperatorType": "Join",
  "Variant": "Join",
  "JoinColumnIndexes": "L:0,L:1,L:2,L:3,L:4,R:0,R:1,R:2,R:3",
  "JoinVars": {
    "o_customer_id": 1
  },
  "TableName": "orders_customers",
  "Inputs": [
    {
      "OperatorType": "Route",
      "Variant": "Scatter",
      "Keyspace": {
        "Name": "ks_derived",
        "Sharded": true
      },
      "FieldQuery": "select o.id, o.customer_id, o.`status`, o.total_amount, o.created_at from orders as o where 1 != 1",
      "Query": "select o.id, o.customer_id, o.`status`, o.total_amount, o.created_at from orders as o",
      "Table": "orders"
    },
    {
      "OperatorType": "Route",
      "Variant": "EqualUnique",
      "Keyspace": {
        "Name": "ks_derived",
        "Sharded": true
      },
      "FieldQuery": "select c.id, c.email, c.`name`, c.created_at from customers as c where 1 != 1",
      "Query": "select c.id, c.email, c.`name`, c.created_at from customers as c where c.id = :o_customer_id /* INT32 */",
      "Table": "customers",
      "Values": [
        ":o_customer_id"
      ],
      "Vindex": "user_index"
    }
  ]
}
```

This is showing the execution plan that Vitess will use for the query. We can see the join being the root of the query plan.
The join is a nested loop join, so for every row returned from the first input to the join, Vitess will issue a query to the second input to the join.
This is a so called "EqualUnique" Route, which means that Vitess knows that the second query only needs to be sent to a single shard.

This is what Vitess will do because the sharding keys we've selected for these tables are the same as the primary keys. 
For the second query, since we are querying by its sharding key, it's easy to figure out where to send the query.

If we instead were to shard the `orders` table by `customer_id`, the query plan would look different.

```json
{
  "OperatorType": "Route",
  "Variant": "Scatter",
  "Keyspace": {
    "Name": "ks_derived",
    "Sharded": true
  },
  "FieldQuery": "select o.id, o.customer_id, o.`status`, o.total_amount, o.created_at, c.id, c.email, c.`name`, c.created_at from orders as o, customers as c where 1 != 1",
  "Query": "select o.id, o.customer_id, o.`status`, o.total_amount, o.created_at, c.id, c.email, c.`name`, c.created_at from orders as o, customers as c where o.customer_id = c.id",
  "Table": "customers, orders"
}
```

Here we can see that the join has been pushed down to the shard, and the join is being performed there. 
Vtgate only has to concatenate the results from the shards.

## Analyze Queries With VExplain Keys

Vitess also provides a tool called `vexplain keys` that can help you analyze your queries so you can design your schema.

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

This output shows the columns that are being used in the query. The join columns are the columns that are being used to join the two tables. The equality sign after the column name indicates which comparison is being performed against the column.
The tool will also show columns used for filtering or grouping, which can be useful when choosing sharding keys. For a more complex query, the output can look like this:

```json
{
  "statementType": "SELECT",
  "groupingColumns": [
    "customers.`name`",
    "customers.id"
  ],
  "joinColumns": [
    "customers.id =",
    "order_items.order_id =",
    "orders.customer_id =",
    "orders.id ="
  ],
  "filterColumns": [
    "orders.`status` ="
  ],
  "selectColumns": [
    "customers.`name`",
    "customers.id",
    "order_items.quantity",
    "order_items.unit_price"
  ]
}
```

This tool is very useful when you're designing your schema and trying to figure out which columns to use as sharding keys.

## Analyzing Query Patterns at Scale

So far we've looked at individual queries, but real applications have hundreds or thousands of queries. 
Let's look at a more realistic example. We've collected a [sample query log](link-to-query-log.sql) from our e-commerce application running in production.

Using the `vt` command line tool, we can analyze all these queries at once:

```bash
vt keys query-log.sql > keys-log.json
vt benchstat keys-log.json
```

