---
title: Vindexes
aliases: ['/docs/schema-management/consistent-lookup/']
---











## A Vindex maps column values to keyspace IDs

A Vindex provides a way to map a column value to a `keyspace ID`. This mapping can be used to identify the location of a row. A variety of vindexes are available to choose from with different trade-offs, and you can choose one that best suits your needs.

The Sharding Key is a concept that was introduced by NoSQL datastores. It is based on the fact that there is only one access path to the data, which is the Key. However, relational databases are more versatile about the data and their relationships. So, sharding a database by only designating a sharding key is often insufficient.

If one were to draw an analogy, the indexes in a database would be the equivalent of the key in a NoSQL datastore, except that databases allow you to define multiple indexes per table, and there are many types of indexes. Extending this analogy to a sharded database results in different types of cross-shard indexes. In Vitess, these are called Vindexes.



## Advantages

Vindexes offer many flexibilities:

* A table can have multiple Vindexes.
* Vindexes could be NonUnique, which allows a column value to yield multiple keyspace IDs.
* They could be a simple function or be based on a lookup table.
* They could be shared across multiple tables.
* Custom Vindexes can be plugged in, and Vitess will still know how to reshard using such Vindexes.

### The Primary Vindex

The Primary Vindex is analogous to a database primary key. Every sharded table must have one defined. A Primary Vindex must be unique: given an input value, it must produce a single keyspace ID. This unique mapping will be used at the time of insert to decide the target shard for a row. Conceptually, this is also equivalent to the NoSQL Sharding Key, and we often refer to the Primary Vindex as the Sharding Key.

Uniqueness for a Primary Vindex does not mean that the column has to be a primary key or unique in the MySQL schema. You can have multiple rows that map to the same keyspace ID. The Vindex uniqueness constraint is only used to make sure that all rows for a keyspace ID live in the same shard.

However, there is a subtle difference: NoSQL datastores let you choose the Sharding Key, but the Sharding Scheme is generally hardcoded in the engine. In Vitess, the choice of Vindex lets you control how a column value maps to a keyspace ID. In other words, a Primary Vindex in Vitess not only defines the Sharding Key, it also decides the Sharding Scheme.

Vindexes come in many varieties. Some of them can be used as Primary Vindex, and others have different purposes. The following sections will describe their properties.

### Secondary Vindexes

Secondary Vindexes are additional vindexes you can define against other columns of a table offering you optimizations for WHERE clauses that do not use the Primary Vindex. Secondary Vindexes return a single or a limited set of `keyspace IDs` which will allow VTGate to only target shards where the relevant data is present. In the absence of a Secondary Vindex, VTGate would have to send the query to all shards.

Secondary Vindexes are also commonly known as cross-shard indexes. It is important to note that Secondary Vindexes are only for making routing decisions. The underlying database shards will most likely need traditional indexes on those same columns.

### Unique and NonUnique Vindex

A Unique Vindex is one that yields at most one keyspace ID for a given input. Knowing that a Vindex is Unique is useful because VTGate can push down some complex queries into VTTablet if it knows that the scope of that query cannot exceed a shard. Uniqueness is also a prerequisite for a Vindex to be used as Primary Vindex.

A NonUnique Vindex is analogous to a database non-unique index. It is a secondary index for searching by an alternate WHERE clause. An input value could yield multiple keyspace IDs, and rows could be matched from multiple shards. For example, if a table has a `name` column that allows duplicates, you can define a cross-shard NonUnique Vindex for it, and this will let you efficiently search for users that match a certain `name`.

### Functional and Lookup Vindex

A Functional Vindex is one where the column value to keyspace ID mapping is pre-established, typically through an algorithmic function. In contrast, a Lookup Vindex is one that gives you the ability to create an association between a value and a keyspace ID, and recall it later when needed.

Typically, the Primary Vindex is Functional. In some cases, it is the identity function where the input value yields itself as the keyspace id. However, one could also choose other algorithms like hashing or mod functions.

Vitess supports the concept of a lookup vindex, or what is also commonly known as a cross-shard index. It's implemented as a mysql table that maps a column value to the keyspace id. This is usually needed when someone needs to efficiently find a row using a where clause that does not contain the primary vindex. At the time of insert, the computed keyspace ID of the row is stored in the lookup table against the column value.
                                                              ### Lookup vindex types

This lookup table can be sharded or unsharded. No matter which option one chooses, the lookup row is most likely not going to be in the same shard as the keyspace id it points to.
                                                              #### Shared Vindexes

Vitess allows the transparent population of these rows by assigning an owner table, which is the main table that requires this lookup. When a row is inserted into the main table, the lookup row for it is created in the lookup table. The lookup row is also deleted on a delete of the main row. These essentially result in distributed transactions, which require 2PC to guarantee atomicity.
                                                              There are currently two vindex types for consistent lookup:

Consistent lookup vindexes use an alternate approach that makes use of careful locking and transaction sequences to guarantee consistency without using 2PC. This gives you the best of both worlds, where you get a consistent cross-shard vindex without paying the price of 2PC.

Relational databases encourage normalization, which lets you split data into different tables to avoid duplication in the case of one-to-many relationships. In such cases, a key is shared between the two tables to indicate that the rows are related, aka `Foreign Key`.

* `consistent_lookup_unique`
* `consistent_lookup`

In a sharded environment, it is often beneficial to keep those rows in the same shard. If a Lookup Vindex was created on the foreign key column of each of those tables, you would find that the backing tables would actually be identical. In such cases, Vitess lets you share a single Lookup Vindex for multiple tables. Of these, one of them is designated as the owner, which is responsible for creating and deleting these associations. The other tables just reuse these associations.

