---
title: Materialize
weight: 3
aliases: ['/docs/user-guides/materialize/'] 
---

{{< info >}}
This guide follows on from the [Get Started](../../../get-started/) guides. Please make sure that you have a
[Kubernetes Operator](../../../get-started/operator) or [local](../../../get-started/local) installation ready.
Make sure you have only run the "101" step of the examples, for example `101_initial_cluster.sh` in the
[local](../../../get-started/local) example. The commands in this guide also assume you have setup the shell
aliases from the example, e.g. `env.sh` in the [local](../../../get-started/local) example.
{{< /info >}}

[`Materialize`](../../../reference/vreplication/materialize/) is a VReplication command/workflow. It can be used as a more
general way to achieve something similar to [MoveTables](../../../concepts/move-tables) or as a way to generate
[materialized views](https://en.wikipedia.org/wiki/Materialized_view) of a table (or set of tables) in the same or
different keyspace from the source table (or set of tables). In general, it can be used to create and maintain
continually updated [materialized views](https://en.wikipedia.org/wiki/Materialized_view) in Vitess, without having
to resort to manual or trigger-based population of the view content.

Since [`Materialize`](../../../reference/vreplication/materialize/) uses VReplication, the view can be kept up-to-date
in very close to real-time which enables use-cases like creating copies of the same table that are sharded in
different ways for the purposes of avoiding expensive cross-shard queries. `Materialize` is also flexible enough to
allow for you to pre-create the schema and [VSchema](../../../concepts/vschema/) for the copied table, allowing you
to for example maintain a copy of a table without some of the source table's MySQL indexes.

All of the command options and parameters are listed in our [reference page for the `Materialize` command](../../../reference/vreplication/materialize). In our examples to follow we will only touch on what is possible using
[`Materialize`](../../../reference/vreplication/materialize).

Let's start by loading some sample data:

```bash
$ mysql < ../common/insert_commerce_data.sql
```

We can look at what we just inserted:

```bash
$ mysql --table < ../common/select_commerce_data.sql

Using commerce
Customer
+-------------+--------------------+
| customer_id | email              |
+-------------+--------------------+
|           1 | alice@domain.com   |
|           2 | bob@domain.com     |
|           3 | charlie@domain.com |
|           4 | dan@domain.com     |
|           5 | eve@domain.com     |
+-------------+--------------------+
Product
+----------+-------------+-------+
| sku      | description | price |
+----------+-------------+-------+
| SKU-1001 | Monitor     |   100 |
| SKU-1002 | Keyboard    |    30 |
+----------+-------------+-------+
COrder
+----------+-------------+----------+-------+
| order_id | customer_id | sku      | price |
+----------+-------------+----------+-------+
|        1 |           1 | SKU-1001 |   100 |
|        2 |           2 | SKU-1002 |    30 |
|        3 |           3 | SKU-1002 |    30 |
|        4 |           4 | SKU-1002 |    30 |
|        5 |           5 | SKU-1002 |    30 |
+----------+-------------+----------+-------+
```

Note that we are using `commerce` keyspace.

## Planning to Use Materialize

In this scenario, we are going to make two copies of the `corder` table **in the same `commerce` keyspace** using
the table names of `corder_view` and `corder_view_redacted`. The first copy will be identical to the source table, but
for the `corder_view_redacted` copy we will use the opportunity to drop or redact the `price` column.

## Create the Destination Tables

In the case where we are using `Materialize` to copy tables *between or across keyspaces* we can use the
`"create_ddl": "copy"` option in the
[`Materialize` `json_spec` `table_settings`](../../../reference/vreplication/materialize/#json-spec-details)
to create the target table for us (similar to what `MoveTables` does). However, in our case where we are using
`Materialize` within a single keyspace (`commerce`) so we need to manually create the target tables. Let's go ahead
and do that:

```sql
$ cat <<EOF | mysql commerce
CREATE TABLE corder_view (
  order_id bigint NOT NULL,
  customer_id bigint DEFAULT NULL,
  sku varbinary(128) DEFAULT NULL,
  price bigint DEFAULT NULL,
  PRIMARY KEY (order_id)
);
CREATE TABLE corder_view_redacted (
  order_id bigint NOT NULL,
  customer_id bigint DEFAULT NULL,
  sku varbinary(128) DEFAULT NULL,
  PRIMARY KEY (order_id)
);
EOF
```

And now we can proceed to the `Materialize` step(s).

## Start the Simple Copy Materialization

We will run two `Materialize` operations, one for each copy/view of the `corder` table we will be creating. We could
combine these two operations into a single `Materialize` operation, but we will keep them separate for clarity.

```bash
$ vtctlclient Materialize -- '{"workflow": "copy_corder_1", "source_keyspace": "commerce", "target_keyspace": "commerce", "table_settings": [{"target_table": "corder_view", "source_expression": "select * from corder"}]}'
```

Now, we should see the materialized view table `corder_view`:

```bash
$ mysql --binary-as-hex=false commerce -e "select * from corder_view"
+----------+-------------+----------+-------+
| order_id | customer_id | sku      | price |
+----------+-------------+----------+-------+
|        1 |           1 | SKU-1001 |   100 |
|        2 |           2 | SKU-1002 |    30 |
|        3 |           3 | SKU-1002 |    30 |
|        4 |           4 | SKU-1002 |    30 |
|        5 |           5 | SKU-1002 |    30 |
+----------+-------------+----------+-------+ 
```

And if we insert a row into the source table, it will be replicated to the materialized view:

```bash
$ mysql commerce -e "insert into corder (order_id, customer_id, sku, price) values (6, 6, 'SKU-1002', 30)"

$ mysql --binary-as-hex=false commerce -e "select * from corder_view"
+----------+-------------+----------+-------+
| order_id | customer_id | sku      | price |
+----------+-------------+----------+-------+
|        1 |           1 | SKU-1001 |   100 |
|        2 |           2 | SKU-1002 |    30 |
|        3 |           3 | SKU-1002 |    30 |
|        4 |           4 | SKU-1002 |    30 |
|        5 |           5 | SKU-1002 |    30 |
|        6 |           6 | SKU-1002 |    30 |
+----------+-------------+----------+-------+
```

Note that the target table is just a normal table, there is nothing that prevents you from writing to it directly.
While you might not want to do that in this in the "materialized view" use-case, in certain other use-cases it might
be completely acceptable to write to the table. Doing so is completedly fine as long as you don't end up altering
or removing rows in a fashion that would break the "replication" part of the VReplication workflow
(e.g. removing a row in the target table directly that is later updated in the source table).

## Viewing the Workflow While in Progress

While we can also see and manipulate the underlying VReplication streams created by `Materialize` there are
[Workflow](../../../reference/vreplication/workflow) commands to `show`, `stop`, `start` and `delete` the
`Materialize` workflow. For example, once we have started the `Materialize` command above, we can observe the
status of the VReplication workflow using the [Workflow](../../../reference/vreplication/workflow) command:

```json
$  vtctlclient Workflow -- commerce listall
Following workflow(s) found in keyspace commerce: copy_corder_1

$ vtctlclient Workflow -- commerce.copy_corder_1 show
{
	"Workflow": "copy_corder_1",
	"SourceLocation": {
		"Keyspace": "commerce",
		"Shards": [
			"0"
		]
	},
	"TargetLocation": {
		"Keyspace": "commerce",
		"Shards": [
			"0"
		]
	},
	"MaxVReplicationLag": 1,
	"MaxVReplicationTransactionLag": 1,
	"Frozen": false,
	"ShardStatuses": {
		"0/zone1-0000000101": {
			"PrimaryReplicationStatuses": [
				{
					"Shard": "0",
					"Tablet": "zone1-0000000101",
					"ID": 1,
					"Bls": {
						"keyspace": "commerce",
						"shard": "0",
						"filter": {
							"rules": [
								{
									"match": "corder_view",
									"filter": "select * from corder"
								}
							]
						}
					},
					"Pos": "4c89eede-8c68-11ed-a40a-6f1a36c22987:1-1070",
					"StopPos": "",
					"State": "Running",
					"DBName": "vt_commerce",
					"TransactionTimestamp": 1672862991,
					"TimeUpdated": 1672862991,
					"TimeHeartbeat": 1672862991,
					"TimeThrottled": 0,
					"ComponentThrottled": "",
					"Message": "",
					"Tags": "",
					"WorkflowType": "Materialize",
					"WorkflowSubType": "None",
					"CopyState": null
				}
			],
			"TabletControls": null,
			"PrimaryIsServing": true
		}
	},
	"SourceTimeZone": "",
	"TargetTimeZone": ""
}
```

We can now also use the `Workflow` `stop`/`start` actions to temporarily stop the materialization workflow. For
example:

```bash
$ vtctlclient Workflow -- commerce.copy_corder_1 stop
+------------------+--------------+
|      Tablet      | RowsAffected |
+------------------+--------------+
| zone1-0000000100 |            1 |
+------------------+--------------+
```

And `start` to start the workflow again and continue with the materialization:

```bash
$ vtctlclient Workflow -- commerce.copy_corder_1 start
+------------------+--------------+
|      Tablet      | RowsAffected |
+------------------+--------------+
| zone1-0000000100 |            1 |
+------------------+--------------+
```

If at some point, when the initial copy is done and we have fully materialized all of the (initial) data, we do not
want to continue replicating changes from the source, we can `delete` the workflow:

```bash
$ vtctlclient Workflow -- commerce.copy_corder_1 delete
+------------------+--------------+
|      Tablet      | RowsAffected |
+------------------+--------------+
| zone1-0000000100 |            1 |
+------------------+--------------+
```

Note that deleting the workflow will *not* `DROP` the target table of the `Materialize` workflow or `DELETE` any of the
data already copied. The data in the target table will remain as it was at the moment the workflow was deleted
(or stopped).

## Start the Redacted Price Materialization

Now we can perform the materialization of the `corder_view_redacted` table we created earlier. Remember that we created
this table without a price column so we will not be copying that column in our query either:

```bash
$ vtctlclient Materialize -- '{"workflow": "copy_corder_2", "source_keyspace": "commerce", "target_keyspace": "commerce", "table_settings": [{"target_table": "corder_view_redacted", "source_expression": "select order_id, customer_id, sku from corder"}]}'
```

Again, looking the target table will show all the source table rows, this time without the `price` column:

```bash
$ mysql commerce --binary-as-hex=false -e "select * from corder_view_redacted"
+----------+-------------+----------+
| order_id | customer_id | sku      |
+----------+-------------+----------+
|        1 |           1 | SKU-1001 |
|        2 |           2 | SKU-1002 |
|        3 |           3 | SKU-1002 |
|        4 |           4 | SKU-1002 |
|        5 |           5 | SKU-1002 |
|        6 |           6 | SKU-1002 |
+----------+-------------+----------+
```

Again, we can add a row to the source table, and see it replicated into the target table:

```bash
$ mysql commerce -e "insert into corder (order_id, customer_id, sku, price) values (7, 7, 'SKU-1002', 30)"

$ mysql commerce --binary-as-hex=false -e "select * from corder_view_redacted"
+----------+-------------+----------+
| order_id | customer_id | sku      |
+----------+-------------+----------+
|        1 |           1 | SKU-1001 |
|        2 |           2 | SKU-1002 |
|        3 |           3 | SKU-1002 |
|        4 |           4 | SKU-1002 |
|        5 |           5 | SKU-1002 |
|        6 |           6 | SKU-1002 |
|        7 |           7 | SKU-1002 |
+----------+-------------+----------+
```

## What Happened Under the Covers

As with [`MoveTables`](../../../reference/vreplication/movetables/), a VReplication stream was formed for each of the `Materialize` workflows we created. We can see these by inspecting the internal `_vt.vreplication` table on the
target keyspace's primary tablet, e.g. in this case:

```bash
# We want to connect directly to the primary mysqld
$ SOCKETPATH=${VTDATAROOT}/$(vtctlclient ListAllTablets -- --keyspace=commerce --tablet_type=primary | awk '$1 sub(/zone1-/, "vt_") {print $1}')

$ mysql -u root -h localhost --socket=${SOCKETPATH}/mysql.sock --binary-as-hex=false -e "select * from _vt.vreplication\G"
*************************** 1. row ***************************
                   id: 2
             workflow: copy_corder_2
               source: keyspace:"commerce" shard:"0" filter:{rules:{match:"corder_view_redacted" filter:"select order_id, customer_id, sku from corder"}}
                  pos: MySQL56/4c89eede-8c68-11ed-a40a-6f1a36c22987:1-4764
             stop_pos: NULL
              max_tps: 9223372036854775807
  max_replication_lag: 9223372036854775807
                 cell:
         tablet_types:
         time_updated: 1672865504
transaction_timestamp: 1672865502
                state: Running
              message:
              db_name: vt_commerce
          rows_copied: 6
                 tags:
       time_heartbeat: 1672865504
        workflow_type: 0
       time_throttled: 0
  component_throttled:
    workflow_sub_type: 0
```

## Cleanup

As seen earlier, you can easily use the [`Workflow delete`](../../../reference/vreplication/workflow) command to
clean up a `Materialize` workflow when it's no longer needed.

{{< info >}}
While this deletes the `Materialize` VReplication stream, the actual source and target tables are left unchanged
and in the same state they were at the moment the VReplication stream was deleted.
{{</ info >}}
