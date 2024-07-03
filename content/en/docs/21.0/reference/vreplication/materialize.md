---
title: Materialize
description: Materialize the results of a query into a table
weight: 40
---

### Description

[`Materialize`](../../programs/vtctldclient/vtctldclient_materialize/) is a lower level vreplication command that allows for generalized materialization of tables. The target tables
can be copies, aggregations, or views. The target tables are kept in sync in near-realtime.

You can specify multiple tables to materialize using the [`create`](../../programs/vtctldclient/vtctldclient_materialize/vtctldclient_materialize_create/) sub-command's `--table-settings` flag.
There are limitations, however, to the queries which can be used with `Materialize`:
  - The query must be a `SELECT` statement
  - Only the following operators are supported: `=`, `<`, `<=`, `>`, `>=`, `<>`, `!=` (e.g. no `IN`, `OR`, or `LIKE`)
  - The query must be against a single table (so no `JOIN`s)
  - The query cannot use `DISTINCT`
  - The query cannot use a derived table
  - Expressions in the query must have an alias, e.g. `select hour(c1) as c1_hour from t1`
  - The `GROUP BY` expression cannot reference an aggregate expression such as `MAX` or `COUNT`

{{< warning >}}
Be careful to avoid using the `INSTANT ADD COLUMN` feature in [MySQL 8.0+](https://mysqlserverteam.com/mysql-8-0-innodb-now-supports-instant-add-column/) with materialization source tables as this can cause the vreplication based materialization workflow to break.
{{< /warning >}}

## The Basic Materialize Workflow Lifecycle

1. Initiate the migration using `Materialize`
2. Monitor the workflow using `show` or `status`<br/>
`Materialize --target-keyspace <target-keyspace> show --workflow <workflow>`<br/>
`Materialize --target-keyspace <target-keyspace> status --workflow <workflow>`<br/>
3. Start accessing your views once the workflow has started Replicating

## Command

Please see the [`Materialize` command reference](../../programs/vtctldclient/vtctldclient_materialize/) for a full list of sub-commands and their flags.

### Example

```shell
vtctldclient --server localhost:15999 Materialize --workflow product_sales --target-keyspace commerce create --source-keyspace commerce --table-settings '[{"target_table": "sales_by_sku", "create_ddl": "create table sales_by_sku (sku varbinary(128) not null primary key, orders bigint, revenue bigint)", "source_expression": "select sku, count(*) as orders, sum(price) as revenue from corder group by sku"}]' --cells zone1 --cells zone2 --tablet-types replica
```

### Parameters

### Action

[`Materialize`](../../programs/vtctldclient/vtctldclient_materialize/) is an "umbrella" command. The [`action` or sub-command](../../programs/vtctldclient/vtctldclient_materialize/#see-also) defines the operation on the workflow.

### Options

Each [`action` or sub-command](../../programs/vtctldclient/vtctldclient_materialize/#see-also) has additional options/parameters that can be used to modify its behavior. Please see the [command's reference docs](../../programs/vtctldclient/vtctldclient_materialize/) for the full list of command options or flags. Below we will add additional information for a subset of key options.

#### --cells
**optional**\
**default** local cell

<div class="cmd">

A comma-separated list of cell names or cell aliases. This list is used by VReplication to determine which
cells should be used to pick a tablet for selecting data from the source keyspace.<br><br>

</div>

###### Uses

* Improve performance by using picking a tablet in cells in network proximity with the target
* To reduce bandwidth costs by skipping cells that are in different availability zones
* Select cells where replica lags are lower

#### --tablet-types 
**optional**\
**default** "in_order:REPLICA,PRIMARY"\
**string**

<div class="cmd">

Source tablet types to replicate from (e.g. PRIMARY, REPLICA, RDONLY). The value
specified impacts [tablet selection](../tablet_selection/) for the workflow.

</div>

###### Uses

* To reduce the load on PRIMARY tablets by using REPLICAs or RDONLYs
* Reducing lag by pointing to PRIMARY

#### --table-settings
**required**\
**JSON**

<div class="cmd">

This is a JSON array where each value must contain two key/value pairs. The first required key is 'target_table' and it is the name of the table in the target-keyspace to store the results in. The second required key is 'source_expression' and its value is the select query to run against the source table. An optional key/value pair can also be specified for 'create_ddl' which provides the DDL to create the target table if it does not exist – you can alternatively specify a value of 'copy' if the target table schema should be copied as-is from the source keyspace. Here's an example value for table-settings:

```json
[
  {
    "target_table": "customer_one_email",
    "source_expression": "select email from customer where customer_id = 1"
  },
  {
    "target_table": "states",
    "source_expression": "select * from states",
    "create_ddl": "copy"
  },
  {
    "target_table": "sales_by_sku",
    "source_expression": "select sku, count(*) as orders, sum(price) as revenue from corder group by sku",
    "create_ddl": "create table sales_by_sku (sku varbinary(128) not null primary key, orders bigint, revenue bigint)"
  }
]
```

</div>

### Notes

There are special commands to perform common materialization tasks and you should prefer them
to using `Materialize` directly.

* If you just want to copy tables to a different keyspace use [MoveTables](../movetables)
* If you want to change sharding strategies use [Reshard](../reshard) instead