An existing `lookup_unique` vindex can be trivially switched to a `consistent_lookup_unique` by changing the vindex type in the VSchema. This is because the data is compatible.    Caveat: If you delete a row from the owner table, Vitess will not perform cascading deletes. This is mainly for efficiency reasons; The application is likely capable of doing this more efficiently.

As for a `lookup`, you can change it to a `consistent_lookup` only if the from columns can uniquely identify the owner row. Without this, many potentially valid inserts would fail.Functional Vindexes can be also be shared. However, there is no concept of ownership because the column to keyspace ID mapping is pre-established.

### Lookup Vindex guidance

The guidance for implementing lookup vindexes has been to create a two-column table. The first column (from column) should match the type of the column of the main table that needs the vindex. The second column (to column) should be a `BINARY` or a `VARBINARY` large enough to accommodate the keyspace id.

This guidance remains the same for unique lookup vindexes.

For non-unique lookup vindexes, it's recommended that the lookup table consist of multiple columns: The first column continues to be the input for computing the keyspace ids. Beyond this, additional columns are needed to uniquely identify the owner row. This should typically be the primary key of the owner table. But it can be any other column that can be combined with the 'from column' to uniquely identify the owner row. The last column remains the keyspace id like before.

For example, if a user table had `(user_id, email)`, where `user_id` was the primary key and `email` needed a non-unique lookup vindex, the lookup table would have the following columns `(email, user_id, keyspace_id)`.

### Orthogonality

The previously described properties are mostly orthogonal. Combining them gives rise to the following valid categories:

 * **Functional Unique**: This is the most popular category because it is the one best suited to be a Primary Vindex.
 * **Functional NonUnique**: There are currently no use cases that need this category.
 * **Lookup Unique Owned**: This gets used for optimizing high QPS queries that do not use the Primary Vindex columns in their WHERE clause. There is a price to pay: You incur an extra write to the lookup table for insert and delete operations, and an extra lookup for read operations. However, it is worth it if you do not want these high QPS queries to be sent to all shards.
* **Lookup Unique Unowned**: This category is used as an optimization as described in the Shared Vindexes section.
* **Lookup NonUnique Owned**: This gets used for high QPS queries on columns that are non-unique.
* **Lookup NonUnique Unowned**: You would rarely have to use this category because it is unlikely that you will be using a column as foreign key that is not unique within a shard. But it is theoretically possible.

Of the above categories, `Functional Unique` and `Lookup Unique Unowned` Vindexes can be Primary. This is because those are the only ones that are unique and have the column to keyspace ID mapping pre-established. This is required because the Primary Vindex is responsible for assigning the keyspace ID for a row when it is created.

However, it is generally not recommended to use a Lookup vindex as Primary because it is too slow for resharding. If absolutely unavoidable, you can use a Lookup Vindex as Primary. In such cases, it is recommended that you add a `keyspace ID` column to such tables. While resharding, Vitess can use that column to efficiently compute the target shard. You can even configure Vitess to auto-populate that column on inserts. This is done using the reverse map feature explained below.

### How vindexes are used

#### Cost

Vindexes have costs. For routing a query, the Vindex with the lowest cost is chosen. The current costs are:

Vindex Type | Cost
----------- | ----
Indentity | 0
Functional | 1
Lookup Unique | 10
Lookup NonUnique | 20

#### Select

In the case of a simple select, Vitess scans the WHERE clause to match references to Vindex columns and chooses the best one to use. If there is no match and the query is simple without complex constructs like aggregates, etc, it is sent to all shards.

Vitess can handle more complex queries. For now, you can refer to the [design doc](https://github.com/vitessio/vitess/blob/master/doc/V3HighLevelDesign.md) on how it handles them.

#### Insert

* The Primary Vindex is used to generate a keyspace ID.
* The keyspace ID is validated against the rest of the Vindexes on the table. There must exist a mapping from the column value to the keyspace ID.
* If a column value was not provided for a Vindex and the Vindex is capable of reverse mapping a keyspace ID to an input value, that function is used to auto-fill the column. If there is no reverse map, it is an error.

#### Update

The WHERE clause is used to route the update. Updating the value of a Vindex column is supported, but with a restriction: the change in the column value should not result in the row being moved from one shard to another. A workaround is to perform a delete followed by insert, which works as expected.

#### Delete

If the table owns lookup vindexes, then the rows to be deleted are first read and the associated Vindex entries are deleted. Following this, the query is routed according to the WHERE clause.

### Predefined Vindexes

Vitess provides the following predefined Vindexes:

Name | Type | Description | Primary | Reversible | Cost
---- | ---- | ----------- | ------- | ---------- | ----
binary | Functional Unique | Identity | Yes | Yes | 0
binary\_md5 | Functional Unique | md5 hash | Yes | No | 1
hash | Functional Unique | 3DES null-key hash | Yes | Yes | 1
lookup | Lookup NonUnique | Lookup table non-unique values | No | Yes | 20
lookup\_unique | Lookup Unique | Lookup table unique values | If unowned | Yes | 10
consistent\_lookup | Lookup NonUnique | Lookup table non-unique values | No | No | 20
consistent\_lookup\_unique | Lookup Unique | Lookup table unique values | unowned | No | 10
numeric | Functional Unique | Identity | Yes | Yes | 0
numeric\_static\_map | Functional Unique | A JSON file that maps input values to keyspace IDs | Yes | No | 1
unicode\_loose\_md5 | Functional Unique | Case-insensitive (UCA level 1) md5 hash | Yes | No | 1
reverse\_bits | Functional Unique | Bit Reversal | Yes | Yes | 1

[Consistent lookup vindexes](../vindexes) are a new category of vindexes that are meant to replace the existing lookup vindexes. For the time being, they have a different name to allow for users to switch back and forth.

Custom vindexes can also be plugged in as needed.

