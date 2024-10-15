---
title: Unsharded Keyspace
weight: 4
---

We are going to start with configuring the `product` table in the unsharded keyspace `product`. The schema file should be as follows:

```sql
create table product(product_id bigint auto_increment, pname varchar(128), primary key(product_id));
```

`product_id` is the primary key for product, and it is also configured to use MySQL’s `auto_increment` feature that allows you to automatically generate unique values for it.

We also need to create a VSchema for the `product` keyspace and specify that `product` is a table in the keyspace:

```json
{
  "sharded": false,
  "tables": {
    "product": {}
  }
}
```

The json states that the keyspace is not sharded. The product table is specified in the “tables” section of the json. This is because there are other sections that we will introduce later.

For unsharded keyspaces, no additional metadata is needed for regular tables. So, their entry is empty.

Alternate VSchema DDL:

```sql
alter vschema add table product.product;
```

{{< info >}}
If `product` is the only keyspace in the cluster, a vschema is unnecessary. Vitess treats single keyspace clusters as a special case and optimistically forwards all queries to that keyspace even if there is no table metadata present in the vschema. But it is a best practice to provide a full vschema to avoid future complications.
{{< /info >}}

Bringing up the cluster will allow you to access the `product` table. You can now insert rows into the table:

```text
$ mysql -h 127.0.0.1 -P 12348
[snip]
mysql> insert into product(pname) values ('monitor'), ('keyboard');
Query OK, 2 rows affected (0.00 sec)

mysql> select * from product;
+------------+----------+
| product_id | pname    |
+------------+----------+
|          1 | monitor  |
|          2 | keyboard |
+------------+----------+
2 rows in set (0.00 sec)
```
The insert does not specify values for `product_id`, because we are relying on MySQL’s `auto_increment` feature to populate it.

You will notice that we did not connect to the `product` database or issue a `use` statement to select it. This is the ‘unspecified’ mode supported by Vitess. As long as a table name can be uniquely identified from the vschemas, Vitess will automatically direct the query to the correct keyspace.

You can also connect or specify keyspaces as if they were MySQL databases. The following constructs are valid:

```text
mysql> select * from product.product;
+------------+----------+
| product_id | pname    |
+------------+----------+
|          1 | monitor  |
|          2 | keyboard |
+------------+----------+
2 rows in set (0.00 sec)

mysql> use product;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
mysql> select * from product;
+------------+----------+
| product_id | pname    |
+------------+----------+
|          1 | monitor  |
|          2 | keyboard |
+------------+----------+
2 rows in set (0.01 sec)
```
