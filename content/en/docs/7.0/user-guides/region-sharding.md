---
title: Region-based Sharding
weight: 8
---

{{< info >}}
This guide follows on from the Get Started guides. Please make sure that you have a [local](../../../get-started/local) installation ready. You should also have already gone through the [MoveTables](../../../migration/move-tables) and [Resharding](../../../configuration-advanced/resharding) tutorials.
{{< /info >}}

## Preparation
Having gone through the Resharding tutorial, you should be familiar with [VSchema](../../../concepts/vschema) and [Vindexes](../../../reference/vindexes).
In this tutorial, we will create a sharded keyspace using a location-based vindex. We will create 4 shards (-40, 40-80, 80-c0, c0-).
The location will be denoted by a `country` column.

## Schema
We will create 2 tables in this example.
```text
CREATE TABLE customer (
  id int NOT NULL,
  fullname varbinary(256),
  nationalid varbinary(256),
  country varbinary(256),
  primary key(id)
  );
CREATE TABLE customer_lookup (
  id int NOT NULL,
  keyspace_id varbinary(256),
  primary key(id)
  );
```

The customer table is the main table we want to shard using country. The lookup table will help us do that.

## Region Vindex
We will use a `region_json` vindex to compute the keyspace_id for a customer row using the (id, country) fields.
Here's what the vindex definition looks like:
```text
    "region_vdx": {
	"type": "region_json",
	"params": {
	    "region_map": "/vt/examples/region_sharding/countries.json",
	    "region_bytes": "1"
	}
    },
```
And we use it thus:
```text
    "customer": {
      "column_vindexes": [
        {
            "columns": ["id", "country"],
	    "name": "region_vdx"
        },
```
This vindex uses a byte mapping of countries provided in a JSON file and combines that with the id column in the customer table to compute the keyspace_id. In this example, we are using 1 byte. You can use 1 or 2 bytes. With 2 bytes, 65536 distinct locations can be supported. The byte value of the country(or other location identifier) is prefixed to a hash value computed from the id to produce the keyspace_id.

The lookup table is used to store the id to keyspace_id mapping. We connect it to the customer table as follows:
We first define a lookup vindex:
```text
    "customer_region_lookup": {
        "type": "consistent_lookup_unique",
        "params": {
            "table": "customer_lookup",
            "from": "id",
            "to": "keyspace_id"
        },
        "owner": "customer"
    },
```
Then we create it as a vindex on the customer table:
```text
    "customer": {
      "column_vindexes": [
        {
            "columns": ["id", "country"],
	    "name": "region_vdx"
        },
	{
            "column": "id",
            "name": "customer_region_lookup"
        }
      ]
    }
```

The lookup table could be unsharded or sharded. In this example, we have chosen to shard the lookup table also. If the goal of region-based sharding is data locality, it makes sense to co-locate the lookup data with the main customer data.
We first define an `identity` vindex:
```text
      "identity": {
	  "type": "binary"
      }
```
Then we create it as a vindex on the lookup table:
```text
    "customer_lookup": {
      "column_vindexes": [
	{
            "column": "keyspace_id",
            "name": "identity"
        }
      ]
    },
```

This is what the JSON file contains:
```text
{
    "United States": 1,
    "Canada": 2,
    "France": 64,
    "Germany": 65,
    "China": 128,
    "Japan": 129,
    "India": 192,
    "Indonesia": 193
}
```
The values for the countries have been chosen such that 2 countries fall into each shard.

## Start the Cluster

Start by copying the region_sharding example included with Vitess to your preferred location.
```sh
cp -r /usr/local/vitess/examples/region_sharding ~/my-vitess/examples/region_sharding
cd ~/my-vitess/examples/region_sharding
```

The VSchema for this tutorial uses a config file. You will need to edit the value of the `region_map` parameter in the vschema file `main_vschema.json`.
For example:
```text
"region_map": "/home/user/my-vitess/examples/region_sharding/countries.json",
```

Now start the cluster
```sh
./101_initial_cluster.sh
```

You should see output similar to the following:

