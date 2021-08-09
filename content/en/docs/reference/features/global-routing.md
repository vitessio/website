---
title: Global Routing
weight: 23
---

# Global Table Routing
Vitess has an implicit feature of routing the queries to appropriate keyspace based on the table specified in the `from` list.
This works only for unique table names provided in the [VSchema](https://vitess.io/docs/concepts/vschema/).

This feature only works when no default keyspace is set on the connection.

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

`ks` and `customer` are sharded keyspace and `commerce` is unsharded keyspace.

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

Without any default keyspace we can route to unique table like `corder`, `product` and `player` but cannot route to `customer`

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

With default keyspace set to `customer` we can only query tables in `commerce` i.e `customer` and `corder`.
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

With default keyspace set, the queries can be routed to other keyspace by specifying the table qualifier.
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
