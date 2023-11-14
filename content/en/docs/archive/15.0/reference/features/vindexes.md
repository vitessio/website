---
title: Vindexes
weight: 10
aliases: ['/docs/schema-management/consistent-lookup/','/docs/reference/vindexes/']
---

## A Vindex maps column values to keyspace IDs

A Vindex provides a way to map a column value to a `keyspace ID`. Since each shard in Vitess covers a range of `keyspace ID` values, this mapping can be used to identify which shard contains a row. A variety of vindexes are available to choose from with different trade-offs, and you can choose one that best suits your needs.

The Sharding Key is a concept that was introduced by NoSQL datastores. It is based on the fact that, in NoSQL databases, there is only one access path to the data, which is the Key. However, relational databases are more versatile with respect to the data stored and their relationships. So, sharding a database by only designating a single sharding key is often insufficient.

If one were to draw an analogy, the indexes in a database would be the equivalent of the key in a NoSQL datastore, except that databases allow multiple indexes per table, and there are many types of indexes. Extending this analogy to a sharded database results in different types of cross-shard indexes. In Vitess, these are called Vindexes.


## Advantages

The advantages of Vindexes stem from their flexibility:

* A table can have multiple Vindexes.
* Vindexes can be NonUnique, which allows a column value to yield multiple keyspace IDs.
* Vindexes can be a simple function or be based on a lookup table.
* Vindexes can be shared across multiple tables.
* Custom Vindexes can be created and used, and Vitess will still know how to reshard using such Vindexes.


### The Primary Vindex

The Primary Vindex for a table is analogous to a database primary key. Every sharded table must have one defined. A Primary Vindex must be unique: given an input value, it must produce a single keyspace ID. At the time of an insert to the table, the unique mapping produced by the Primary Vindex determines the target shard for the inserted row. Conceptually, this is equivalent to a NoSQL Sharding Key, and we often informally refer to the Primary Vindex as the Sharding Key.

However, there is a subtle difference:  NoSQL datastores allow a choice of the Sharding Key, but the Sharding Strategy or Function is generally hardcoded in the engine. In Vitess, the choice of Vindex allows control of how a column value maps to a keyspace ID. In other words, a Primary Vindex in Vitess not only defines the Sharding Key, but also decides the Sharding Strategy.

Uniqueness for a Primary Vindex does not mean that the column has to be a primary key or unique key in the MySQL schema for the underlying shard. You can have multiple rows that map to the same keyspace ID. The Vindex uniqueness constraint only ensures that all rows for a keyspace ID end up in the same shard.