```text
~/my-vitess-example> ./101_initial_cluster.sh
add /vitess/global
add /vitess/zone1
add zone1 CellInfo
etcd start done...
Starting vtctld...
Starting MySQL for tablet zone1-0000000100...
Starting vttablet for zone1-0000000100...
HTTP/1.1 200 OK
Date: Thu, 21 May 2020 01:05:26 GMT
Content-Type: text/html; charset=utf-8

Starting MySQL for tablet zone1-0000000200...
Starting vttablet for zone1-0000000200...
HTTP/1.1 200 OK
Date: Thu, 21 May 2020 01:05:31 GMT
Content-Type: text/html; charset=utf-8

Starting MySQL for tablet zone1-0000000300...
Starting vttablet for zone1-0000000300...
HTTP/1.1 200 OK
Date: Thu, 21 May 2020 01:05:35 GMT
Content-Type: text/html; charset=utf-8

Starting MySQL for tablet zone1-0000000400...
Starting vttablet for zone1-0000000400...
HTTP/1.1 200 OK
Date: Thu, 21 May 2020 01:05:40 GMT
Content-Type: text/html; charset=utf-8

W0520 18:05:40.443933    6824 main.go:64] W0521 01:05:40.443180 reparent.go:185] master-elect tablet zone1-0000000100 is not the shard master, proceeding anyway as -force was used
W0520 18:05:40.445230    6824 main.go:64] W0521 01:05:40.443744 reparent.go:191] master-elect tablet zone1-0000000100 is not a master in the shard, proceeding anyway as -force was used
W0520 18:05:40.496253    6841 main.go:64] W0521 01:05:40.495599 reparent.go:185] master-elect tablet zone1-0000000200 is not the shard master, proceeding anyway as -force was used
W0520 18:05:40.496508    6841 main.go:64] W0521 01:05:40.495647 reparent.go:191] master-elect tablet zone1-0000000200 is not a master in the shard, proceeding anyway as -force was used
W0520 18:05:40.537548    6858 main.go:64] W0521 01:05:40.536985 reparent.go:185] master-elect tablet zone1-0000000300 is not the shard master, proceeding anyway as -force was used
W0520 18:05:40.537758    6858 main.go:64] W0521 01:05:40.537041 reparent.go:191] master-elect tablet zone1-0000000300 is not a master in the shard, proceeding anyway as -force was used
W0520 18:05:40.577854    6875 main.go:64] W0521 01:05:40.577407 reparent.go:185] master-elect tablet zone1-0000000400 is not the shard master, proceeding anyway as -force was used
W0520 18:05:40.578042    6875 main.go:64] W0521 01:05:40.577448 reparent.go:191] master-elect tablet zone1-0000000400 is not a master in the shard, proceeding anyway as -force was used
...
Waiting for vtgate to be up...
vtgate is up!
Access vtgate at http://localhost:15001/debug/status

```

You can also verify that the processes have started with `pgrep`:

```bash
~/my-vitess-example> pgrep -fl vtdataroot
3920 etcd
4030 vtctld
4173 mysqld_safe
4779 mysqld
4817 vttablet
4901 mysqld_safe
5426 mysqld
5461 vttablet
5542 mysqld_safe
6100 mysqld
6136 vttablet
6231 mysqld_safe
6756 mysqld
6792 vttablet
6929 vtgate
```

_The exact list of processes will vary. For example, you may not see `mysqld_safe` listed._

If you encounter any errors, such as ports already in use, you can kill the processes and start over:

```sh
pkill -9 -e -f '(vtdataroot|VTDATAROOT)' # kill Vitess processes
rm -rf vtdataroot
```

## Aliases

For ease-of-use, Vitess provides aliases for `mysql` and `vtctlclient`. These are automatically created when you start the cluster.
```bash
source ./env.sh
```

Setting up aliases changes `mysql` to always connect to Vitess for your current session. To revert this, type `unalias mysql && unalias vtctlclient` or close your session.

## Connect to your cluster

You should now be able to connect to the VTGate server that was started in `101_initial_cluster.sh`:

```bash
~/my-vitess-example> mysql
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 2
Server version: 5.7.9-Vitess (Ubuntu)

Copyright (c) 2000, 2019, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> show tables;
+-------------------+
| Tables_in_vt_main |
+-------------------+
| customer          |
| customer_lookup   |
+-------------------+
2 rows in set (0.01 sec)
```

## Insert some data into the cluster
```bash
~/my-vitess-example> mysql < insert_customers.sql
```

## Examine the data we just inserted
```text
mysql> use main/-40;
Database changed

mysql> select * from customer;
+----+-----------------+-------------+---------------+
| id | fullname        | nationalid  | country       |
+----+-----------------+-------------+---------------+
|  1 | Philip Roth     | 123-456-789 | United States |
|  2 | Gary Shteyngart | 234-567-891 | United States |
|  3 | Margaret Atwood | 345-678-912 | Canada        |
|  4 | Alice Munro     | 456-789-123 | Canada        |
+----+-----------------+-------------+---------------+
4 rows in set (0.01 sec)

mysql> select id,hex(keyspace_id) from customer_lookup;
+----+--------------------+
| id | hex(keyspace_id)   |
+----+--------------------+
|  1 | 01166B40B44ABA4BD6 |
|  2 | 0106E7EA22CE92708F |
|  3 | 024EB190C9A2FA169C |
|  4 | 02D2FD8867D50D2DFE |
+----+--------------------+
4 rows in set (0.00 sec)
```
You can see that only data from US and Canada exists in this shard.
Repeat this for the other shards (40-80, 80-c0 and c0-) and see that each shard contains 4 rows in customer table and the 4 corresponding rows in the lookup table.

You can now teardown your example:

```bash
./201_teardown.sh
rm -rf vtdataroot
```
