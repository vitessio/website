---
title: Move Tables
weight: 2
aliases: ['/docs/user-guides/move-tables/']
---

{{< info >}}
This guide follows on from the [Get Started](../../../get-started/) guides. Please make sure that you have an
[Kubernetes Operator](../../../get-started/operator) or [local](../../../get-started/local) installation ready.
Make sure you have only run the "101" step of the examples, for example `101_initial_cluster.sh` in the
[local](../../../get-started/local) example. The commands in this guide also assume you have setup the shell
aliases from the example, e.g. `env.sh` in the [local](../../../get-started/local) example.
{{< /info >}}

[MoveTables](../../../concepts/move-tables) is a [VReplication](../../../reference/vreplication/) workflow that enables you to move all or a subset of
tables between [keyspaces](../../../concepts/keyspace) without downtime. For example, after
[initially deploying Vitess](../../../get-started/local), your single `commerce` schema may grow so large that it needs
to be split into multiple [keyspaces](../../../concepts/keyspace) (often times referred to as vertical or functional sharding).

All of the command options and parameters are listed in our [reference page for `MoveTables`](../../../reference/vreplication/movetables).

As a stepping stone towards splitting a single table across multiple servers (sharding), it usually makes sense to first split from having a single monolithic keyspace (`commerce`) to having multiple keyspaces (`commerce` and `customer`). For example, in our hypothetical ecommerce system we may know that the `customer` and `corder` tables are closely related and both growing quickly.

Let's start by simulating this situation by loading sample data:

```bash
# On local and operator installs:
$ mysql < ../common/insert_commerce_data.sql
```

We can look at what we just inserted:

```bash
# On local and operator installs:
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

Notice that all of the tables are currently in the `commerce` schema/keyspace here.

## Planning to Move Tables

In this scenario, we are going to add the `customer` [keyspace](../../../concepts/keyspace) in addition to the `commerce` keyspace we already have.  This new keyspace will be backed by its own set of mysqld instances. We will then move the `customer` and `corder` tables from the `commerce` keyspace to the newly created `customer` keyspace while the `product` table will remain in the `commerce` keyspace. This operation happens online, which means that it does not block either read or write operations to the tables, *except* for a very small window during the final cut-over.

## Show our current tablets

```bash
$ mysql -e "show vitess_tablets"
+-------+----------+-------+------------+---------+------------------+-----------+----------------------+
| Cell  | Keyspace | Shard | TabletType | State   | Alias            | Hostname  | PrimaryTermStartTime |
+-------+----------+-------+------------+---------+------------------+-----------+----------------------+
| zone1 | commerce | 0     | PRIMARY    | SERVING | zone1-0000000100 | localhost | 2023-01-04T17:59:37Z |
| zone1 | commerce | 0     | REPLICA    | SERVING | zone1-0000000101 | localhost |                      |
| zone1 | commerce | 0     | RDONLY     | SERVING | zone1-0000000102 | localhost |                      |
+-------+----------+-------+------------+---------+------------------+-----------+----------------------+
```

As can be seen, we have 3 tablets running, with tablet ids 100, 101 and 102; which we use in the examples to form the tablet alias/names like `zone1-0000000100`, etc.

## Create New Tablets

The first step in our MoveTables operation is to deploy new tablets for our `customer` keyspace. By the convention used in our examples, we are going to use the tablet ids 200-202 as the `commerce` keyspace previously used `100-102`. Once the tablets have started, we will wait for the operator (k8s install) or `vtorc` (local install) to promote one of the new tablets to `PRIMARY` before proceeding:

### Using Operator

```bash
$ kubectl apply -f 201_customer_tablets.yaml
```

After a few minutes the pods should appear running:

```bash
$ kubectl get pods
example-commerce-x-x-zone1-vtorc-c13ef6ff-5d658d78d8-dvmnn   1/1     Running   1 (4m39s ago)   65d
example-etcd-faf13de3-1                                      1/1     Running   1 (4m39s ago)   65d
example-etcd-faf13de3-2                                      1/1     Running   1 (4m39s ago)   65d
example-etcd-faf13de3-3                                      1/1     Running   1 (4m39s ago)   65d
example-vttablet-zone1-1250593518-17c58396                   3/3     Running   1 (27s ago)     32s
example-vttablet-zone1-2469782763-bfadd780                   3/3     Running   3 (4m39s ago)   65d
example-vttablet-zone1-2548885007-46a852d0                   3/3     Running   3 (4m39s ago)   65d
example-vttablet-zone1-3778123133-6f4ed5fc                   3/3     Running   1 (26s ago)     32s
example-zone1-vtadmin-c03d7eae-7dcd4d75c7-szbwv              2/2     Running   2 (4m39s ago)   65d
example-zone1-vtctld-1d4dcad0-6b9cd54f8f-jmdt9               1/1     Running   2 (4m39s ago)   65d
example-zone1-vtgate-bc6cde92-856d44984b-lqfvg               1/1     Running   2 (4m6s ago)    65d
vitess-operator-8df7cc66b-6vtk6                              1/1     Running   0               55s
```

Again, the operator will promote one of the tablets to `PRIMARY` implicitly for you.

Make sure that you restart the port-forward after launching the pods has completed:

```bash
$ killall kubectl
./pf.sh &
```

### Using a Local Deployment

```bash
$ ./201_customer_tablets.sh
```

## Show All Tablets

```bash
$ mysql -e "show vitess_tablets"
+-------+----------+-------+------------+---------+------------------+-----------+----------------------+
| Cell  | Keyspace | Shard | TabletType | State   | Alias            | Hostname  | PrimaryTermStartTime |
+-------+----------+-------+------------+---------+------------------+-----------+----------------------+
| zone1 | commerce | 0     | PRIMARY    | SERVING | zone1-0000000100 | localhost | 2023-01-04T17:59:37Z |
| zone1 | commerce | 0     | REPLICA    | SERVING | zone1-0000000101 | localhost |                      |
| zone1 | commerce | 0     | RDONLY     | SERVING | zone1-0000000102 | localhost |                      |
| zone1 | customer | 0     | PRIMARY    | SERVING | zone1-0000000201 | localhost | 2023-01-04T18:00:22Z |
| zone1 | customer | 0     | REPLICA    | SERVING | zone1-0000000200 | localhost |                      |
| zone1 | customer | 0     | RDONLY     | SERVING | zone1-0000000202 | localhost |                      |
+-------+----------+-------+------------+---------+------------------+-----------+----------------------+
```

{{< info >}}
The following change does not change actual query routing yet. We will later use the _SwitchTraffic_ action to perform that.
{{</ info >}}

## Start the Move

In this step we will create the `MoveTables` workflow, which copies the tables from the `commerce` keyspace into
`customer`. This operation does not block any database activity; the `MoveTables` operation is performed online:

```bash
$ vtctlclient MoveTables -- --source commerce --tables 'customer,corder' Create customer.commerce2customer
```

A few things to note:
 * In a real-world situation this process can take hours or even days to complete depending on the size of the table.
 * The workflow name (`commerce2customer` in this case) is arbitrary, you can name it whatever you like. You will use this name for the other `MoveTables` actions like in the upcoming `SwitchTraffic` step.

## Check Routing Rules (Optional)

To see what happens under the covers, let's look at the [**routing rules**](../../../reference/features/schema-routing-rules/) that the `MoveTables` operation created.  These are instructions used by a [`VTGate`](../../../concepts/vtgate) to determine which backend keyspace to send requests to for a given table — even when using a fully qualified table name such as `commerce.customer`:

```json
$ vtctldclient GetRoutingRules
{
  "rules": [
    {
      "fromTable": "customer.customer@rdonly",
      "toTables": [
        "commerce.customer"
      ]
    },
    {
      "fromTable": "commerce.corder@rdonly",
      "toTables": [
        "commerce.corder"
      ]
    },
    {
      "fromTable": "customer",
      "toTables": [
        "commerce.customer"
      ]
    },
    {
      "fromTable": "customer.customer@replica",
      "toTables": [
        "commerce.customer"
      ]
    },
    {
      "fromTable": "corder@replica",
      "toTables": [
        "commerce.corder"
      ]
    },
    {
      "fromTable": "customer.corder",
      "toTables": [
        "commerce.corder"
      ]
    },
    {
      "fromTable": "commerce.corder@replica",
      "toTables": [
        "commerce.corder"
      ]
    },
    {
      "fromTable": "customer@rdonly",
      "toTables": [
        "commerce.customer"
      ]
    },
    {
      "fromTable": "commerce.customer@replica",
      "toTables": [
        "commerce.customer"
      ]
    },
    {
      "fromTable": "corder",
      "toTables": [
        "commerce.corder"
      ]
    },
    {
      "fromTable": "corder@rdonly",
      "toTables": [
        "commerce.corder"
      ]
    },
    {
      "fromTable": "customer.corder@rdonly",
      "toTables": [
        "commerce.corder"
      ]
    },
    {
      "fromTable": "customer@replica",
      "toTables": [
        "commerce.customer"
      ]
    },
    {
      "fromTable": "customer.customer",
      "toTables": [
        "commerce.customer"
      ]
    },
    {
      "fromTable": "commerce.customer@rdonly",
      "toTables": [
        "commerce.customer"
      ]
    },
    {
      "fromTable": "customer.corder@replica",
      "toTables": [
        "commerce.corder"
      ]
    }
  ]
}
```

The `MoveTables` operation has created [routing rules](../../../reference/features/schema-routing-rules/) to explicitly route
queries against the `customer` and `corder` tables — including the fully qualified `customer.customer` and `customer.corder`
names — to the respective tables in the `commerce` keyspace so that currently all requests go to the original keyspace.  This
is done so that when `MoveTables` creates the new copy of the tables in the `customer` keyspace, there is no ambiguity about
where to route requests for the `customer` and `corder` tables. All requests for those tables will keep going to the original
instance of those tables in `commerce` keyspace. Any changes to the tables after the `MoveTables` is executed will
be copied faithfully to the new copy of these tables in the `customer` keyspace.

## Monitoring Progress (Optional)

In this example there are only a few rows in the tables, so the `MoveTables` operation only takes seconds. If the tables were large, however, you may need to monitor the progress of the operation. You can get a basic summary of the progress using the [`Progress`](../../../reference/vreplication/movetables/#progress) action:

```bash
$ vtctlclient MoveTables -- Progress customer.commerce2customer