Vindexes come in many varieties. Some of them can be used as Primary Vindex, and others have different purposes. We will describe their properties in the [Predefined Vindexes](#predefined-vindexes) section.


### Secondary Vindexes

Secondary Vindexes are additional vindexes against other columns of a table offering optimizations for WHERE clauses that do not use the Primary Vindex. Secondary Vindexes return a single or a limited set of `keyspace IDs` which will allow VTGate to only target shards where the relevant data is present. In the absence of a Secondary Vindex, VTGate would have to send the query to all shards (called a scatter query).

It is important to note that Secondary Vindexes are only used for making routing decisions. The underlying database shards will most likely need traditional indexes on those same columns, to allow efficient retrieval from the table on the underlying MySQL instances.


### Unique and NonUnique Vindex

A Unique Vindex is a vindex that yields at most one keyspace ID for a given input. Knowing that a Vindex is Unique is useful because VTGate can push down certain complex queries into VTTablet if it knows that the scope of that query can be limited to a single shard. Uniqueness is also a prerequisite for a Vindex to be used as Primary Vindex.

A NonUnique Vindex is analogous to a database non-unique index. It is a secondary index for searching by an alternate WHERE clause. An input value could yield multiple keyspace IDs, and rows could be matched from multiple shards. For example, if a table has a `name` column that allows duplicates, you can define a cross-shard NonUnique Vindex for it, and this will allow an efficient search for users that match a certain `name`.


### Functional and Lookup Vindex

A **Functional Vindex** is a vindex where the column value to keyspace ID mapping is pre-established, typically through an algorithmic function. In contrast, a **Lookup Vindex** is a vindex that provides the ability to create an association between a value and a keyspace ID, and recall it later when needed. Lookup Vindexes are sometimes also informally referred to as cross-shard indexes.

Typically, the Primary Vindex for a table is Functional. In some cases, it is the identity function where the input value yields itself as the keyspace id. However, other algorithms like a hashing function can also be used.

A Lookup Vindex is implemented as a MySQL lookup table that maps a column value to the keyspace id. This is usually needed when database user needs to efficiently find a row using a WHERE clause that does not contain the Primary Vindex. At the time of insert, the computed keyspace ID of the row is stored in the lookup table against the column value.


### Lookup Vindex types

The lookup table that implements a Lookup Vindex can be sharded or unsharded.  Note that the lookup row is most likely not going to be in the same shard as the keyspace id it points to.

Vitess allows for the transparent population of these lookup table rows by assigning an owner table, which is the main table that requires this lookup. When a row is inserted into this owner table, the lookup row for it is created in the lookup table. The lookup row is also deleted upon a delete of the corresponding row in the owner table. These essentially result in distributed transactions, which traditionally require 2PC to guarantee atomicity.

Consistent lookup vindexes use an alternate approach that makes use of careful locking and transaction sequences to guarantee consistency without using 2PC. This gives the best of both worlds, with the benefit of a consistent cross-shard vindex without paying the price of 2PC. To read more about what makes a consistent lookup vindex different from a standard lookup vindex read our [consistent lookup vindexes design documentation](https://github.com/vitessio/vitess/issues/4855).

There are currently two vindex types in Vitess for consistent lookup:

* `consistent_lookup_unique`
* `consistent_lookup`

#### Consistent Lookup usage

There are 3 sessions which VTGate can open when a consistent lookup is involved.

1. Pre session
2. Normal session
3. Post session

The pre and post session are used by lookup queries. The normal session is used by the original query that was sent from the client to VTGate.

If an insert query is received, insert on consistent lookup will happen through the pre session and the actual query insert will happen through the normal session. When a commit happens it happens on the pre session first and if it succeeds then the commit happens on the post session.

If an update or delete query is received, the post session is used to do the update or delete on consistent lookup and the normal session for the original query. When a commit happens it happens on the normal session first and if that succeeds then the commit is executed on the post session.

Anytime there is a consistent lookup involved in the query received, a lock will be taken so that is not available for other sessions to be modified.

In order to do that we have to select the right session at the beginning. For an insert query, the pre session is used to send `SELECT ...` for the update query.

For an update or delete query, the post session is used to send `SELECT ...` for the update query.

Due to this, a current limitation with consistent lookup is that it cannot support an insert followed by an update or delete in the same transaction for the same consistent lookup column value.

#### Shared Vindexes

Relational databases encourage normalization, which allows the splitting of data into different tables to avoid duplication in the case of one-to-many relationships. In such cases, a key is shared between the two tables to indicate that the rows are related, a.k.a. `Foreign Key`.

In a sharded environment, it is often beneficial to keep those rows in the same shard. If a Lookup Vindex was created on the foreign key column of each of those tables, the backing tables would actually be identical. In such cases, Vitess allows sharing a single Lookup Vindex for multiple tables. One of these tables is designated as the owner of the Lookup Vindex, and is responsible for creating and deleting these associations. The other tables just reuse these associations.

An existing `lookup_unique` vindex can be trivially switched to a `consistent_lookup_unique` by changing the vindex type in the VSchema. This is because the data is compatible. Caveat: If you delete a row from the owner table, Vitess will not perform cascading deletes. This is mainly for efficiency reasons;  the application is likely capable of doing this more efficiently.

As for a `lookup` vindex, it can be changed it to a `consistent_lookup` only if the `from` columns can uniquely identify the owner row. Without this, many potentially valid inserts would fail.

Functional Vindexes can be also be shared. However, there is no concept of ownership because the column to keyspace ID mapping is pre-established.

### Lookup Vindex guidance

The guidance for implementing lookup vindexes has been to create a two-column table. The first column (`from` column) should match the type of the column of the main table that needs the vindex. The second column (`to` column) should be a `BINARY` or a `VARBINARY` large enough to accommodate the keyspace id.

This guidance remains the same for unique lookup vindexes.

For non-unique lookup Vindexes, the lookup table should consist of multiple columns. The first column continues to be the input for computing the keyspace IDs. Beyond this, additional columns are needed to uniquely identify the owner row. This should typically be the primary key of the owner table. But it can be any other column that can be combined with the `from` column to uniquely identify the owner row. The last column remains the keyspace ID like before.

For example, if a user table had the columns `(user_id, email)`, where `user_id` was the primary key and `email` needed a non-unique lookup vindex, the lookup table would have the columns `(email, user_id, keyspace_id)`.


### Independence

The previously described properties are mostly independent of each other. Combining them gives rise to the following valid categories:

* **Functional Unique**: The most popular category because it is the one best suited to be a Primary Vindex.
* **Functional NonUnique**: There are currently no use cases that need this category.
* **Lookup Unique Owned**: Used for optimizing high QPS read queries that do not use the Primary Vindex columns in their WHERE clause. There is a price to pay: an extra write to the lookup table for insert and delete operations, and an extra lookup for read operations. However, it may be worth it to avoid high QPS read queries to be sent to all shards. The overheard of maintaining the lookup table is amortized as the number of shards grow.
* **Lookup Unique Unowned**: Can be used as an optimization as described in the Shared Vindexes section.
* **Lookup NonUnique Owned**: Used for high QPS queries on columns that are non-unique.
* **Lookup NonUnique Unowned**: You would rarely have to use this category because it is unlikely that you will be using a column as foreign key that is not unique within a shard. But it is theoretically possible.

Of the above categories, `Functional Unique` and `Lookup Unique Unowned` Vindexes can be a Primary Vindex. This is because those are the only ones that are unique and have the column to keyspace ID mapping pre-established. This is required because the Primary Vindex is responsible for assigning the keyspace ID for a row when it is created.

However, it is generally not recommended to use a Lookup Vindex as a Primary Vindex because it is too slow for resharding. If absolutely unavoidable, it is recommended to add a `keyspace ID` column to the tables that need this level of control of the row-to-shard mapping. While resharding, Vitess can use that column to efficiently compute the target shard. Vitess can also be configured to auto-populate that column on inserts. This is done using the reverse map feature explained [below](#insert).

### Defining Vindexes

Vindexes are defined in the [VSchema](../vschema/) inside the `Vindexes` section of every keyspace. The `column_vindexes` section of each table in that keyspace may refer to the Vindex by name. Here is an example:

``` json
    "name_keyspace_idx": {
      "type": "lookup",
      "params": {
        "table": "name_keyspace_idx",
        "from": "name",
        "to": "keyspace_id"
      },
      "owner": "user"
    }
```

In the above case, the name of the vindex is `name_keyspace_idx`. It is of type `lookup`, and it is owned by the `user` table.

Every Vindex has an optional `params` section that contains a map of string key-value pairs. The keys and values differ depending on the vindex type and are explained below. 

There is an optional fourth parameter: `batch_lookup`. To read more about how to use `batch_lookup` see our [Unique Lookup user guide](../../../user-guides/vschema-guide/unique-lookup/).

### How Vindexes are used

#### Cost

Vindexes have costs. For routing a query, the applicable Vindex with the lowest cost is chosen. The current general costs for the different Vindex Types are as follows:

Vindex Type | Cost
| ----------- | ---- |
| Identity | 0 |
| Functional | 1 |
| Lookup Unique | 10 |
| Lookup NonUnique | 20 |

#### Select

In the case of a simple select, Vitess scans the WHERE clause to match references to Vindex columns and chooses the best one to use. If there is no match and the query is simple without complex constructs like aggregates, etc., it is sent to all shards.

Vitess can handle more complex queries with the new Gen4 planner.

#### Insert

* The Primary Vindex is used to generate a keyspace ID.
* The keyspace ID is validated against the rest of the Vindexes on the table. There must exist a mapping from the column value(s) for these Secondary Vindexes to the keyspace ID.
* If a column value was not provided for a Vindex and the Vindex is capable of reverse mapping a keyspace ID to an input value, that function is used to auto-fill the column. If there is no reverse map, it is an error.

#### Update

The WHERE clause is used to route the update. Updating the value of a Vindex column is supported, but with a restriction: the change in the column value should not result in the row being moved from one shard to another. A workaround is to perform a delete followed by insert, which works as expected.

#### Delete

If the table owns lookup vindexes, then the rows to be deleted are first read and the associated Vindex entries are deleted. Following this, the query is routed according to the WHERE clause.

#### Ignore Nulls

There are situations where the from columns of a lookup vindex can be `NULL`. Such columns cannot be inserted in the lookup backing table due to the uniqueness constraints of a lookup. There are two ways to deal with a `NULL` value in the from column of a lookup vindex:

* Use a predefined vindex as the primary vindex of the backing table that supports the use of a `NULL` value. The table for [predefined vindexes](../vindexes/#predefined-vindexes) lists what types are and are not nullable.
* Enable the `ignore_nulls` option. If the input value of any of the columns is null, Vitess can skip the creation of the lookup row if `ignore_nulls` is enabled. 

{{< info >}}
Note: You can have `NULL` values for the primary vindex column, as long as that vindex allows it (e.g. xxhash). However, you cannot have `NULL` values for the lookup input column, unless you have enabled `ignore_nulls`.
{{< /info >}}

### Predefined Vindexes

Vitess provides the following predefined Vindexes:

Name | Type | Description                                                                                                                                                                             | Primary | Multi-column | Reversible | Nullable | Cost | Data types                                   |
---- | ---- |-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------| ------- | ------------ | ---------- | -------- | --- |----------------------------------------------|
binary | Functional Unique | Identity                                                                                                                                                                                | Yes | No | Yes | Yes | 0 | Any                                          |
binary\_md5 | Functional Unique | MD5 hash                                                                                                                                                                                | Yes | No | No | Yes | 1 | Any                                          |
consistent\_lookup | Lookup NonUnique | Lookup table non-unique values                                                                                                                                                          | No | Identify Row | No | Yes [only if](../vindexes/#ignore-nulls) | 20 | Any                                          |
consistent\_lookup\_unique | Lookup Unique | Lookup table unique values                                                                                                                                                              | If unowned | Identify Row | No | Yes [only if](../vindexes/#ignore-nulls) | 10 | Any                                          |
hash | Functional Unique | DES null-key hash                                                                                                                                                                       | Yes | No | Yes | No | 1 | 64 bit or smaller numeric or equivalent type |
lookup | Lookup NonUnique | Lookup table non-unique values                                                                                                                                                          | No | Identify Row | No | Yes [only if](../vindexes/#ignore-nulls) | 20 | Any                                          |
lookup\_unique | Lookup Unique | Lookup table unique values                                                                                                                                                              | If unowned | Identify Row | No | Yes [only if](../vindexes/#ignore-nulls) | 10 | Any                                          |
multicol | Functional Unique | Multi-column [subsharding](../../../user-guides/vschema-guide/subsharding-vindex/) hash for use in tenant based sharding or geo-partitioning or multiple column serving as sharding key | Yes | Yes | No | No | sum of cost of hashing function used for each column | Any                                          |
null | Functional Unique | Always map to keyspace ID 0                                                                                                                                                             | Yes | No | No | Yes | 100 | Any                                          |
numeric | Functional Unique | Identity                                                                                                                                                                                | Yes | No | Yes | No | 0 | 64 bit or smaller numeric or equivalent type |
numeric\_static\_map | Functional Unique | JSON file statically mapping input numeric values to keyspace IDs                                                                                                                       | Yes | No | No | No | 1 | 64 bit or smaller numeric or equivalent type |
region\_experimental | Functional Unique | Multi-column prefix-based hash for use in geo-partitioning                                                                                                                              | Yes | Yes | No | No | 1 | String and numeric type                      |
region\_json | Functional Unique | Multi-column prefix-based hash combined with a JSON map for key-to-region mapping, for use in geo-partitioning                                                                          | Yes | Yes | No | No | 1 | String and numeric type                      |
reverse\_bits | Functional Unique | Bit reversal                                                                                                                                                                            | Yes | No | Yes | No | 1 | 64 bit or smaller numeric or equivalent type |
unicode\_loose\_md5 | Functional Unique | Case-insensitive (UCA level 1) MD5 hash                                                                                                                                                 | Yes | No | No | Yes | 1 | String or binary types                       |
unicode\_loose\_xxhash | Functional Unique | Case-insensitive (UCA level 1) xxHash64 hash                                                                                                                                            | Yes | No | No | Yes | 1 | String or binary types                       |
xxhash | Functional Unique | xxHash64 hash                                                                                                                                                                           | Yes | No | No | Yes | 1 | Any                                          |

Consistent lookup vindexes, as described above, are a new category of Vindexes that are meant to replace the existing lookup Vindexes implementation. For the time being, they have a different name to allow for users to switch back and forth.

Under the Multi-column heading, an `Identify Row` comment indicates that the Vindex only uses the first column to map to the keyspace id(s). The rest of the columns are used to identify the owner row.

Lookup Vindexes support the following parameters:

* `table`: The backing table for the lookup vindex. It is recommended that the table name be qualified by its keyspace.
* `from`: The list of "from" columns. The first column is used for routing, and the rest of the columns are used for identifying the owner row.
* `to`: The name of the "to" keyspace\_id column.
* `autocommit` (false): if true, specific vindex entries are updated in their own autocommit transaction. This is useful if values never get remapped to different values. For example, if the input column comes from an auto-increment value. Note that the autocommit option does not affect `consistent_lookup` or `consistent_lookup_unique` vindexes, but is for use with `lookup` or `lookup_unique` vindexes..
* `write_only` (false): if true, the vindex is kept updated, but a lookup will return all shards if the key is not found. This mode is used while the vindex is being populated and backfilled.
* `ignore_nulls` (false): if true, null values in input columns do not create entries in the lookup table. Otherwise, a null input results in an error.

The `numeric_static_map` vindex requires a `json_path` parameter. The file must contain a json that maps input numeric values to keyspace ids.

The `region_experimental` vindex is an experimental vindex that uses the first one or two bytes of the input value as prefix for keyspace id. The rest of the bits are hashed. This allows you to group users of the same region within the same group of shards. The vindex requires a `region_bytes` parameter that specifies if the prefix is one or two bytes.

The `region_json` vindex requires an additional `region_map` file name that is used to compute the region from the country. The `region_bytes` is presumed to contain country codes.

Custom Vindexes can also be created as needed. At the moment there is no formal plugin system for custom Vindexes, but the interface is well-defined, and thus custom implementations including code performing arbitrary lookups in other systems can be accommodated.

\
\
There are also the following legacy (deprecated) Vindexes. **Do not use these**:

| Name | Type | Primary | Reversible | Cost |
| ---- | ---- | ------- | ---------- | ---- |
| lookup\_hash | Lookup NonUnique | No | No | 20 |
| lookup\_hash\_unique | Lookup Unique | If unowned | No | 10 |
| lookup\_unicodeloosemd5\_hash | Lookup NonUnique | No | No | 20 |
| lookup\_unicodeloosemd5\_hash\_unique | Lookup Unique | If unowned | No | 10 |

### Query Vindex functions

You can query Vindex functions to see the resulting `keyspace_id` it produces (the resulting hash is a 64-bit hexadecimal number) and thus which shard a particular row would be placed on within the keyspace. You would query the Vindex functions by referencing their name as defined in your VSchema, and using query predicates specifically on the fixed name `id` field (this is not related to your actual schema). The Vindex functions support both equality (`WHERE id = X`) and list (`WHERE id IN(...)`) lookups. Here's a full example using the `customer` keyspace:

First, a snippet of the VSchema:
``` shell
$ vtctlclient -server=localhost:15999 GetVSchema customer | jq '.vindexes'
{
  "binary_md5_vdx": {
    "type": "binary_md5"
  },
  "binary_vdx": {
    "type": "binary"
  },
  "hash_vdx": {
    "type": "hash"
  }
}
```

And example queries using them from a VTGate (the Vindex function exists as a meta table in the given keyspace):
``` sql
mysql> use customer;
Database changed

mysql> select * from hash_vdx where id in(1,29999,397)\G
*************************** 1. row ***************************
             id: 1
    keyspace_id: k@�J�K�
    range_start:
      range_end: �
hex_keyspace_id: 166b40b44aba4bd6
          shard: -80
*************************** 2. row ***************************
             id: 29999
    keyspace_id: ��>V�7M�
    range_start: �
      range_end:
hex_keyspace_id: fcd63e56d3374d88
          shard: 80-
*************************** 3. row ***************************
             id: 397
    keyspace_id: U��s���
    range_start:
      range_end: �
hex_keyspace_id: 5584fa738baaf516
          shard: -80
3 rows in set (0.00 sec)

mysql> select * from binary_md5_vdx where id = "heythere"\G
*************************** 1. row ***************************
             id: heythere
    keyspace_id: ��,
���e��u�I�
    range_start: �
      range_end:
hex_keyspace_id: d9e62c0ad204fe91658ecc758049e515
          shard: 80-
1 row in set (0.00 sec)

```
