---
title: Unique Lookup Vindexes
weight: 8
---

Certain application features may require you to point-select orders by their id with a query like this:

```sql
select * from corder where corder_id=1;
```

However, issuing this query to Vitess will cause it to scatter this query across all shards because there is no way to know which shard contains that order id. This would be inefficient if the QPS of this query or the number of shards is too high.

Vitess supports the concept of lookup vindexes, also known as cross-shard indexes. You can instruct Vitess to create and manage a lookup vindex for the `corder_id` column. Such a vindex needs to maintain a mapping from `corder_id` to the `keyspace_id` of the row, which will be stored in a lookup table.

This lookup table can be created in any keyspace, and it may or may not be sharded. In this particular case, we are going to create the table in the unsharded product keyspace even though the lookup vindex itself is going to be in the `customer` keyspace:

```sql
create table corder_keyspace_idx(corder_id bigint, keyspace_id varbinary(10), primary key(corder_id));
```

The primary key is `corder_id`. The unique constraint on `corder_id` makes the Lookup Vindex unique: for a given `corder_id` as input, at most one `keyspace_id` can be produced. It is not necessary to name the column as `corder_id`, but it is less confusing to do so.

Since the table is not sharded, we have a trivial VSchema addition:

```json
    "corder_keyspace_idx": {}
```

We can now instantiate the Lookup Vindex in the VSchema of the `customer` keyspace:

```json
    "corder_keyspace_idx": {
      "type": "consistent_lookup_unique",
      "params": {
        "table": "product.corder_keyspace_idx",
        "from": "corder_id",
        "to": "keyspace_id"
      },
      "owner": "corder"
    }
```

* The vindex is given a distinctive name `corder_keyspace_idx` because of its specific input parameters.
* The vindex type is `consistent_lookup_unique`. We expect this lookup vindex to yield at most one keyspace id for a given input. The `consistent` qualifier is explained below.
* The `params` section of a Vindex is a set of key-value strings. Each vindex expects a different set of parameters depending on the implementation. A lookup vindex requires the following three parameters:
  * `table` should be the name of the lookup table. It is recommended that it is fully qualified.
  * The `from` and `to` fields must reference the column names of the lookup table.
  * An optional fourth parameter:
  
    * `batch_lookup`:  Set this to `"true"` if you want lookups for key values in the lookup vindex table to be batched (i.e. all values that match to a shard of the lookup backing table will be done in a single query). This can be important if you have queries with multiple point lookup values in the `WHERE` clause (e.g. using `IN`).  This is not enabled by default, since it only supports binary equality, i.e. does not take collation into account. You should therefore only use it with lookup vindexes where the `from` key is binary or binary equivalent (e.g. integer or a character field where you are sure that collation matching is not required). Without this option, lookups of multiple values in the shards backing the lookup table will be performed one-by-one, and can have a significant latency overhead if you have a large number of values to lookup per query, relative to your number of shards.
* The `owner` field indicates that `corder` is responsible for populating the lookup table and keeping it up-to-date. This means that an insert into `corder` will result in a corresponding lookup row being inserted in the lookup table, etc. Lookup vindexes can also be shared, but they can have only one owner each. We will later see an example about how to share lookup vindexes.

{{< info >}}
Since `corder_keyspace_idx` and `corder` are in different keyspaces, any change that affects the lookup column results in a distributed transaction between the `customer` shard and the `product` keyspace. Usually, a two-phase commit (2PC) protocol would need to be used for the distributed transaction. However, the `consistent` lookup vindex utilizes a special algorithm that orders the commits in such a way that a commit failure resulting in partial commits does not result in inconsistent data. This avoids the extra overheads associated with 2PC.
{{< /info >}}

Finally, we must associate `customer.corder_id` with the lookup vindex:

```json
      "column_vindexes": [{
          "column": "customer_id",
          "name": "hash"
        }, {
          "column": "corder_id",
          "name": "corder_keyspace_idx"
        }]
```

Note that `corder_id` comes after `customer_id` implying that `customer_id` is the Primary Vindex for this table.

Alternate VSchema DDL:

```sql
alter vschema add table product.corder_keyspace_idx;
alter vschema on customer.corder add vindex corder_keyspace_idx(corder_id) using consistent_lookup_unique with owner=`corder`, table=`product.corder_keyspace_idx`, from=`corder_id`, to=`keyspace_id`;
```

{{< info >}}
An owned lookup vindex (even if unique) cannot be a Primary Vindex because it creates an association against a keyspace id after one has been assigned to the row. The job of computing the keyspace id must therefore be performed by a different unique vindex.
{{< /info >}}

Bringing up the demo application again, you can now see the lookup table being automatically populated when rows are inserted in `corder`:

```text
mysql> insert into corder(customer_id, product_id, oname) values (1,1,'gift'),(1,2,'gift'),(2,1,'work'),(3,2,'personal'),(4,1,'personal');
Query OK, 5 rows affected (0.00 sec)

mysql> select corder_id, hex(keyspace_id) from corder_keyspace_idx;
+-----------+------------------+
| corder_id | hex(keyspace_id) |
+-----------+------------------+
|         1 | 166B40B44ABA4BD6 |
|         2 | 166B40B44ABA4BD6 |
|         3 | 06E7EA22CE92708F |
|         4 | 4EB190C9A2FA169C |
|         5 | D2FD8867D50D2DFE |
+-----------+------------------+
5 rows in set (0.01 sec)
```

And then, issuing a query like `select * from corder where corder_id=1` results in two single-shard round-trips instead of a full scatter.

### Reversible Vindexes

Looking at the rows in `corder_keyspace_idx` reveals a few things. We get to now see actual keyspace id values that were previously invisible. We can also notice that two different inputs `1` and `2` map to the same keyspace id `166B40B44ABA4BD6`. In other words, a unique vindex does not necessarily guarantee that two different values yield different keyspace ids. In fact, this is derived from the fact that there are two order rows for customer id `1`.

Vindexes that do have a one-to-one correspondence between the input value and keyspace id , like `hash`, are known as reversible vindexes: Given a keyspace id, the input value can be back-computed. This property will be used in a later example.

### Backfill

To Backfill the vindex on an existing table refer to [Backfill Vindexes](../backfill-vindexes)
