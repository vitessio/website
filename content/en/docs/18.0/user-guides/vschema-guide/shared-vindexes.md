---
title: Shared Vindexes and Foreign Keys
weight: 7
---

Let us now look at creating the `corder` table that will contain orders placed by the customers. It will be beneficial to group the rows of the orders in the same shard as that of the customer that placed the orders. Doing things this way will allow for simpler join queries between `customer` and `corder`. There will also be transactional benefits: any transaction that also updates the customer row along with an order will be a single shard transaction.

To make this happen in Vitess, all you have to do is specify that `corder.customer_id` uses the `hash` vindex, which is the same one used by `customer.customer_id`.

This is one situation where a Primary Vindex conceptually differs from a traditional database Primary Key. Whereas a Primary Key makes a row unique, a Vitess Primary Vindex only yields a Unique value. But multiple rows with the same Primary Vindex value can exist.

In other words, the Primary Vindex column need not be the primary key, or unique within MySQL. This is convenient for the `corder` table because we want customers to place multiple orders. In this case, all orders placed by a customer will have the same `customer_id`. The Primary Vindex for those will yield the same keyspace id as that of the customer. Therefore, all the rows for that customer’s orders will end up in the same shard along with the customer row.

Since `corder` rows will need to have their own unique identifier, we also need to create a separate sequence for it in the product keyspace.

```sql
create table corder_seq(id bigint, next_id bigint, cache bigint, primary key(id)) comment 'vitess_sequence';
insert into corder_seq(id, next_id, cache) values(0, 1, 3);
```

VSchema:

```json
    "corder_seq": { "type": "sequence" }
```

We create the `corder` table as follows:

```sql
create table corder(corder_id bigint, customer_id bigint, product_id bigint, oname varchar(128), primary key(corder_id));
```

VSchema:
```json
    "corder": {
      "column_vindexes": [{
          "column": "customer_id",
          "name": "hash"
        }],
      "auto_increment": {
        "column": "corder_id",
        "sequence": "product.corder_seq"
      }
    }
```

Alternate VSchema DDL:

```sql
alter vschema on customer.corder add vindex hash(customer_id);
alter vschema add sequence product.corder_seq;
alter vschema on customer.corder add auto_increment corder_id using product.corder_seq;
```

Inserting into `corder` yields the following results:

```text
mysql> insert into corder(customer_id, product_id, oname) values (1,1,'gift'),(1,2,'gift'),(2,1,'work'),(3,2,'personal'),(4,1,'personal');
Query OK, 5 rows affected (0.03 sec)

mysql> use `customer:-80`;
Database changed
mysql> select * from corder;
+-----------+-------------+------------+----------+
| corder_id | customer_id | product_id | oname    |
+-----------+-------------+------------+----------+
|         1 |           1 |          1 | gift     |
|         2 |           1 |          2 | gift     |
|         3 |           2 |          1 | work     |
|         4 |           3 |          2 | personal |
+-----------+-------------+------------+----------+
4 rows in set (0.00 sec)

mysql> use `customer:80-`;
Database changed
mysql> select * from corder;
+-----------+-------------+------------+----------+
| corder_id | customer_id | product_id | oname    |
+-----------+-------------+------------+----------+
|         5 |           4 |          1 | personal |
+-----------+-------------+------------+----------+
1 row in set (0.00 sec)
```

As expected, orders are created in the same shard as their customer. Selecting orders by their customer id goes to a single shard:

```text
mysql> select * from corder where customer_id=1;
+-----------+-------------+------------+-------+
| corder_id | customer_id | product_id | oname |
+-----------+-------------+------------+-------+
|         1 |           1 |          1 | gift  |
|         2 |           1 |          2 | gift  |
+-----------+-------------+------------+-------+
2 rows in set (0.00 sec)
```

Joining `corder` with `customer` also goes to a single shard. This is also referred to as a local join:

```text
mysql> select c.uname, o.oname, o.product_id from customer c join corder o on c.customer_id = o.customer_id where c.customer_id=1;
+-------+-------+------------+
| uname | oname | product_id |
+-------+-------+------------+
| alice | gift  |          1 |
| alice | gift  |          2 |
+-------+-------+------------+
2 rows in set (0.01 sec)
```

Performing the join without a `customer_id` constraint still results in a local join, but the query is scattered across all shards:

```text
mysql> select c.uname, o.oname, o.product_id from customer c join corder o on c.customer_id = o.customer_id;
+---------+----------+------------+
| uname   | oname    | product_id |
+---------+----------+------------+
| alice   | gift     |          1 |
| alice   | gift     |          2 |
| bob     | work     |          1 |
| charlie | personal |          2 |
| dan     | personal |          1 |
+---------+----------+------------+
5 rows in set (0.00 sec)
```

However, adding a join with `product` results in a cross-shard join for the product part ot the query:

```text
mysql> select c.uname, o.oname, p.pname from customer c join corder o on c.customer_id = o.customer_id join product p on o.product_id = p.product_id;
+---------+----------+----------+
| uname   | oname    | pname    |
+---------+----------+----------+
| alice   | gift     | monitor  |
| alice   | gift     | keyboard |
| bob     | work     | monitor  |
| charlie | personal | keyboard |
| dan     | personal | monitor  |
+---------+----------+----------+
5 rows in set (0.01 sec)
```

Although the underlying work performed by Vitess is not visible here, you can see it in the bottom right panel if using the demo app. Alternatively, you can also stream this information with the following command:

```text
curl localhost:12345/debug/querylog
[verbose output not shown]
```

### Foreign Keys

More generically stated: If a table has a foreign key into another table, then Vitess can ensure that the related rows live in the same shard by making them share a common Unique Vindex.

In cases where you choose to group rows based on their foreign key relationships, you have the option to enforce those constraints within each shard at the MySQL level. You can also configure cascade deletes as needed. However, overuse of foreign key constraints is generally discouraged in MySQL.

Foreign key constraints across shards or keyspaces are not supported in Vitess. For example, you cannot specify a foreign key between `corder.product_id` and `product.product_id`.

A more detailed analysis of foreign keys in Vitess can be found on the [foreign keys](../foreign-keys) page.

### Many-to-Many relationships

In the case where a table has relationships with multiple other tables, you can only choose one of those relationships for shard grouping. All other relationships will end up being cross-shard, and will incur cross-shard penalties.

If a table has strong relationships with multiple other tables, and if performance becomes a challenge choosing either way, you can explore the [VReplication Materialization](../../../reference/vreplication/materialize) feature that allows you to materialize a table both ways.

### Enforcing Uniqueness

To enforce global uniqueness for a row in a sharded table, you have to have:

* A Unique Vindex on the column
* A Unique constraint at the MySQL level

A Primary Vindex coupled with a Primary Key constraint makes a row globally unique.

A Unique Vindex can also be specified for a non-unique column. In such cases, it is likely that you will be using that column in a where clause, and will require a secondary non-unique index on it at the MySQL level.
