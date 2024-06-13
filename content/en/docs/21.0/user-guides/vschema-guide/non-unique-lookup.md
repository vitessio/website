---
title: Non-Unique Lookup Vindexes
weight: 9
---

The `oname` column in `corder` can contain duplicate values. There may be a need in the application to frequently search by this column:

```sql
select * from corder where oname='gift'
```

To prevent this query from resulting in a full scatter, we will need to create a lookup vindex for it. But this time, it will need to be non-unique. However, the fact that duplicates are allowed leads to a complication with the lookup table approach. Let us look at the insert query:

```sql
insert into corder(customer_id, product_id, oname) values (1,1,'gift'),(1,2,'gift'),(2,1,'work'),(3,2,'personal'),(4,1,'personal');
```

We see that `customer_id 1` has two rows where the `oname` is `gift`. If we try to create entries for those two in a lookup table, they would be identical:

```text
+-----------+--------------+
| oname | hex(keyspace_id) |
+-----------+--------------+
| gift  | 166B40B44ABA4BD6 | (corder_id=1)
| gift  | 166B40B44ABA4BD6 | (corder_id=2)
+-----------+--------------+
```

To disambiguate this situation, non-unique lookup vindexes require you to add additional columns to the lookup table. They are typically the Primary Key of the main table. For the sake of demonstration, let us create this as a sharded table in the `customer` keyspace:

```sql
create table oname_keyspace_idx(oname varchar(128), corder_id bigint, keyspace_id varbinary(10), primary key(oname, corder_id));
```

Note that the primary key includes the `oname` column as well as the `corder_id` column.

Because `oname` is a text column, the recommended Primary Vindex for it would be `unicode_loose_md5`, which also requires a vindex instantiation:

“vindexes” section:

```json
    "unicode_loose_md5": {
      "type": "unicode_loose_md5"
    }
```

“tables” section:

```json
    "oname_keyspace_idx": {
      "column_vindexes": [{
        "column": "oname",
        "name": "unicode_loose_md5"
      }]
    }
```

The lookup vindex should reference these new columns as follows:

```json
    "oname_keyspace_idx": {
      "type": "consistent_lookup",
      "params": {
        "table": "customer.oname_keyspace_idx",
        "from": "oname,corder_id",
        "to": "keyspace_id"
      },
      "owner": "corder"
    }
```

{{< info >}}
This Vindex could also be seen as a multi-column Unique Lookup Vindex: For a given pair of `oname,corder_id` as input, the result can only yield a single `keyspace_id`. However, the `consistent_lookup` vindex functionality only supports resolution using the first column `oname`. In the future, we may add the ability to use both columns as input if they are present in the `where` clause. This may result in the merger of `consistent_lookup` with a multi-column version of `consistent_lookup_unique` that can also perform non-unique lookups on a subset of the inputs.
{{< /info >}}

Finally, we tie the associated columns in `corder` to the vindex:

```json
    "corder": {
      "column_vindexes": [{
        "column": "customer_id",
        "name": "hash"
      }, {
        "column": "corder_id",
        "name": "corder_keyspace_idx"
      }, {
        "columns": ["oname", "corder_id"],
        "name": "oname_keyspace_idx"
      }],
      "auto_increment": {
        "column": "corder_id",
        "sequence": "product.corder_seq"
      }
    }
```

Alternate VSchema DDL:

```sql
alter vschema on customer.oname_keyspace_idx add vindex unicode_loose_md5(oname) using unicode_loose_md5;
alter vschema on customer.corder add vindex oname_keyspace_idx(oname,corder_id) using consistent_lookup with owner=`corder`, table=`customer.oname_keyspace_idx`, from=`oname,corder_id`, to=`keyspace_id`;
```

We can now look at the effects of this change:

```text
mysql> insert into corder(customer_id, product_id, oname) values (1,1,'gift'),(1,2,'gift'),(2,1,'work'),(3,2,'personal'),(4,1,'personal');
Query OK, 5 rows affected (0.03 sec)

mysql> use `customer:-80`;
Database changed
mysql> select oname, corder_id, hex(keyspace_id) from oname_keyspace_idx;
+-------+-----------+------------------+
| oname | corder_id | hex(keyspace_id) |
+-------+-----------+------------------+
| gift  |         1 | 166B40B44ABA4BD6 |
| gift  |         2 | 166B40B44ABA4BD6 |
| work  |         3 | 06E7EA22CE92708F |
+-------+-----------+------------------+
3 rows in set (0.00 sec)

mysql> use `customer:80-`;
Database changed
mysql> select oname, corder_id, hex(keyspace_id) from oname_keyspace_idx;
+----------+-----------+------------------+
| oname    | corder_id | hex(keyspace_id) |
+----------+-----------+------------------+
| personal |         4 | 4EB190C9A2FA169C |
| personal |         5 | D2FD8867D50D2DFE |
+----------+-----------+------------------+
2 rows in set (0.00 sec)
```

We can see that the lookup table is following its own sharding scheme and distributing its rows according to the value of the `oname` column.

Deleting one of the `corder` rows results in the corresponding lookup row being deleted:

```text
mysql> delete from corder where corder_id=1;
Query OK, 1 row affected (0.00 sec)

mysql> select oname, corder_id, hex(keyspace_id) from oname_keyspace_idx where oname='gift';
+-------+-----------+------------------+
| oname | corder_id | hex(keyspace_id) |
+-------+-----------+------------------+
| gift  |         2 | 166B40B44ABA4BD6 |
+-------+-----------+------------------+
1 row in set (0.00 sec)
```

{{< info >}}
You would typically have to create a MySQL non-unique index on `oname` for queries to work efficiently. While these vindexes and indexes improve read performance, the trade-off is that they also increase storage requirements and amplify writes when inserting rows.
{{< /info >}}

### Backfill

To Backfill the vindex on an existing table refer to [Backfill Vindexes](../backfill-vindexes)
