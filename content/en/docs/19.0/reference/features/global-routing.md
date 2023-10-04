---
title: Global Routing
weight: 23
---

# Global Table Routing
Vitess has an implicit feature of routing the queries to the appropriate keyspace based on the table specified in the `from` list.
This differs from the standard mysql, in mysql unqualified tables will fail if the correct database is not set on the connection.

This feature works only for unique table names provided in the [VSchema](../../../vschema/), and only when no default keyspace is set on the connection. One exception to the uniqueness rule is [Reference Tables](../../../user-guides/vschema-guide/advanced-vschema/#reference-tables) that explicitly specify a `source` table.

Example:
```sql
mysql> show keyspaces;
+----------+
| Database |
+----------+
| ks       |
| customer |
| commerce |
+----------+
3 rows in set (0.00 sec)
```

`ks` and `customer` are sharded keyspaces and `commerce` is an unsharded keyspace.

Tables present in each of the keyspace.

```sql
mysql> show tables from ks;
+--------------+
| Tables_in_ks |
+--------------+
| customer     |
| matches      |
| player       |
+--------------+
3 rows in set (0.00 sec)

mysql> show tables from customer;
+--------------------+
| Tables_in_customer |
+--------------------+
| corder             |
| customer           |
+--------------------+
2 rows in set (0.00 sec)

mysql> show tables from commerce;
+--------------------+
| Tables_in_commerce |
+--------------------+
| customer_seq       |
| order_seq          |
| product            |
+--------------------+
3 rows in set (0.00 sec)
```

Without a default keyspace we can route to unique tables like `corder`, `product` and `player` but cannot route to `customer`

```sql
mysql> show columns from corder;
+-------------+----------------+------+-----+---------+-------+
| Field       | Type           | Null | Key | Default | Extra |
+-------------+----------------+------+-----+---------+-------+
| order_id    | bigint         | NO   | PRI | NULL    |       |
| customer_id | bigint         | YES  |     | NULL    |       |
| sku         | varbinary(128) | YES  |     | NULL    |       |
| price       | bigint         | YES  |     | NULL    |       |
+-------------+----------------+------+-----+---------+-------+
4 rows in set (0.01 sec)

mysql> show columns from product;
+-------------+----------------+------+-----+---------+-------+
| Field       | Type           | Null | Key | Default | Extra |
+-------------+----------------+------+-----+---------+-------+
| sku         | varbinary(128) | NO   | PRI | NULL    |       |
| description | varbinary(128) | YES  |     | NULL    |       |
| price       | bigint         | YES  |     | NULL    |       |
+-------------+----------------+------+-----+---------+-------+
3 rows in set (0.00 sec)

mysql> show columns from player;
+-----------+-------------+------+-----+---------+-------+
| Field     | Type        | Null | Key | Default | Extra |
+-----------+-------------+------+-----+---------+-------+
| player_id | bigint      | NO   | PRI | NULL    |       |
| name      | varchar(50) | NO   |     | NULL    |       |
+-----------+-------------+------+-----+---------+-------+
2 rows in set (0.00 sec)

mysql> show columns from customer;
ERROR 1105 (HY000): ambiguous table reference: customer
```

With the default keyspace set to `customer` we can only query tables in `commerce` i.e `customer` and `corder`.
```sql
mysql> use customer
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
mysql> show columns from customer;
+-------------+----------------+------+-----+---------+-------+
| Field       | Type           | Null | Key | Default | Extra |
+-------------+----------------+------+-----+---------+-------+
| customer_id | bigint         | NO   | PRI | NULL    |       |
| email       | varbinary(128) | YES  |     | NULL    |       |
+-------------+----------------+------+-----+---------+-------+
2 rows in set (0.01 sec)

mysql> show columns from corder;
+-------------+----------------+------+-----+---------+-------+
| Field       | Type           | Null | Key | Default | Extra |
+-------------+----------------+------+-----+---------+-------+
| order_id    | bigint         | NO   | PRI | NULL    |       |
| customer_id | bigint         | YES  |     | NULL    |       |
| sku         | varbinary(128) | YES  |     | NULL    |       |
| price       | bigint         | YES  |     | NULL    |       |
+-------------+----------------+------+-----+---------+-------+
4 rows in set (0.00 sec)

mysql> show columns from product;
ERROR 1105 (HY000): table product not found
```

With a default keyspace set, the queries can be routed to other keyspaces by specifying the table qualifier.
```sql
mysql> use customer
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
mysql> show columns from ks.player;
+-----------+-------------+------+-----+---------+-------+
| Field     | Type        | Null | Key | Default | Extra |
+-----------+-------------+------+-----+---------+-------+
| player_id | bigint      | NO   | PRI | NULL    |       |
| name      | varchar(50) | NO   |     | NULL    |       |
+-----------+-------------+------+-----+---------+-------+
2 rows in set (0.00 sec)

mysql> show columns from commerce.product;
+-------------+----------------+------+-----+---------+-------+
| Field       | Type           | Null | Key | Default | Extra |
+-------------+----------------+------+-----+---------+-------+
| sku         | varbinary(128) | NO   | PRI | NULL    |       |
| description | varbinary(128) | YES  |     | NULL    |       |
| price       | bigint         | YES  |     | NULL    |       |
+-------------+----------------+------+-----+---------+-------+
3 rows in set (0.00 sec)
```
