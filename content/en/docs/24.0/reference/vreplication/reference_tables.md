---
title: Reference Tables
description: Using and managing reference tables in Vitess
weight: 100
aliases: [ '/docs/reference/vreplication/v2/referencetables/' ]
---

{{< warning >}}

### Shard Targeting and DMLs

Any DMLs executed on reference tables using shard targeting to a specific shard in the target keyspace, the DMLs to
reference tables will *NOT* be routed to the source keyspace. Writes will happen on the copy of the table in the target
keyspace and the the workflow will most likely break at some future time.

{{< /warning >}}

# Reference Tables in Vitess

Vitess supports the concept of **Reference Tables** as a feature that allows you to keep identical copies of tables
across multiple shards in sync. This is useful for small lookup-type tables that are commonly used by applications. For
example, dimension tables like countries, currencies, states, time zones and shipping methods or even entities like
products, product categories, manufacturers etc. which only change occasionally.

By providing mechanisms to keep consistent copies of these tables in all shards, Vitess ensures that
queries involving reference tables can be served efficiently without the need for cross-keyspace lookups.

The source of truth for reference tables is in an unsharded keyspace. All DMLs on reference tables are
executed in the source keyspace. Vitess provides VReplication workflows to replicate these changes to all shards in
a target sharded keyspace.

This guide provides an example of how to setup reference tables and how to start the VReplication workflow
required to keep them in sync across all shards.

## Specifying reference tables

This is done in the vschema of both the source and target keyspaces. The source keyspace is the source of truth
and where DML operations against the table are performed. The target keyspace then maintains the in-sync copies and
supports local reads on the tables.

### Source VSchema

```json
{
  "tables": {
    "countries": {
      "type": "reference"
    }
  }
}
```

### Target VSchema

Here in addition to the type, you need to specify the source of the reference table, used by vtgate to
route DML queries to the source keyspace.

```json
{
  "tables": {
    "countries": {
      "type": "reference",
      "source": "source.countries"
    }
  }
}
```

## Query Serving features

## Select Queries

Vitess optimizes query serving for reference tables. Since reference tables are present in every shard, Vitess ensures
that SELECT queries involving reference tables can be executed locally within each shard without needing to perform
lookups on the unsharded keyspace which hosts the reference table.

For example, running this query in a sharded keyspace with a reference table `countries` will be served locally by each
shard.

```sql
SELECT c.Name Country, sum(s.Total) SalesByCountry FROM countries c, sales s WHERE s.country_id = c.id GROUP BY c.Name;
```

### DML Queries

If a DML query for a reference table is executed on the target keyspace, vtgate will route the query to the source
keyspace. Example:

```sql
UPDATE countries SET name = 'The Netherlands' WHERE name = 'Netherlands'
```

Once this query is executed against the source table, the VReplication workflows (see below) will propagate the
changes to the corresponding reference tables in all other shards.

## Keeping Reference Tables in Sync

The [VReplication Materialize](https://vitess.io/docs/user-guides/migration/materialize/) workflow is the mechanism that
you can use to keep reference tables in sync with the source across all shards. An example of how to create such a
workflow is:

`Materialize --target-keyspace target --workflow ref1 create --source-keyspace source --reference-tables countries,currencies`

### Monitoring VReplication Lag

The reference table copies on the target are essentially caches of the source table which are synced near-realtime
using `Materialize` workflows. The `Materialize` workflows keep the reference tables in sync by using binlog
replication. If the load on the source and/or target is high, it is possible that there is a lag between the source
getting updated and those updates being propagated to the target.

You can monitor the lag by using `Workflow Show` on the workflows or the VTAdmin UI, and looking at the value
for the `max_replication_lag` in its output.
