---
title: Advanced VSchema Properties
weight: 20
---

With the exception of Multi-Column Vindexes, advanced VSchema Properties do not have DDL constructs. They can only be updated through `vtctld` CLI commands.

## Multi-Column Vindexes

Multi-Column Vindexes are useful in the following two use cases:

* Grouping customers by their regions so they can be hosted in specific geographical locations. This may be required for compliance and also to achieve better performance.
* For a multi-tenant system, grouping all rows of a tenant in a separate set of shards. This limits the fan out of queries if searching only for rows that are related to a single tenant.

In both cases the leading column is the region or tenant, and is used to form the first few bits of the `keyspace_id`. The second column is used for the bits that follow. Since Vitess shards by keyrange, this approach will naturally group all rows of a region or tenant within the same shard, or within a group of consecutive shards. Since each shard is its own MySQL cluster, these can then be deployed to different regions as needed.

Please refer to [Region-based Sharding](../../configuration-advanced/region-sharding) for an example on how to use the `region_json` vindex and [Subsharding Vindex](../subsharding-vindex) for the more generic multicol vindex.

#### Alternate approach

You have the option to pre-combine the region and id bits into a single column and use that as an input for a single column vindex. This approach achieves the same goals as a multi-column vindex.

The downside of this approach is that it is harder to migrate an id to a different region and you won't get the query serving support for routing queries to subset of shards if only the first few columns of a multicol vindex are provided.

## Reference Tables

Sharded databases often need the ability to join their tables with smaller “reference” tables. For example, the `product` table could be seen as a reference table. Other use cases are tables that map static information like zip code to city, etc.

Joining against these tables across keyspaces results in cross-shard joins that may not be very efficient or fast.

Vitess allows you to create a table in a sharded keyspace as a reference table. This means that it will treat the table as having an identical set of rows across all shards. A query that joins a sharded table against such reference tables is then performed locally within each shard.

A reference table should not have any vindex, and is defined in the VSchema as a reference type:

```json
{
  "sharded": true,
  "tables": {
    "zip_detail": {
      "type": "reference"
    }
  }
}
```
<br/>

#### Source Tables

Vitess will optimize reference table routing when joined to a table within the same keyspace. Additional routing optimizations can be enabled by specifying the `source` of a reference table. When a reference table specifies a `source` table:

 * A `SELECT ... JOIN` (or equivalent `SELECT ... WHERE`) will try to route the
   query to the keyspace of the table to which the reference (or source) table
   is being joined.
 * An `INSERT`, `UPDATE`, or `DELETE` uses the keyspace of the source table.

For example:

```json
{
  "sharded": true,
  "tables": {
    "zip_detail": {
      "type": "reference",
      "source": "unsharded_is.zip_detail"
    }
  }
}
```
<br/>

There are some constraints on `source`:

 * It must refer to an existing table in an existing keyspace.
 * It must refer to a table in a different keyspace.
 * It must refer to a table in an unsharded keyspace.
 * Any given value for `source` may appear at most once per-keyspace.

#### Materialization

It may become a challenge to keep a reference table correctly updated across all shards. Vitess supports the [Materialize](../../migration/materialize) feature that allows you to maintain the original table in an unsharded keyspace and automatically propagate changes to that table in real-time across all shards.

## Column List

The VSchema allows you to specify the list of columns along with their types for every table. This allows Vitess to make optimization decisions where necessary.

For example, specifying that a column contains numeric data allows VTGate to not request further collation specific information (`weight_string`) if additional sorting is needed after collecting results from all shards.

For example, issuing this query against `customer` would add the `weight_string` column while sending the query to the vttablets:

```json
Query - select integer_col from customer order by integer_col;
Plan -
{
  "QueryType": "SELECT",
  "Original": "select integer_col from customer order by integer_col",
  "Instructions": {
    "OperatorType": "Route",
    "Variant": "SelectScatter",
    "Keyspace": {
      "Name": "customer",
      "Sharded": true
    },
    "FieldQuery": "select integer_col, weight_string(integer_col) from `customer` where 1 != 1",
    "OrderBy": "0 ASC",
    "Query": "select integer_col, weight_string(integer_col) from `customer` order by integer_col asc",
    "Table": "`customer`"
  }
}
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
        "name": "integer_col",
        "type": "INT16"
      }]
    }
```

Re-issuing the same query will now not use `weight_string`:

```json
Query - select integer_col from customer order by integer_col;
Plan -
{
  "QueryType": "SELECT",
  "Original": "select integer_col from customer order by integer_col",
  "Instructions": {
    "OperatorType": "Route",
    "Variant": "SelectScatter",
    "Keyspace": {
      "Name": "customer",
      "Sharded": true
    },
    "FieldQuery": "select integer_col from `customer` where 1 != 1",
    "OrderBy": "0 ASC",
    "Query": "select integer_col from `customer` order by integer_col asc",
    "Table": "`customer`"
  }
}
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

#### Automatic Schema Tracking

Vtgates now also have the capability to track the schema changes and populate the columns list on its own by contacting the vttablets. To know more about this feature, read [here](../../../reference/features/schema-tracking).
This feature tracks the underlying schema and sets the authoritative column list.

## Routing Rules

Routing Rules are an advanced method of redirecting queries meant for one table to another. They are just pointers and are analogous to symbolic links in a file system. You should generally not have to use routing rules in Vitess.

Workflows like `MoveTables` make use of routing rules to create the existence of the target tables and manage traffic switch from source to target by manipulating these routing rules.

For more information, please refer to the [Routing Rules](../../../reference/features/schema-routing-rules) section.

