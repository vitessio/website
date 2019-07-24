---
title: Consistent Lookup Vindexes
weight: 3
---

As mentioned in the VSchema section, Vitess supports the concept of a lookup vindex, or what is also commonly known as a cross-shard index. It's implemented as a mysql table that maps a column value to the keyspace id. This is usually needed when someone needs to efficiently find a row using a where clause that does not contain the primary vindex.

This lookup table can be sharded or unsharded. No matter which option one chooses, the lookup row is most likely not going to be in the same shard as the keyspace id it points to.

Vitess allows the transparent population of these rows by assigning an owner table, which is the main table that requires this lookup. When a row is inserted into the main table, the lookup row for it is created in the lookup table. The lookup row is also deleted on a delete of the main row. These essentially result in distributed transactions, which require 2PC to guarantee atomicity.

Consistent lookup vindexes use an alternate approach that make use of careful locking and transaction sequences to guarantee consistent, without using 2PC. This gives you the best of both worlds, where you get a consistent cross-shard vindex without paying the price of 2PC.

## Modified guidance

The guidance for implementing lookup vindexes has been to create a two-column table. The first column (from column) should match the type of the column of the main table that needs the vindex. The second column (to column) should be a `binary` or a `varbinary` large enough to accommodate the keyspace id.

This guidance remains the same for unique lookup vindexes.

For non-unique lookup vindexes, it's recommended that the lookup table consist of multiple columns: The first column continues to be the input for computing the keyspace ids. Beyond this, additional columns are needed to uniquely identify the owner row. This should typically be the primary key of the owner table. But it can be any other column that can be combined with the 'from column' to uniquely identify the owner row. The last column remains the keyspace id like before.

For example, if a user table had `(user_id, email)`, where `user_id` was the primary key and `email` needed a non-unique lookup vindex, the lookup table would have the following columns `(email, user_id, keyspace_id)`.

## Lookup vindex types

There are currently two vindex types for consistent lookup:

* `consistent_lookup_unique`
* `consistent_lookup`

An existing `lookup_unique` vindex can be trivially switched to a `consistent_lookup_unique` by changing the vindex type in the VSchema. This is because the data is compatible.

As for a `lookup`, you can change it to a `consistent_lookup` only if the from columns can uniquely identify the owner row. Without this, many potentially valid inserts would fail.
