---
title: Creating a LookupVindex
weight: 30
aliases: ['/docs/user-guides/createlookupvindex/']
---

{{< info >}}
This guide follows on from the Get Started guides. Please make sure that you have
an [Operator](../../../get-started/operator) or [local](../../../get-started/local) installation ready. Make sure you
are at the point where you have the sharded keyspace called `customer` setup.
{{< /info >}}

[`LookupVindex create`](../../../reference/programs/vtctldclient/vtctldclient_lookupvindex/vtctldclient_lookupvindex_create/) uses a [VReplication](../../../reference/vreplication/) workflow used to create **and** backfill
a [Lookup Vindex](../../../reference/features/vindexes/#lookup-vindex-types) automatically for a table that already
exists, and may have a significant amount of data in it already.

Internally, the [`LookupVindex create`](../../../reference/programs/vtctldclient/vtctldclient_lookupvindex/vtctldclient_lookupvindex_create/) command uses
VReplication for the backfill process, until the lookup Vindex is "in sync". Then the normal process for
adding/deleting/updating rows in the lookup Vindex via the usual
[transactional flow when updating the "owner" table for the Vindex](../../../reference/features/vindexes/#lookup-vindex-types)
takes over.

In this guide, we will walk through the process of using the [`LookupVindex create`](../../../reference/programs/vtctldclient/vtctldclient_lookupvindex/vtctldclient_lookupvindex_create/) command, and give some insight into what happens underneath the covers.

You can see the details of the [`LookupVindex create` command](../../../reference/programs/vtctldclient/vtctldclient_lookupvindex/vtctldclient_lookupvindex_create/) in the reference docs.

In the context of the `customer` database that is part of the Vitess examples we
started earlier, let's add some rows into the `customer.corder` table, and then
look at an example command:

```bash
$ mysql -P 15306 -h 127.0.0.1 -u root --binary-as-hex=false -A
Welcome to the MySQL monitor.  Commands end with ; or \g.
...
```

```mysql
mysql> use customer;
Database changed

mysql> show tables;
+-----------------------+
| Tables_in_vt_customer |
+-----------------------+
| corder                |
| customer              |
+-----------------------+
2 rows in set (0.00 sec)

mysql> desc corder;
+-------------+----------------+------+-----+---------+-------+
| Field       | Type           | Null | Key | Default | Extra |
+-------------+----------------+------+-----+---------+-------+
| order_id    | bigint         | NO   | PRI | NULL    |       |
| customer_id | bigint         | YES  |     | NULL    |       |
| sku         | varbinary(128) | YES  |     | NULL    |       |
| price       | bigint         | YES  |     | NULL    |       |
+-------------+----------------+------+-----+---------+-------+
4 rows in set (0.01 sec)

mysql> insert into corder (order_id, customer_id, sku, price) values (1, 1, "Product_1", 100);
Query OK, 1 row affected (0.01 sec)

mysql> insert into corder (order_id, customer_id, sku, price) values (2, 1, "Product_2", 101);
Query OK, 1 row affected (0.01 sec)

mysql> insert into corder (order_id, customer_id, sku, price) values (3, 2, "Product_3", 102);
Query OK, 1 row affected (0.01 sec)

mysql> insert into corder (order_id, customer_id, sku, price) values (4, 3, "Product_4", 103);
Query OK, 1 row affected (0.01 sec)

mysql> insert into corder (order_id, customer_id, sku, price) values (5, 4, "Product_5", 104);
Query OK, 1 row affected (0.03 sec)

mysql> select * from corder;
+----------+-------------+-----------+-------+
| order_id | customer_id | sku       | price |
+----------+-------------+-----------+-------+
|        1 |           1 | Product_1 |   100 |
|        2 |           1 | Product_2 |   101 |
|        3 |           2 | Product_3 |   102 |
|        4 |           3 | Product_4 |   103 |
|        5 |           4 | Product_5 |   104 |
+----------+-------------+-----------+-------+
5 rows in set (0.01 sec)
```

</br>

If we look at the [VSchema](../../../reference/features/vschema/) for the
`customer.corder` table, we will see there is a `hash` index on the
`customer_id` column:

```json
$ vtctldclient GetVSchema customer
{
  "sharded": true,
  "vindexes": {
    "hash": {
      "type": "hash",
      "params": {},
      "owner": ""
    }
  },
  "tables": {
    "corder": {
      "type": "",
      "column_vindexes": [
        {
          "column": "customer_id",
          "name": "hash",
          "columns": []
        }
      ],
      "auto_increment": {
        "column": "order_id",
        "sequence": "order_seq"
      },
      "columns": [],
      "pinned": "",
      "column_list_authoritative": false,
      "source": ""
    },
    "customer": {
      "type": "",
      "column_vindexes": [
        {
          "column": "customer_id",
          "name": "hash",
          "columns": []
        }
      ],
      "auto_increment": {
        "column": "customer_id",
        "sequence": "customer_seq"
      },
      "columns": [],
      "pinned": "",
      "column_list_authoritative": false,
      "source": ""
    }
  },
  "require_explicit_routing": false
}
```

</br>

We can now see that 4 of our 5 rows have ended up on the `-80` shard with the
5th row on the `80-` shard:

```sql
mysql> use customer/-80
Database changed

mysql> select * from corder;
+----------+-------------+-----------+-------+
| order_id | customer_id | sku       | price |
+----------+-------------+-----------+-------+
|        1 |           1 | Product_1 |   100 |
|        2 |           1 | Product_2 |   101 |
|        3 |           2 | Product_3 |   102 |
|        4 |           3 | Product_4 |   103 |
+----------+-------------+-----------+-------+
4 rows in set (0.00 sec)

mysql> use customer/80-
Database changed

mysql> select * from corder;
+----------+-------------+-----------+-------+
| order_id | customer_id | sku       | price |
+----------+-------------+-----------+-------+
|        5 |           4 | Product_5 |   104 |
+----------+-------------+-----------+-------+
1 row in set (0.01 sec)
```

</br>

Note that this skewed distribution is completely coincidental — for larger
numbers of rows we would expect the distribution to be approximately even
for a `hash` index.

Now let's say we want to add a lookup Vindex on the `sku` column.
We can use a [`consistent_lookup` or `consistent_lookup_unique`](../../vschema-guide/unique-lookup/)
Vindex type. In our example we will use `consistent_lookup_unique`.

Note that as mentioned above, we do not have to tell Vitess about
how to shard the actual backing table for the lookup Vindex or
any schema to create as it will do it automatically. Now, let us
actually execute the `LookupVindex create` command:

```bash
vtctldclient --server localhost:15999 LookupVindex --name customer_region_lookup --table-keyspace main create --keyspace main --type consistent_lookup_unique --table-owner customer --table-owner-columns=id --tablet-types=PRIMARY
```

</br>

Note:

* We are specifying a tablet_type of `RDONLY`; meaning it is going to
  run the VReplication streams from tablets of the `RDONLY` type **only**.
  If tablets of this type cannot be found, in a shard, the lookup Vindex
  population will fail.

Now, in our case, the table is tiny, so the copy will be instant, but
in a real-world case this might take hours. To monitor the process,
we can use the usual VReplication commands. However, the VReplication
status commands needs to operate on individual tablets. Let's check
which tablets we have in our environment, so we know which tablets to
issue commands against:

```bash
$ vtctldclient --server localhost:15999 GetTablets --keyspace customer
zone1-0000000300 customer -80 primary localhost:15300 localhost:17300 [] 2020-08-13T01:23:15Z
zone1-0000000301 customer -80 replica localhost:15301 localhost:17301 [] <null>
zone1-0000000302 customer -80 rdonly localhost:15302 localhost:17302 [] <null>
zone1-0000000400 customer 80- primary localhost:15400 localhost:17400 [] 2020-08-13T01:23:15Z
zone1-0000000401 customer 80- replica localhost:15401 localhost:17401 [] <null>
zone1-0000000402 customer 80- rdonly localhost:15402 localhost:17402 [] <null>
```

</br>

Now we can look what happened in greater detail:

* VReplication streams were setup from the primary tablets
  `zone1-0000000300` and `zone1-0000000400`; pulling data from the `RDONLY`
  source tablets `zone1-0000000302` and `zone1-0000000402`.
* Note that each primary tablet will start streams from each source
  tablet, for a total of 4 streams in this case.

Lets observe the VReplication streams that got created using the `show` sub-command.

{{< info >}}
The created vreplication workflow will have a generated name of `<target_table_name>_vdx`.
So in our example here: `corder_lookup_vdx`.
{{< /info >}}

```json
$ vtctldclient --server localhost:15999 LookupVindex --name customer_region_lookup --table-keyspace main show --include-logs=false
{
  "workflows": [
    {
      "name": "customer_region_lookup",
      "source": {
        "keyspace": "main",
        "shards": [
          "0"
        ]
      },
      "target": {
        "keyspace": "main",
        "shards": [
          "0"
        ]
      },
      "max_v_replication_lag": "0",
      "shard_streams": {
        "0/zone1-0000000100": {
          "streams": [
            {
              "id": "1",
              "shard": "0",
              "tablet": {
                "cell": "zone1",
                "uid": 100
              },
              "binlog_source": {
                "keyspace": "main",
                "shard": "0",
                "tablet_type": "UNKNOWN",
                "key_range": null,
                "tables": [],
                "filter": {
                  "rules": [
                    {
                      "match": "customer_region_lookup",
                      "filter": "select id as id, keyspace_id() as keyspace_id from customer where in_keyrange(id, 'main.xxhash', '-') group by id, keyspace_id",
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
              "position": "63c84d28-6888-11ee-93b0-81b2fbd12545:1-63",
              "stop_position": "",
              "state": "Running",
              "db_name": "vt_main",
              "transaction_timestamp": {
                "seconds": "1697064644",
                "nanoseconds": 0
              },
              "time_updated": {
                "seconds": "1697064646",
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
      "workflow_type": "CreateLookupIndex",
      "workflow_sub_type": "None",
      "max_v_replication_transaction_lag": "0",
      "defer_secondary_keys": false
    }
  ]
}
```

</br>

There is a lot going on in this output, but the most important parts are the
`state` and `message` fields which say `Stopped` and `Stopped after copy.`
for all four of the streams. This means that the VReplication streams finished
their copying/backfill of the lookup table.

Note that if the tables were large and the copy was still in progress, the
`state` field would say `Copying` — you can see the state/progress as part
of `Workflow show` json output.

We can verify the result of the backfill by looking at the `customer`
keyspace again in the MySQL client:

```sql
mysql> show tables;
+-----------------------+
| Tables_in_vt_customer |
+-----------------------+
| corder                |
| corder_lookup         |
| customer              |
+-----------------------+
3 rows in set (0.01 sec)
```

</br>

Note there is now a new table, `corder_lookup`; which was created as the
backing table for the lookup Vindex. Lets look at this table:

```sql
mysql> desc corder_lookup;
+-------------+----------------+------+-----+---------+-------+
| Field       | Type           | Null | Key | Default | Extra |
+-------------+----------------+------+-----+---------+-------+
| sku         | varbinary(128) | NO   | PRI | NULL    |       |
| keyspace_id | varbinary(128) | YES  |     | NULL    |       |
+-------------+----------------+------+-----+---------+-------+
2 rows in set (0.01 sec)

mysql> select sku, hex(keyspace_id) from corder_lookup;
+-----------+------------------+
| sku       | hex(keyspace_id) |
+-----------+------------------+
| Product_2 | 166B40B44ABA4BD6 |
| Product_3 | 06E7EA22CE92708F |
| Product_1 | 166B40B44ABA4BD6 |
| Product_4 | 4EB190C9A2FA169C |
| Product_5 | D2FD8867D50D2DFE |
+-----------+------------------+
```

</br>

Basically, this shows exactly what we expected. Now, we have to clean-up
the artifacts of the backfill. The `ExternalizeVindex` command will delete
the VReplication streams and also clear the `write_only` flag from the
Vindex indicating that it is *not* backfilling anymore.

```bash
$ vtctldclient --server localhost:15999 LookupVindex --name customer_region_lookup --table-keyspace main externalize
LookupVindex customer_region_lookup has been externalized and the customer_region_lookup VReplication workflow has been deleted
```

</br>

Next, to confirm the lookup Vindex is doing what we think it should, we can
use the [`vexplain plan` SQL statement](../../sql/vexplain/):

```sql
mysql> vexplain plan select * from corder where customer_id = 1;
+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| JSON                                                                                                                                                                                                                                                                                                                                                                |
+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| {
	"OperatorType": "Route",
	"Variant": "EqualUnique",
	"Keyspace": {
		"Name": "customer",
		"Sharded": true
	},
	"FieldQuery": "select order_id, customer_id, sku, price from corder where 1 != 1",
	"Query": "select order_id, customer_id, sku, price from corder where customer_id = 1",
	"Table": "corder",
	"Values": [
		"INT64(1)"
	],
	"Vindex": "hash"
} |
+---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
1 row in set (0.00 sec)
```

</br>

Since the above `select` statement is doing a lookup using the primary Vindex
on the `corder` table, this query does not Scatter (variant is
`SelectEqualUnique`), as expected. Let's try a scatter query to see what that
looks like:

```sql
mysql> vexplain select * from corder;
+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| JSON                                                                                                                                                                                                                                                                                     |
+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| {
	"OperatorType": "Route",
	"Variant": "Scatter",
	"Keyspace": {
		"Name": "customer",
		"Sharded": true
	},
	"FieldQuery": "select order_id, customer_id, sku, price from corder where 1 != 1",
	"Query": "select order_id, customer_id, sku, price from corder",
	"Table": "corder"
} |
+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
1 row in set (0.00 sec)
```

So now we see the expectied variant of `SelectScatter` for a scatter query.
Let's try a lookup on a column that does *not* have a primary or secondary
(lookup) Vindex, e.g. the `price` column:

```sql
mysql> vexplain select * from corder where price = 103\G
*************************** 1. row ***************************
JSON: {
	"OperatorType": "Route",
	"Variant": "Scatter",
	"Keyspace": {
		"Name": "customer",
		"Sharded": true
	},
	"FieldQuery": "select order_id, customer_id, sku, price from corder where 1 != 1",
	"Query": "select order_id, customer_id, sku, price from corder where price = 103",
	"Table": "corder"
}
1 row in set (0.00 sec)
```

That also scatters, as expected, because there's no Vindex on the column.

Now, let's try a lookup on the `sku` column, which we have created our lookup
Vindex on:

```sql
mysql> vexplain select * from corder where sku = "Product_1";
+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| JSON                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           |
+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
| {
	"OperatorType": "VindexLookup",
	"Variant": "EqualUnique",
	"Keyspace": {
		"Name": "customer",
		"Sharded": true
	},
	"Values": [
		"VARCHAR(\"Product_1\")"
	],
	"Vindex": "corder_lookup",
	"Inputs": [
		{
			"OperatorType": "Route",
			"Variant": "IN",
			"Keyspace": {
				"Name": "customer",
				"Sharded": true
			},
			"FieldQuery": "select sku, keyspace_id from corder_lookup where 1 != 1",
			"Query": "select sku, keyspace_id from corder_lookup where sku in ::__vals",
			"Table": "corder_lookup",
			"Values": [
				":sku"
			],
			"Vindex": "binary_md5"
		},
		{
			"OperatorType": "Route",
			"Variant": "ByDestination",
			"Keyspace": {
				"Name": "customer",
				"Sharded": true
			},
			"FieldQuery": "select order_id, customer_id, sku, price from corder where 1 != 1",
			"Query": "select order_id, customer_id, sku, price from corder where sku = 'Product_1'",
			"Table": "corder"
		}
	]
} |
+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
1 row in set (0.00 sec)
```

</br>

As expected, we can see it is not scattering anymore, which it would have
before we executed the `CreateLookupVindex` command.

Lastly, let's ensure that the lookup Vindex is being updated appropriately
when we insert and delete rows:

```sql
mysql> select * from corder;
+----------+-------------+-----------+-------+
| order_id | customer_id | sku       | price |
+----------+-------------+-----------+-------+
|        5 |           4 | Product_5 |   104 |
|        1 |           1 | Product_1 |   100 |
|        2 |           1 | Product_2 |   101 |
|        3 |           2 | Product_3 |   102 |
|        4 |           3 | Product_4 |   103 |
+----------+-------------+-----------+-------+
5 rows in set (0.00 sec)

mysql> delete from corder where customer_id = 1 and sku = "Product_1";
Query OK, 1 row affected (0.03 sec)

mysql> select * from corder;
+----------+-------------+-----------+-------+
| order_id | customer_id | sku       | price |
+----------+-------------+-----------+-------+
|        2 |           1 | Product_2 |   101 |
|        3 |           2 | Product_3 |   102 |
|        4 |           3 | Product_4 |   103 |
|        5 |           4 | Product_5 |   104 |
+----------+-------------+-----------+-------+
4 rows in set (0.01 sec)

mysql> select sku, hex(keyspace_id) from corder_lookup;
+-----------+------------------+
| sku       | hex(keyspace_id) |
+-----------+------------------+
| Product_4 | 4EB190C9A2FA169C |
| Product_5 | D2FD8867D50D2DFE |
| Product_2 | 166B40B44ABA4BD6 |
| Product_3 | 06E7EA22CE92708F |
+-----------+------------------+
4 rows in set (0.01 sec)
```

</br>

We deleted a row from the `corder` table, and the matching lookup Vindex row
is gone. Now we can try adding a row:

```sql
mysql> insert into corder (order_id, customer_id, sku, price) values (6, 1, "Product_6", 105);
Query OK, 1 row affected (0.02 sec)

mysql> select * from corder;
+----------+-------------+-----------+-------+
| order_id | customer_id | sku       | price |
+----------+-------------+-----------+-------+
|        2 |           1 | Product_2 |   101 |
|        3 |           2 | Product_3 |   102 |
|        4 |           3 | Product_4 |   103 |
|        6 |           1 | Product_6 |   105 |
|        5 |           4 | Product_5 |   104 |
+----------+-------------+-----------+-------+
5 rows in set (0.00 sec)

mysql> select sku, hex(keyspace_id) from corder_lookup;
+-----------+------------------+
| sku       | hex(keyspace_id) |
+-----------+------------------+
| Product_4 | 4EB190C9A2FA169C |
| Product_5 | D2FD8867D50D2DFE |
| Product_6 | 166B40B44ABA4BD6 |
| Product_2 | 166B40B44ABA4BD6 |
| Product_3 | 06E7EA22CE92708F |
+-----------+------------------+
5 rows in set (0.00 sec)
```

</br>

We added a new row to the `corder` table, and now we have a new row in the
lookup table!
