---
title: Advanced VSchema Properties
weight: 11
---

With the exception of Multi-Column Vindexes, advanced VSchema Properties do not have DDL constructs. They can only be updated through `vtctld` CLI commands.

## Multi-Column Vindexes

Multi-Column Vindexes are useful in the following two use cases:

* Grouping customers by their regions so they can be hosted in specific geographical locations. This may be required for compliance, and also to achieve better performance.
* For a multi-tenant system, grouping all rows of a tenant in a separate set of shards. This limits the fan out of queries if searching only for rows that are related to a single tenant.

In both cases the leading column is the region or tenant, and is used to form the first few bits of the `keyspace_id`. The second column is used for the bits that follow. Since Vitess shards by keyrange, this approach will naturally group all rows of a region or tenant within the same shard, or within a group of consecutive shards. Since each shard is its own MySQL cluster, these can then be deployed to different regions as needed.

Please refer to [Region-based Sharding](../../configuration-advanced/region-sharding) for an example on how to use the `region_json` vindex.

Currently, the Vindex gets used for assigning a `keyspace_id` at the time of insert and at the time of resharding. Additional vindexes need to be added to the table for routing query constructs that contain WHERE clauses.

Vitess does not have the capability to route a query based on multiple values of a multi-column vindex in a where clause yet. This feature will be added soon.

#### Alternate approach

You have the option to pre-combine the region and id bits into a single column and use that as an input for a single column vindex. This approach achieves the same goals as a multi-column vindex. Moreover, you avoid having to define additional vindexes for query routing.

The downside of this approach is that it is harder to migrate an id to a different region.

## Reference Tables

Sharded databases often need the ability to join their tables with smaller “reference” tables. For example, the `product` table could be seen as a reference table. Other use cases are tables that map static information like zipcode to city, etc.

Joining against these tables across keyspaces results in cross-shard joins that may not be very efficient or fast.

Vitess allows you to create a table in a sharded keyspace as a reference table. This means that it will treat the table as having an identical set of rows across all shards. A query that joins a sharded table against such reference tables is then performed locally within each shard.

A reference table should not have any vindex, and is defined in the VSchema as a reference type:

```json
{
  "sharded": true,
  "tables": {
    "zip_detail": { "type": "reference" }
  }
}
```

It may become a challenge to keep a reference table correctly updated across all shards. Vitess supports the [Materialize](../../migration/materialize) feature that allows you to maintain the original table in an unsharded keyspace and automatically propagate changes to that table in real-time across all shards.

## Column List

The VSchema allows you to specify the list of columns along with their types for every table. This allows Vitess to make optimization decisions where necessary.

For example, specifying that a column contains text allows VTGate to request further collation specific information (`weight_string`) if additional sorting is needed after collecting results from all shards.

For example, issuing this query against `customer` would fail:

```text
mysql> select customer_id, uname from customer order by uname;
ERROR 1105 (HY000): vtgate: http://sougou-lap1:12345/: types are not comparable: VARCHAR vs VARCHAR
```

However, we can modify the VSchema as follows:

```json
    "customer": {
      "column_vindexes": [{
        "column": "customer_id",
        "name": "hash"
      }],
      "auto_increment": {
        "column": "customer_id",
        "sequence": "product.customer_seq"
      },
      "columns": [{
        "name": "uname",
        "type": "VARCHAR"
      }]
    }
```

Re-issuing the same query will now succeed:

```text
mysql> select customer_id, uname from customer order by uname;
+-------------+---------+
| customer_id | uname   |
+-------------+---------+
|           1 | alice   |
|           2 | bob     |
|           3 | charlie |
|           4 | dan     |
|           5 | eve     |
+-------------+---------+
5 rows in set (0.00 sec)
```

Specifying columns against tables also allows VTGate to resolve ambiguous naming of columns against the right tables.

#### Authoritative List

If you have listed all columns of a table in the VSchema, you can add the `column_list_authoritative` flag to the table:

```json
    "customer": {
      "column_vindexes": [{
        "column": "customer_id",
        "name": "hash"
      }],
      "auto_increment": {
        "column": "customer_id",
        "sequence": "product.customer_seq"
      },
      "columns": [{
        "name": "uname",
        "type": "VARCHAR"
      }],
      "column_list_authoritative": true
    }
```

This flag causes VTGate to automatically expand expressions like `select *` or insert statements that don’t specify the column list.

The caveat about using this feature is that you have to keep this column list in sync with the underlying schema.

In the future, Vitess will allow you to pull this information from the vttablets and automatically keep it up-to-date.

## Routing Rules

Routing Rules are an advanced method of redirecting queries meant for one table to another. They are just pointers and are analogous to symbolic links in a file system. You should generally not have to use routing rules in Vitess.

Workflows like `MoveTables` make use of routing rules to create the existence of the target tables and manage traffic switch from source to target by manipulating these routing rules.

For more information, please refer to the [Routing Rules](../../../reference/features/schema-routing-rules) section.

