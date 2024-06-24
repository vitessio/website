---
title: Sharded Keyspace
weight: 5
---

A sharded keyspace allows you to split a large database into smaller parts by distributing the rows of each table into different shards. In Vitess, each shard is assigned a `keyrange`. Every row has a keyspace id, and this value decides the shard in which the row lives. For key-value stores, the keyspace id is dictated by the value of the key, also known as the sharding key. In Vitess, this is known as the Primary Vindex. But it differs from a sharding key in the following ways:

* Any column or a set of columns can be chosen to be the primary vindex.
* The Vindex also decides the sharding function that controls how the data is distributed.
* The sharding function is pluggable, allowing for user-defined sharding schemes.

Vitess provides many predefined vindex types. The most popular ones are:

* `xxhash`: for numbers
* `unicode_loose_xxhash`: for text columns
* `xxhash`: for binary columns

In our example, we are going to designate `customer` as a sharded keyspace, and create a `customer` table in it. The schema for the table is as follows:

```sql
create table customer(customer_id bigint, uname varchar(128), primary key(customer_id));
```

In the VSchema, we need to designate which column should be the Primary Vindex, and choose the vindex type for it. The `customer_id` column seems to be the natural choice. Since it is a number, we will choose `hash` as the vindex type:

```json
{
  "sharded": true,
  "vindexes": {
    "hash": {
      "type": "hash"
    }
  },
  "tables": {
    "customer": {
      "column_vindexes": [{
        "column": "customer_id",
        "name": "hash"
      }]
    }
  }
}
```

In the above section, we are instantiating a vindex named `hash` from the vindex type `hash`. Such instantiations are listed in the `vindexes` section of the vschema. The tables are expected to refer to the instantiated name. There are a few reasons why this additional level of indirection is necessary:

* As we will see later, vindexes can be instantiated with different input parameters. In such cases, they have to have their own distinct names.
* Vindexes can be shared by tables, and this has special meaning. We will cover this in a later section.
* Vindexes can also be referenced as if they were tables and can be used to compute the keyspace id for a given input.

The `column_vindexes` section is a list. This is because a table can have multiple vindexes. If so, the first vindex in the list must be the Primary Vindex. More information about vindexes can be found in the [Vindex Reference](../../../reference/features/vindexes).

Alternate VSchema DDL:

```sql
alter vschema on customer.customer add vindex hash(customer_id) using hash;
```

The DDL creates the `hash` vindex under the `vindexes` section, the `customer` table under the `tables` section, and associates the `customer_id` column to `hash`. For sharded keyspaces, the only way to create a table is using the above construct. This is because a primary vindex is mandatory for sharded tables.

{{< info >}}
Every sharded table must have a Primary Vindex. A Primary Vindex must be instantiated from a vindex type that is Unique. `xxhash`, `unicode_loose_xxhash` and `binary_md5` are unique vindex types.
{{< /info >}}

The demo brings up the `customer` table as two shards: `-80` and `80-`. For a `hash` vindex, input values of 1, 2 and 3 fall in the `-80` range, and 4 falls in the `80-` range. Restarting the demo with the updated configs should allow you to perform the following:

```text
mysql> insert into customer(customer_id,uname) values(1,'alice'),(4,'dan');
Query OK, 2 rows affected (0.00 sec)

mysql> use `customer:-80`;
Database changed
mysql> select * from customer;
+-------------+-------+
| customer_id | uname |
+-------------+-------+
|           1 | alice |
+-------------+-------+
1 row in set (0.00 sec)

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

You will notice that we used a special shard targeting construct: `use customer:-80`. Vitess allows you to use this hidden database name to bypass its routing logic and directly send queries to a specific shard. Using this construct, we are able to verify that the rows went to different shards.

At the time of insert, the Primary Vindex is used to compute and assign a keyspace id to each row. This keyspace id gets used to decide where the row will be stored. Although a keyspace id is not explicitly stored anywhere, it must be seen as an unchanging property of that row; as if there was an invisible column for it.

Consequently, you cannot make changes to a row that can cause the keyspace id to change. Such a change will be supported in the future through a shard move operation. Trying to change the value of a Primary Vindex results in an error:

```text
mysql> update customer set customer_id=2 where customer_id=1;
ERROR 1235 (HY000): vtgate: http://sougou-lap1:12345/: unsupported: You can't update primary vindex columns. Invalid update on vindex: hash
```

A Primary Vindex can also be used to find rows if referenced in a where clause:

```text
mysql> select * from customer where customer_id=1;
+-------------+-------+
| customer_id | uname |
+-------------+-------+
|           1 | alice |
+-------------+-------+
1 row in set (0.00 sec)
```

If you run the above query in the demo app, the panel on the bottom right will show that the query was executed only on one shard.

On the other hand, the query below will get sent to all shards because there is no where clause:

```text
mysql> select * from customer;
+-------------+-------+
| customer_id | uname |
+-------------+-------+
|           4 | dan   |
|           1 | alice |
+-------------+-------+
2 rows in set (0.01 sec)
```

{{< info >}}
There is no implicit or predictable ordering for rows that are gathered from multiple shards. If a specific order is required, the query must include an `order by` clause.
{{< /info >}}
