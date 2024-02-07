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
vtctldclient MoveTables --target-keyspace customer --workflow commerce2customer create --source-keyspace commerce --tables 'customer,corder'
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

In this example there are only a few rows in the tables, so the `MoveTables` operation only takes seconds. If the tables were large, however, you may need to monitor the progress of the operation. You can get a basic summary of the progress using the [`status`](../../../reference/vreplication/movetables/#status) action:

```bash
$ vtctldclient MoveTables --target-keyspace customer --workflow commerce2customer status --format=json
{
  "table_copy_state": {},
  "shard_streams": {
    "customer/0": {
      "streams": [
        {
          "id": 2,
          "tablet": {
            "cell": "zone1",
            "uid": 200
          },
          "source_shard": "commerce/0",
          "position": "5d8e0b24-6873-11ee-9359-49d03ab2cdee:1-51",
          "status": "Running",
          "info": "VStream Lag: 0s"
        }
      ]
    }
  },
  "traffic_state": "Reads Not Switched. Writes Not Switched"
}
```

You can get more detailed status information using the
[`show`](../../../reference/programs/vtctldclient/vtctldclient_movetables/vtctldclient_movetables_show/) sub-command:

```json
$ vtctldclient MoveTables --target-keyspace customer --workflow commerce2customer show --include-logs=false 
{
  "workflows": [
    {
      "name": "commerce2customer",
      "source": {
        "keyspace": "commerce",
        "shards": [
          "0"
        ]
      },
      "target": {
        "keyspace": "customer",
        "shards": [
          "0"
        ]
      },
      "max_v_replication_lag": "1",
      "shard_streams": {
        "0/zone1-0000000200": {
          "streams": [
            {
              "id": "2",
              "shard": "0",
              "tablet": {
                "cell": "zone1",
                "uid": 200
              },
              "binlog_source": {
                "keyspace": "commerce",
                "shard": "0",
                "tablet_type": "UNKNOWN",
                "key_range": null,
                "tables": [],
                "filter": {
                  "rules": [
                    {
                      "match": "customer",
                      "filter": "select * from customer",
                      "convert_enum_to_text": {},
                      "convert_charset": {},
                      "source_unique_key_columns": "",
                      "target_unique_key_columns": "",
                      "source_unique_key_target_columns": "",
                      "convert_int_to_enum": {}
                    },
                    {
                      "match": "corder",
                      "filter": "select * from corder",
                      "convert_enum_to_text": {},
                      "convert_charset": {},
                      "source_unique_key_columns": "",
                      "target_unique_key_columns": "",
                      "source_unique_key_target_columns": "",
                      "convert_int_to_enum": {}
                    }
                  ],
                  "field_event_mode": "ERR_ON_MISMATCH",
                  "workflow_type": "0",
                  "workflow_name": ""
                },
                "on_ddl": "IGNORE",
                "external_mysql": "",
                "stop_after_copy": false,
                "external_cluster": "",
                "source_time_zone": "",
                "target_time_zone": ""
              },
              "position": "5d8e0b24-6873-11ee-9359-49d03ab2cdee:1-51",
              "stop_position": "",
              "state": "Running",
              "db_name": "vt_customer",
              "transaction_timestamp": {
                "seconds": "0",
                "nanoseconds": 0
              },
              "time_updated": {
                "seconds": "1697060227",
                "nanoseconds": 0
              },
              "message": "",
              "copy_states": [],
              "logs": [],
              "log_fetch_error": "",
              "tags": [],
              "rows_copied": "0",
              "throttler_status": {
                "component_throttled": "",
                "time_throttled": {
                  "seconds": "0",
                  "nanoseconds": 0
                }
              }
            }
          ],
          "tablet_controls": [],
          "is_primary_serving": true
        }
      },
      "workflow_type": "MoveTables",
      "workflow_sub_type": "None",
      "max_v_replication_transaction_lag": "1",
      "defer_secondary_keys": false
    }
  ]
}
```

## Validate Correctness (Optional)

We can use [`VDiff`](../../../reference/vreplication/vdiff/) to perform a logical diff between the sources and target
to confirm that they are fully in sync:

```bash
$ vtctldclient VDiff --target-keyspace customer --workflow commerce2customer create
VDiff bc74b91b-2ee8-4869-bc39-4740ce445e20 scheduled on target shards, use show to view progress

$ vtctldclient VDiff --format=json --target-keyspace customer --workflow commerce2customer show last --verbose
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
$ vtctldclient MoveTables --target-keyspace customer --workflow commerce2customer SwitchTraffic
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
you supply the `--enable-reverse-replication=false` flag) to copy changes now applied to the moved tables in the
target keyspace — `customer` and `corder` in the `customer` keyspace — back to the original source tables in the
source `commerce` keyspace. This allows us to reverse or revert the cutover using the [`ReverseTraffic`](../../../reference/vreplication/movetables/#reversetraffic)
action, without data loss, even after we have started writing to the new `customer` keyspace. Note that the
workflow for this reverse workflow is created in the original source keyspace and given the name of the original
workflow with `_reverse` appended. So in our example where the `MoveTables` workflow was in the `customer` keyspace
and called `commerce2customer`, the reverse workflow is in the `commerce` keyspace and called
`commerce2customer_reverse`. We can see the details of this auto-created workflow using the
[`Workflow show`](../../../reference/vreplication/workflow/) command:

```json
$ vtctldclient Workflow --keyspace commerce show --workflow commerce2customer_reverse
{
  "workflows": [
    {
      "name": "commerce2customer_reverse",
      "source": {
        "keyspace": "customer",
        "shards": [
          "0"
        ]
      },
      "target": {
        "keyspace": "commerce",
        "shards": [
          "0"
        ]
      },
      "max_v_replication_lag": "1",
      "shard_streams": {
        "0/zone1-0000000101": {
          "streams": [
            {
              "id": "1",
              "shard": "0",
              "tablet": {
                "cell": "zone1",
                "uid": 101
              },
              "binlog_source": {
                "keyspace": "customer",
                "shard": "0",
                "tablet_type": "UNKNOWN",
                "key_range": null,
                "tables": [],
                "filter": {
                  "rules": [
                    {
                      "match": "customer",
                      "filter": "select * from `customer`",
                      "convert_enum_to_text": {},
                      "convert_charset": {},
                      "source_unique_key_columns": "",
                      "target_unique_key_columns": "",
                      "source_unique_key_target_columns": "",
                      "convert_int_to_enum": {}
                    },
                    {
                      "match": "corder",
                      "filter": "select * from `corder`",
                      "convert_enum_to_text": {},
                      "convert_charset": {},
                      "source_unique_key_columns": "",
                      "target_unique_key_columns": "",
                      "source_unique_key_target_columns": "",
                      "convert_int_to_enum": {}
                    }
                  ],
                  "field_event_mode": "ERR_ON_MISMATCH",
                  "workflow_type": "0",
                  "workflow_name": ""
                },
                "on_ddl": "IGNORE",
                "external_mysql": "",
                "stop_after_copy": false,
                "external_cluster": "",
                "source_time_zone": "",
                "target_time_zone": ""
              },
              "position": "751b3b58-6874-11ee-9a45-2b583b20ee4a:1-4579",
              "stop_position": "",
              "state": "Running",
              "db_name": "vt_commerce",
              "transaction_timestamp": {
                "seconds": "1697060479",
                "nanoseconds": 0
              },
              "time_updated": {
                "seconds": "1697060690",
                "nanoseconds": 0
              },
              "message": "",
              "copy_states": [],
              "logs": [
                {
                  "id": "1",
                  "stream_id": "1",
                  "type": "Stream Created",
                  "state": "Stopped",
                  "created_at": {
                    "seconds": "1697046079",
                    "nanoseconds": 0
                  },
                  "updated_at": {
                    "seconds": "1697046079",
                    "nanoseconds": 0
                  },
                  "message": "{\"component_throttled\":\"\",\"db_name\":\"vt_commerce\",\"defer_secondary_keys\":\"0\",\"id\":\"1\",\"max_replication_lag\":\"9223372036854775807\",\"max_tps\":\"9223372036854775807\",\"pos\":\"MySQL56/751b3b58-6874-11ee-9a45-2b583b20ee4a:1-4577\",\"rows_copied\":\"0\",\"source\":\"keyspace:\\\"customer\\\" shard:\\\"0\\\" filter:{rules:{match:\\\"customer\\\" filter:\\\"select * from `customer`\\\"} rules:{match:\\\"corder\\\" filter:\\\"select * from `corder`\\\"}}\",\"state\":\"Stopped\",\"tags\":\"\",\"time_heartbeat\":\"0\",\"time_throttled\":\"0\",\"time_updated\":\"1697060479\",\"transaction_timestamp\":\"0\",\"workflow\":\"commerce2customer_reverse\",\"workflow_sub_type\":\"0\",\"workflow_type\":\"1\"}",
                  "count": "1"
                },
                {
                  "id": "2",
                  "stream_id": "1",
                  "type": "State Changed",
                  "state": "Running",
                  "created_at": {
                    "seconds": "1697046079",
                    "nanoseconds": 0
                  },
                  "updated_at": {
                    "seconds": "1697046079",
                    "nanoseconds": 0
                  },
                  "message": "",
                  "count": "1"
                }
              ],
              "log_fetch_error": "",
              "tags": [],
              "rows_copied": "0",
              "throttler_status": {
                "component_throttled": "",
                "time_throttled": {
                  "seconds": "0",
                  "nanoseconds": 0
                }
              }
            }
          ],
          "tablet_controls": [
            {
              "tablet_type": "PRIMARY",
              "cells": [],
              "denied_tables": [
                "corder",
                "customer"
              ],
              "frozen": false
            }
          ],
          "is_primary_serving": true
        }
      },
      "workflow_type": "MoveTables",
      "workflow_sub_type": "None",
      "max_v_replication_transaction_lag": "1",
      "defer_secondary_keys": false
    }
  ]
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
$ vtctldclient MoveTables --target-keyspace customer --workflow commerce2customer complete
Successfully completed the commerce2customer workflow in the customer keyspace
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
$ vtctldclient Workflow --keyspace customer list
[]

# Reverse workflow is also gone
$ vtctldclient Workflow --keyspace commerce list
[]
```

This confirms that the data and routing rules have been properly cleaned up. Note that the `Complete` process also cleans up the reverse VReplication workflow mentioned above.

## Next Steps

Congratulations! You've successfully moved tables between into Vitess or between keyspaces. The next step to try out is
sharding one of your keyspaces using [Resharding](../../configuration-advanced/resharding).
