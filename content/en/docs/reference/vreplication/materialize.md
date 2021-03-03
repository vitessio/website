---
title: Materialize
description:
weight: 70
---

### Command

```
Materialize [-cells=<cells>] [-tablet_types=<source_tablet_types>] <json_spec>
```

### Description

Materialize is a low level vreplication API that allows for generalized materialization of tables. The target tables
can be copies, aggregations or views. The target tables are kept in sync in near-realtime.

You can specify multiple tables to materialize using the json_spec parameter.

### Parameters


#### -cells
**optional**\
**default** local cell

<div class="cmd">

A comma-separated list of cell names or cell aliases. This list is used by VReplication to determine which
cells should be used to pick a tablet for selecting data from the source keyspace.<br><br>

###### Uses

* Improve performance by using picking a tablet in cells in network proximity with the target
* To reduce bandwidth costs by skipping cells that are in different availability zones
* Select cells where replica lags are lower
</div>

#### -tablet_types
**optional**\
**default** replica

<div class="cmd">

A comma-separated list of tablet types that are used while picking a tablet for sourcing data.
One or more from MASTER, REPLICA, RDONLY.<br><br>

###### Uses

* To reduce the load on master tablets by using REPLICAs or RDONLYs
* Reducing lags by pointing to MASTER
</div>

#### JSON spec details
<div class="cmd">

* *workflow* name to refer to this materialization
* *source_keyspace* keyspace containing the source table
* *target_keyspace* keyspace to materialize to
* *table_settings* list of views to be materialized and the associated query
  * *target_table* name of table to which to materialize the data to
  * *source_expression* the materialization query
* Optional parameters:
  * *stop_after_copy* if vreplication should be stopped after the copy phase
    is complete
  * *cell* name of a cell, or a comma separated list of cells, that should be
    used for choosing source tablet(s) for the materialization. If this
    parameter is not specified, only cell(s) local to the target tablet(s) is
    considered
  * *tablet_types* a Vitess tablet_type, or comma separated list of tablet
    types, that should be used for choosing source tablet(s) for the
    materialization. If not specified, this defaults to the tablet type(s)
    specified by the `-vreplication_tablet_type` VTTablet command line flag

</div>

#### Example
```
Materialize '{"workflow": "product_sales", "source_keyspace": "commerce", "target_keyspace": "customer",
    "table_settings": [{"target_table": "sales_by_sku",
    "source_expression": "select sku, count(*), sum(price) from corder group by order_id"}],
    "cell": "zone1", "tablet_types": "REPLICA"}'
```


### A Materialize Workflow

Once you decide on your materialization requirements, you need to initiate a VReplication workflow as follows:

1. Initiate the migration using Materialize
2. Monitor the workflow using [Workflow](../workflow) or [VExec](../vexec)
3. Start accessing your views once the workflow has started Replicating

### Notes

There are special commands to perform common materialization tasks and you should prefer them
to using Materialize directly.

* If you just want to copy tables to a different keyspace use [MoveTables](../movetables).
* If you want to change sharding strategies use [Reshard](../reshard) instead
