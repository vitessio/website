---
author: 'Florent Poinsard'
date: 2021-12-16
slug: '2021-12-16-schema-tracking'
tags: ['Vitess','CNCF', 'Schema', 'Tracking', 'Planner', 'Query', 'Serving', 'MySQL']
title: 'Vitess Schema Tracking'
description: "Insight into Vitess' Schema Tracking feature"
---

## What is Schema Tracking?

In a distributed relational database system like Vitess a central component is responsible for  serving queries across multiple shards, for Vitess, it is [VTGate](https://vitess.io/docs/concepts/vtgate/).
One of the challenges for this component is to be aware of the underlying SQL schema that is being used.
This awareness facilitates query planning.

Table schemas are stored in MySQL’s information_schema, meaning that they are located in a [VTTablet](https://vitess.io/docs/concepts/tablet/)’s MySQL instance and not in VTGate.
When planning queries, VTGate is unable to know the explicit list of columns for a table, also known as the authoritative column list.
This inability leads to several limitations that are listed below.

- This query is a cross-shard query with an order by clause, VTGate needs to create a plan that contains an order by instruction with the column index to order. Without knowledge of the schema, this is not possible.

  ```sql
  SELECT * FROM tbl1, tbl2 WHERE tbl1.id = tbl2.id ORDER BY tbl1.name
  ```


- In this cross-shard query’s projection, the name column is ambiguous, which table are we talking about? If only one of the two tables had a name column, schema tracking would tell VTGate which table name belongs to, and thus the query would not be ambiguous anymore.
  
  ```sql
  SELECT name FROM tbl1, tbl2 WHERE tbl1.id = tbl2.id
  ```


- Since this query is cross-shard, it involves a group by operation at the VTGate level. Let’s assume that tbl2.name is a textual column, we need to know its collation to perform correct string comparisons. Without schema tracking, this is not possible as VTGate does not natively know about tables’ columns collations.

  ```sql
  SELECT tbl2.name FROM tbl1, tbl2 WHERE tbl1.id = tbl2.id GROUP BY tbl2.name
  ```

These queries can be planned only if VTGate has an authoritative column list for the tables, which, prior to Schema Tracking, was possible using the [VSchema](https://vitess.io/docs/concepts/vschema/).
The VSchema lets us declare an authoritative list of columns for our tables.
However, this technique is not perfect, let us see why.

Vitess has some pretty large-scale users, like [Slack](https://slack.engineering/scaling-datastores-at-slack-with-vitess/) and [GitHub](https://github.blog/2021-09-27-partitioning-githubs-relational-databases-scale/) to name a few who use hundreds or thousands of shards with continuous schema changes made by several teams, leading to near-non-stop schema changes.
To ensure constant authoritativeness using the VSchema they would need to update their VSchema after every change to the MySQL schema, which is definitely not sustainable.
The lack of scalability that comes with VSchema motivated the development of the Schema Tracking feature.

We developed the Schema Tracking feature to augment the capabilities of our new [Gen4](https://vitess.io/blog/2021-11-02-why-write-new-planner/) planner by increasing the number of queries supported by it in comparison with the V3 planner, the previous generation of our query planner.
The next section covers how this new functionality works.

## How does Schema Tracking work?

At a regular interval, VTTablet queries its underlying MySQL database to detect if the schema changed.
VTTablet keeps a copy of the schema in a table named schemacopy, this table is updated with the VTTablet’s latest view on the SQL schema.
When comparing the information_schema and the schemacopy table, VTTablet can easily detect any change.
There are three types of changes we want to detect:
- New columns.
- Changed columns.
- Deleted columns.

Each of these changes is detected using a specific SQL query.
For instance, we detect new columns using this query:

```sql
SELECT isc.table_name FROM information_schema.columns AS isc LEFT JOIN _vt.schemacopy AS c ON isc.table_name = c.table_name AND isc.table_schema = c.table_schema AND isc.ordinal_position = c.ordinal_position WHERE isc.table_schema = database() AND c.table_schema IS NULL
```

The result of this query is a list of tables (`isc.table_name`) that have new columns when compared to the one listed in the schemacopy table.
If one of the three queries used to detect a schema change returns a non-empty list of tables, the next healthcheck sent to VTGate will contain the list of updated tables.
Once VTGate receives the healthcheck with the list of updated tables, it queries the VTTablet who sent the healthcheck to fetch the actual metadata for every updated table.
VTGate sends a query against the schemacopy table, which is shown below:

```sql
SELECT table_name, column_name, data_type, collation_name FROM _vt.schemacopy WHERE table_schema = database() AND table_name IN ::tableNames ORDER BY table_name, ordinal_position
```

Note that the `::tableNames` variable is the list of changed tables we received through the healthcheck.
Sometimes, when for instance the healthcheck we receive indicates that the VTTablet is unhealthy, the next fetch of the schemacopy table will ask for the changes on all the tables, instead of just the ones listed in the healthcheck response.
This allows a full reload of the keyspace’s schema.

Once VTGate has updated its local view of the schema, the VSchema gets updated with the new authoritative columns lists.
These lists are then used by our query planner.

As mentioned earlier, large-scale deployments of Vitess can concurrently change their schema at a very high cadence on thousands of shards.
In order to avoid network congestion  in such scenarios, the Schema Tracker has a queueing mechanism at the VTGate level.
This mechanism queues all incoming schema changes from the healthcheck, and at a fixed interval compiles all the different schema change notifications into a single list of updated tables.
This allows us to send a single query to the VTTablet to fetch all metadata changes.

## New capabilities
As mentioned in the first section, a lack of knowledge of the schema was preventing us from supporting more queries.
The impossible queries listed before are now plannable.
With Schema Tracking, all the tables become authoritative without having to manually specify them in the VSchema.

An example of how we use the authoritative column lists is the queries with a `select *`.
We are now able to rewrite the `*` to the actual column list, which eases the work of our planner.

## Future Work
Schema Tracking is still not enabled by default in new Vitess clusters as the feature is experimental.
More information regarding how to enable the Schema Tracking on your Vitess cluster can be found in the [documentation](https://vitess.io/docs/reference/features/schema-tracking/).

Once we have built up enough confidence in this new feature and have enough feedback from our users, we will start thinking about its second version.
The new version could include features like conflict resolutions where two VTTablets send a different update at the same time.
