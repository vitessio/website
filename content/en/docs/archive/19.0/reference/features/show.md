---
title: SHOW extensions
weight: 9
aliases: []
---

In Vitess, `SHOW` has been extended with additional functionality.

### SHOW Statements

Vitess supports the following additional SHOW statements:

* `SHOW GLOBAL GTID_EXECUTED [FROM <keyspace>]` -- retrieves the global gtid_executed status variable from each shard in the keyspace either selected or provided in the query.
```shell
Example Output for customer keyspace:
+----------+-------------------------------------------+-------+
| db_name  | gtid_executed                             | shard |
+----------+-------------------------------------------+-------+
| customer | e9148eb0-a320-11eb-8026-98af65a6dc4a:1-43 | 80-   |
| customer | e0f64aca-a320-11eb-9be4-98af65a6dc4a:1-43 | -80   |
+----------+-------------------------------------------+-------+
```

* `SHOW KEYSPACES` -- A list of keyspaces available.
```shell
Example Output:
+----------+
| Database |
+----------+
| commerce |
| customer |
+----------+
```

* `SHOW VITESS_REPLICATION_STATUS [LIKE "<Keyspace/<Shard>"]` (**Experimental; 12.0+**) -- Shows the Replication (_not_ [VReplication](../../vreplication/vreplication/)) health for the Vitess deployment. It returns a row for each `REPLICA` and `RDONLY` tablet in the topology -- with support for filtering by Keyspace/Shard using a `LIKE` clause -- providing relevant health and status information, including the current [tablet throttler](../tablet-throttler/) status.
```shell
Example Output:
+----------+-------+------------+------------------+--------------+--------------------+-------------------------------------------------------------------------+----------------+-----------------------------------------+
| Keyspace | Shard | TabletType | Alias            | Hostname     | ReplicationSource  | ReplicationHealth                                                       | ReplicationLag | ThrottlerStatus                         |
+----------+-------+------------+------------------+--------------+--------------------+-------------------------------------------------------------------------+----------------+-----------------------------------------+
| commerce | 0     | REPLICA    | zone1-0000000101 | 52030e360852 | 52030e360852:17100 | {"EventStreamRunning":"Yes","EventApplierRunning":"Yes","LastError":""} | 0              | {"state":"OK","load":0.00,"message":""} |
| commerce | 0     | RDONLY     | zone1-0000000102 | 52030e360852 | 52030e360852:17100 | {"EventStreamRunning":"Yes","EventApplierRunning":"Yes","LastError":""} | 0              | {"state":"OK","load":0.00,"message":""} |
+----------+-------+------------+------------------+--------------+--------------------+-------------------------------------------------------------------------+----------------+-----------------------------------------+
```

* `SHOW VITESS_SHARDS` -- A list of shards that are available.
```shell
Example Output:
+--------------+
| Shards       |
+--------------+
| commerce/0   |
| customer/-80 |
| customer/80- |
+--------------+
```

* `SHOW VITESS_TABLETS` -- Information about the current Vitess tablets such as the keyspace, key ranges, tablet type, hostname, and status.
```shell
Example Output:
+-------+----------+-------+------------+---------+------------------+------------+----------------------+
| Cell  | Keyspace | Shard | TabletType | State   | Alias            | Hostname   | PrimaryTermStartTime |
+-------+----------+-------+------------+---------+------------------+------------+----------------------+
| zone1 | commerce | 0     | PRIMARY    | SERVING | zone1-0000000100 | <redacted> | 2021-04-22T04:10:29Z |
| zone1 | commerce | 0     | REPLICA    | SERVING | zone1-0000000101 | <redacted> |                      |
| zone1 | commerce | 0     | RDONLY     | SERVING | zone1-0000000102 | <redacted> |                      |
| zone1 | customer | -80   | PRIMARY    | SERVING | zone1-0000000300 | <redacted> | 2021-04-22T04:12:23Z |
| zone1 | customer | -80   | REPLICA    | SERVING | zone1-0000000301 | <redacted> |                      |
| zone1 | customer | -80   | RDONLY     | SERVING | zone1-0000000302 | <redacted> |                      |
| zone1 | customer | 80-   | PRIMARY    | SERVING | zone1-0000000400 | <redacted> | 2021-04-22T04:12:23Z |
| zone1 | customer | 80-   | REPLICA    | SERVING | zone1-0000000401 | <redacted> |                      |
| zone1 | customer | 80-   | RDONLY     | SERVING | zone1-0000000402 | <redacted> |                      |
+-------+----------+-------+------------+---------+------------------+------------+----------------------+
```

* `SHOW VSCHEMA KEYSPACES` -- Information about Vschema information for all the keyspaces including the foreign key mode, whether the keyspace is sharded, and if there is an error in the VSchema for the keyspace.
```shell
Example Output:
+----------+---------+-------------+---------+
| Keyspace | Sharded | Foreign Key | Comment |
+----------+---------+-------------+---------+
| ks       | true    | managed     |         |
| uks      | false   | managed     |         |
+----------+---------+-------------+---------+
```

* `SHOW VSCHEMA TABLES` -- A list of tables available in the current keyspace's vschema.
```shell
Example Output for customer keyspace:
+----------+
| Tables   |
+----------+
| corder   |
| customer |
| dual     |
+----------+
```

* `SHOW VSCHEMA VINDEXES` -- Information about the current keyspace's vindexes such as the keyspace, name, type, params, and owner. Optionally supports an "ON" clause with a table name.
```shell
Example Output:
+----------+------+------+--------+-------+
| Keyspace | Name | Type | Params | Owner |
+----------+------+------+--------+-------+
| customer | hash | hash |        |       |
+----------+------+------+--------+-------+
```

* `SHOW VITESS_THROTTLER STATUS` -- shows status for all tablet throttlers in current keyspace
```shell
Example Output:
+-------+---------+-----------+
| shard | enabled | threshold |
+-------+---------+-----------+
| -80   |       1 |       1.5 |
| 80-   |       1 |       1.5 |
+-------+---------+-----------+
```
