---
title: Sequences
weight: 6
---

The sharded `customer` table we created did not have an auto-increment column. The Vitess Sequence feature can be used to emulate the same behavior as MySQL’s auto-increment. A Vitess sequence is a single row unsharded tablet that keeps track of ids issued so far. Additionally, a configurable number of values can be cached by vttablet to minimize round trips into MySQL.

We will create the sequence table in the unsharded `product` keyspace as follows:

```sql
create table customer_seq(id bigint, next_id bigint, cache bigint, primary key(id)) comment 'vitess_sequence';
insert into customer_seq(id, next_id, cache) values(0, 1, 3);
```

Note the special comment `vitess_sequence`. This instructs vttablet that this is a special table.

The table needs to be pre-populated with a single row where:

* `id` must always be 0
* `next_id` should be set to the next (starting) value of the sequence
* `cache` is the number of values to cache before updating the table for the next value. This value should be set to a fairly large number like 1000. We have set the value to `3` mainly to demonstrate how the feature works.

Since this is a special table, we have to inform the vschema by giving it a `sequence` type.

```
    "customer_seq": { "type": "sequence" }
```

Once setup this way, you can use the special `select next` syntax to generate values from this sequence:


```text
mysql> select next 2 values from customer_seq; 
+---------+
| nextval |
+---------+
|       1 |
+---------+
1 row in set (0.00 sec)

mysql> select next 1 values from customer_seq;
+---------+
| nextval |
+---------+
|       3 |
+---------+
1 row in set (0.00 sec)
```

The construct returns the first of the N values generated.

However, this is insufficient to emulate MySQL’s auto-increment behavior. To achieve this, we have to inform the VSchema that the `customer_id` column should use this sequence to generate values if no value is specified. This is done by adding the following section to the `customer` table:

```json
      "auto_increment": {
        "column": "customer_id",
        "sequence": "product.customer_seq"
      }
```

Alternate VSchema DDL:

```sql
alter vschema add sequence product.customer_seq;
alter vschema on customer.customer add auto_increment customer_id using product.customer_seq;
```

With this, you can insert into `customer` without specifying the `customer_id`:

```text
mysql> insert into customer(uname) values('alice'),('bob'),('charlie'),('dan'),('eve');
Query OK, 5 rows affected (0.03 sec)

mysql> use `customer:-80`;
Database changed
mysql> select * from customer;
+-------------+---------+
| customer_id | uname   |
+-------------+---------+
|           1 | alice   |
|           2 | bob     |
|           3 | charlie |
|           5 | eve     |
+-------------+---------+
4 rows in set (0.00 sec)

mysql> use `customer:80-`;
Database changed
mysql> select * from customer;
+-------------+-------+
| customer_id | uname |
+-------------+-------+
|           4 | dan   |
+-------------+-------+
1 row in set (0.00 sec)
```
