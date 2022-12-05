---
title: Global Routing
weight: 23
---

# Global Table Routing

Vitess has an implicit feature of routing the queries to the appropriate keyspace based on the table specified in the `from` list. This differs from the standard mysql, in mysql unqualified tables will fail if the correct database is not set on the connection.

## Requirements

Vitess will globally route queries for tables when:

 * They are specified in the VSchema,
 * And either:
   * They have a globally unique name,
   * Or they are [Reference Tables](../../../user-guides/vschema-guide/advanced-vschema/#reference-tables) with a `source`,
 * And either:
   * The connection does not use a default keyspace,
   * Or the connection uses a Global Keyspace,
   * Or the table is name is qualified with a Global Keyspace.

## Global Keyspaces

Global keyspaces are a feature that enables global routing to be requested by using a global keyspace name in the connection, or by qualifying a query by a global keyspace name.

To enable this feature, set one or more [VTGate `--global-keyspace [global_ks]` flags](../../programs/vtgate/#options).

## Examples

Given keyspaces `ks`, `customer` and `commerce`:

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

`ks` and `customer` are sharded keyspaces, and `commerce` is an unsharded keyspace.

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

<br/>

#### Without a default keyspace

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

<br/>

#### With a default keyspace

With the default keyspace set to `customer` we can only query keyspace-unqualified tables in `commerce` i.e `customer` and `corder`.

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

<br/>

#### Queries qualified by a keyspace

With a default keyspace set, queries can be routed to other keyspaces by qualifying the table name with the keyspace name.

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

<br/>

#### With a default global keyspace

Global routing may be requested by using a global keyspace on the connection. Vitess will behave the same way as if no default keyspace was set.

```sql
mysql> use global_ks;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
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
```

<br/>

#### Queries qualified by a global keyspace

With a default keyspace set, global routing may be requested by qualifying a table with a global keyspace.

```sql
mysql> use customer
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
mysql> show columns from global_ks.product;
+-------------+----------------+------+-----+---------+-------+
| Field       | Type           | Null | Key | Default | Extra |
+-------------+----------------+------+-----+---------+-------+
| sku         | varbinary(128) | NO   | PRI | NULL    |       |
| description | varbinary(128) | YES  |     | NULL    |       |
| price       | bigint         | YES  |     | NULL    |       |
+-------------+----------------+------+-----+---------+-------+
3 rows in set (0.00 sec)
```