The following vreplication streams exist for workflow customer.commerce2customer:

id=1 on 0/zone1-0000000201: Status: Running. VStream Lag: 0s.
```

You can get detailed status and progress information using the
[`Workflow show`](../../../reference/vreplication/workflow/) command: 
```json
$ vtctlclient Workflow customer.commerce2customer show
{
	"Workflow": "commerce2customer",
	"SourceLocation": {
		"Keyspace": "commerce",
		"Shards": [
			"0"
		]
	},
	"TargetLocation": {
		"Keyspace": "customer",
		"Shards": [
			"0"
		]
	},
	"MaxVReplicationLag": 1,
	"MaxVReplicationTransactionLag": 1,
	"Frozen": false,
	"ShardStatuses": {
		"0/zone1-0000000201": {
			"PrimaryReplicationStatuses": [
				{
					"Shard": "0",
					"Tablet": "zone1-0000000201",
					"ID": 1,
					"Bls": {
						"keyspace": "commerce",
						"shard": "0",
						"filter": {
							"rules": [
								{
									"match": "customer",
									"filter": "select * from customer"
								},
								{
									"match": "corder",
									"filter": "select * from corder"
								}
							]
						}
					},
					"Pos": "7e765c5c-8c59-11ed-9d2e-7c501ea4de6a:1-83",
					"StopPos": "",
					"State": "Running",
					"DBName": "vt_customer",
					"TransactionTimestamp": 0,
					"TimeUpdated": 1672857697,
					"TimeHeartbeat": 1672857697,
					"TimeThrottled": 0,
					"ComponentThrottled": "",
					"Message": "",
					"Tags": "",
					"WorkflowType": "MoveTables",
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

## Validate Correctness (Optional)

We can use [`VDiff`](../../../reference/vreplication/vdiff/) to perform a logical diff between the sources and target
to confirm that they are fully in sync:

```bash
$ vtctlclient VDiff -- --v2 customer.commerce2customer create
{
	"UUID": "d050262e-8c5f-11ed-ac72-920702940ee0"
}

$ vtctlclient VDiff -- --v2 --format=json --verbose customer.commerce2customer show last
{
	"Workflow": "commerce2customer",
	"Keyspace": "customer",
	"State": "completed",
	"UUID": "d050262e-8c5f-11ed-ac72-920702940ee0",
	"RowsCompared": 10,
	"HasMismatch": false,
	"Shards": "0",
	"StartedAt": "2023-01-04 18:44:26",
	"CompletedAt": "2023-01-04 18:44:26",
	"TableSummary": {
		"corder": {
			"TableName": "corder",
			"State": "completed",
			"RowsCompared": 5,
			"MatchingRows": 5,
			"MismatchedRows": 0,
			"ExtraRowsSource": 0,
			"ExtraRowsTarget": 0
		},
		"customer": {
			"TableName": "customer",
			"State": "completed",
			"RowsCompared": 5,
			"MatchingRows": 5,
			"MismatchedRows": 0,
			"ExtraRowsSource": 0,
			"ExtraRowsTarget": 0
		}
	},
	"Reports": {
		"corder": {
			"0": {
				"TableName": "corder",
				"ProcessedRows": 5,
				"MatchingRows": 5,
				"MismatchedRows": 0,
				"ExtraRowsSource": 0,
				"ExtraRowsTarget": 0
			}
		},
		"customer": {
			"0": {
				"TableName": "customer",
				"ProcessedRows": 5,
				"MatchingRows": 5,
				"MismatchedRows": 0,
				"ExtraRowsSource": 0,
				"ExtraRowsTarget": 0
			}
		}
	}
}
```

{{< info >}}
This can take a long time to complete on very large tables.
{{</ info >}}

## Switching Traffic

Once the `MoveTables` operation is complete ([in the "running" or replicating phase](../../../../design-docs/vreplication/life-of-a-stream/)), the first step in making the changes live is to _switch_ all query serving
traffic from the old `commerce` keyspace to the `customer` keyspace for the tables we moved. Queries against the other
tables will continue to route to the `commerce` keyspace.

```bash
$ vtctlclient MoveTables -- SwitchTraffic customer.commerce2customer

SwitchTraffic was successful for workflow customer.commerce2customer
Start State: Reads Not Switched. Writes Not Switched
Current State: All Reads Switched. Writes Switched
```

{{< info >}}
While we have switched all traffic in this example, you can also switch non-primary reads and writes separately by
specifying the [`--tablet_types`](../../../reference/vreplication/movetables/#--tablet_types) parameter to
`SwitchTraffic`.
{{</ info >}}

## Check the Routing Rules (Optional)

If we now look at the [routing rules](../../../reference/features/schema-routing-rules/) after the `SwitchTraffic`
step, we will see that all queries against the `customer` and `corder` tables will get routed to the `customer` keyspace:

```json
$ vtctldclient GetRoutingRules
{
  "rules": [
    {
      "from_table": "commerce.corder@rdonly",
      "to_tables": [
        "customer.corder"
      ]
    },
    {
      "from_table": "corder@rdonly",
      "to_tables": [
        "customer.corder"
      ]
    },
    {
      "from_table": "customer.corder@replica",
      "to_tables": [
        "customer.corder"
      ]
    },
    {
      "from_table": "commerce.corder@replica",
      "to_tables": [
        "customer.corder"
      ]
    },
    {
      "from_table": "customer.corder@rdonly",
      "to_tables": [
        "customer.corder"
      ]
    },
    {
      "from_table": "customer@replica",
      "to_tables": [
        "customer.customer"
      ]
    },
    {
      "from_table": "customer.customer@replica",
      "to_tables": [
        "customer.customer"
      ]
    },
    {
      "from_table": "corder@replica",
      "to_tables": [
        "customer.corder"
      ]
    },
    {
      "from_table": "commerce.customer@rdonly",
      "to_tables": [
        "customer.customer"
      ]
    },
    {
      "from_table": "customer@rdonly",
      "to_tables": [
        "customer.customer"
      ]
    },
    {
      "from_table": "customer.customer@rdonly",
      "to_tables": [
        "customer.customer"
      ]
    },
    {
      "from_table": "commerce.customer@replica",
      "to_tables": [
        "customer.customer"
      ]
    },
    {
      "from_table": "corder",
      "to_tables": [
        "customer.corder"
      ]
    },
    {
      "from_table": "commerce.corder",
      "to_tables": [
        "customer.corder"
      ]
    },
    {
      "from_table": "customer",
      "to_tables": [
        "customer.customer"
      ]
    },
    {
      "from_table": "commerce.customer",
      "to_tables": [
        "customer.customer"
      ]
    }
  ]
}
```

## Reverting the Switch (Optional)

As part of the `SwitchTraffic` operation, Vitess will automatically setup a reverse VReplication workflow (unless
you supply the [`--reverse_replication false` flag](../../../reference/vreplication/movetables/#--reverse_replication))
to copy changes now applied to the moved tables in the target keyspace — `customer` and `corder` in the
`customer` keyspace — back to the original source tables in the source `commerce` keyspace. This allows us to
reverse or revert the cutover using the [`ReverseTraffic`](../../../reference/vreplication/movetables/#reversetraffic)
action, without data loss, even after we have started writing to the new `customer` keyspace. Note that the
workflow for this reverse workflow is created in the original source keyspace and given the name of the original
workflow with `_reverse` appended. So in our example where the `MoveTables` workflow was in the `customer` keyspace
and called `commerce2customer`, the reverse workflow is in the `commerce` keyspace and called
`commerce2customer_reverse`. We can see the details of this auto-created workflow using the
[`Workflow show`](../../../reference/vreplication/workflow/) command:

```json
$ vtctlclient Workflow commerce.commerce2customer_reverse show
{
	"Workflow": "commerce2customer_reverse",
	"SourceLocation": {
		"Keyspace": "customer",
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
		"0/zone1-0000000100": {
			"PrimaryReplicationStatuses": [
				{
					"Shard": "0",
					"Tablet": "zone1-0000000100",
					"ID": 1,
					"Bls": {
						"keyspace": "customer",
						"shard": "0",
						"filter": {
							"rules": [
								{
									"match": "customer",
									"filter": "select * from `customer`"
								},
								{
									"match": "corder",
									"filter": "select * from `corder`"
								}
							]
						}
					},
					"Pos": "9fb1be70-8c59-11ed-9ef5-c05f9df6f7f3:1-2361",
					"StopPos": "",
					"State": "Running",
					"DBName": "vt_commerce",
					"TransactionTimestamp": 1672858428,
					"TimeUpdated": 1672859207,
					"TimeHeartbeat": 1672859207,
					"TimeThrottled": 0,
					"ComponentThrottled": "",
					"Message": "",
					"Tags": "",
					"WorkflowType": "MoveTables",
					"WorkflowSubType": "None",
					"CopyState": null
				}
			],
			"TabletControls": [
				{
					"tablet_type": 1,
					"denied_tables": [
						"corder",
						"customer"
					]
				}
			],
			"PrimaryIsServing": true
		}
	},
	"SourceTimeZone": "",
	"TargetTimeZone": ""
}
```

## Finalize and Cleanup

The final step is to complete the migration using the [`Complete`](../../../reference/vreplication/movetables/#complete) action.
This will (by default) get rid of the [routing rules](../../../reference/features/schema-routing-rules/) that were created and
`DROP` the original tables in the source keyspace (`commerce`). Along with freeing up space on the original tablets, this is an
important step to eliminate potential future confusion. If you have a misconfiguration down the line and accidentally route queries
for the  `customer` and `corder` tables to the `commerce` keyspace, it is much better to return a *"table not found"*
error, rather than return incorrect/stale data:

```bash
$ vtctlclient MoveTables -- Complete customer.commerce2customer

Complete was successful for workflow customer.commerce2customer
Start State: All Reads Switched. Writes Switched
Current State: Workflow Not Found
```

{{< info >}}
This command will return an error if you have not already switched all traffic.
{{</ info >}}

After this step is complete, you should see an error if you try to query the moved tables in the original `commerce`
keyspace:

```bash
# Expected to fail!
$ mysql < ../common/select_commerce_data.sql
Using commerce
Customer
ERROR 1146 (42S02) at line 4: target: commerce.0.primary: vttablet: rpc error: code = NotFound desc = Table 'vt_commerce.customer' doesn't exist (errno 1146) (sqlstate 42S02) (CallerID: userData1): Sql: "select * from customer", BindVars: {}

# Expected to be empty
$ vtctldclient GetRoutingRules
{
  "rules": []
}

# Workflow is gone
$ vtctlclient Workflow customer listall
No workflows found in keyspace customer

# Reverse workflow is also gone
$ vtctlclient Workflow commerce listall
No workflows found in keyspace commerce
```

This confirms that the data and routing rules have been properly cleaned up. Note that the `Complete` process also cleans up the reverse VReplication workflow mentioned above.

## Next Steps

Congratulations! You've successfully moved tables between into Vitess or between keyspaces. The next step to try out is
sharding one of your keyspaces using [Resharding](../../configuration-advanced/resharding).
