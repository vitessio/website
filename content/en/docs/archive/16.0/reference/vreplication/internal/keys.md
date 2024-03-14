---
title: Role of Table Keys in VReplication
description: Uses and requirements for primary and unique keys in source and target tables in VReplication Workflows
weight: 3
aliases: ['/docs/design-docs/vreplication/keys/']
---

# The Use of Unique Keys

A VReplication stream copies data from a table on a source tablet to a table on a target tablet. In some cases, the two
tablets may be the same one, but the stream is oblivious to such nuance. VReplication needs to be able to copy existing
rows from the source table to the target table, as well as identify binary log events from the source tablet and
apply them to the target table. To that effect, VReplication needs to be able to uniquely identify rows, so that it
can apply a specific `UPDATE` on the correct row, or so that it knows that all rows _up to a given row_ have been copied.

Thus each row needs to be uniquely identifiable. In the relational model, this is trivially done by utilizing a `UNIQUE KEY`s,
preferably `PRIMARY KEY`s. A `UNIQUE KEY` made up of non-`NULL`able columns is considered a `PRIMARY KEY` equivalent (PKE)
for this purpose.

Typically, both the source and the target tables have a similar structure and the same keys.

In fact, in the most common use case, both tables will have the same `PRIMARY KEY` covering the same set of columns in
the same order. This is the default assumption and expectation by VReplication. But this doesn't have to be the case,
and it is possible to have different keys on the source and the target table.

## Which Keys Are Eligible?

Any `UNIQUE KEY` that is non-`NULL`able potentially qualifies. A `NULL`able `UNIQUE KEY` is a key that covers one or
more `NULL`able columns. It doesn't matter if column values do or do not actually contain `NULL`s. If a column is `NULL`
able, then a `UNIQUE KEY` that includes that column is not eligible.

`PRIMARY KEY`s are by definition always non-`NULL`able. A `PRIMARY KEY` (PK) is typically the best choice. It gives best
iteration/read performance on InnoDB tables, as those are clustered by PK (index organized tables).

`PRIMARY KEY` aside, `VReplication` prioritizes keys that utilize e.g. integers rather than characters, and more generally
prioritizes smaller data types over larger data types.

However, not all eligible `UNIQUE KEY`s, or even `PRIMARY KEY`s are usable for all VReplication streams, as described
below.

## Comparable Rows

VReplication needs to be able to determine, given a row in the source table, which row it maps to in the target table.

In the case both tables share the same `PRIMARY KEY`, the answer is trivial: given a row from the source table, take the
PK column values (say the table has `PRIMARY KEY(col1, col2)`), and compare with/apply to the target table via
`... WHERE col1=<val1> AND col2=<val2>`.

However, other scenarios are also valid. Consider an OnlineDDL operation that modifies the `PRIMARY KEY` as
follows: `DROP PRIMARY KEY, ADD PRIMARY KEY(col1)`. On the source table, a row is identified by `col1, col2`. On the
target table, a row is only identifiable by `col1`. This scenario still feels comfortable: all we need to do when we
apply e.g. an `UPDATE` statement on the target table is to drop `col2` from the statement: `... WHERE col1=<val1>`.

_Note that it is the user's responsibility to make sure the data will comply with the new constraints. If not,
VReplication will fail the operation._

But consider the opposite case, there's a `PRIMARY KEY(col1)` and an OnlineDDL operation turns it into
`PRIMARY KEY(col1, col2)`. Now we need to apply changes using `... WHERE col1=<val1> AND col2=<val2>`. But `col2` is
not part of the source `PRIMARY KEY`.

An extreme case is when the keys on the source table and the target table do not share _any columns_ between them. Say
the source table has `PRIMARY KEY(col1)` and the target table has `PRIMARY KEY(col2)` and with no other potential keys.
We still need to identify which row in the source table maps to which row in the target table. VReplication still supports
this scenario.

Yet another complication is when columns are renamed along the way. Consider an
`ALTER TABLE CHANGE COLUMN col2 col_two INT UNSIGNED ...` statement. A row on the source table is identified by
`col1, col2`, but on the target table it is identified by `col1, col_two`.

Let's now discuss what the exact requirements are for unique keys, and then discuss the implementation.

## Requirements

To be able to create a VReplication stream between the source table and target table:

- The source table must have a non-`NULL`able `UNIQUE/PRIMARY` key (PK or PKE) whose columns all exist in the target
  table (possibly under different names)
- The target table must have a non-`NULL`able `UNIQUE/PRIMARY` key whose columns all exist in the source table (possibly
  under different names)
- Except in the trivial case where both tables share the same `PRIMARY KEY` (of the same columns in the same order),
  VReplication can automatically determine which keys to utilize (more on this later)

To clarify, it is **OK** if:

- Keys in the source table and the target table go by different names
- Chosen key in the source table and chosen key in the target table do not share any columns
- Chosen key in the source table and chosen key in the target table share some or all columns
- Chosen key in the source table and chosen key in the target table share some or all columns, but in a different order
- There are keys in the source table that cover columns not present in the target table
- There are keys in the target table that cover columns not present in the source table
- There are `NULL`able columns in the source and the target table
- There are `NULL`able keys in the source and the target table

All it takes is _one_ viable key that can be used to uniquely identify rows in the source table, and one such viable key
in the target table to allow VReplication to work.

### Examples of Valid Cases

#### Source Table and Target Table Are the Same

```sql
CREATE TABLE `entry` (
  `id` int NOT NULL,
  `uuid` varchar(40) DEFAULT NULL,
  `ts` timestamp NULL DEFAULT NULL,
  `customer_id` int NOT NULL,
  PRIMARY KEY (`id`)
)
```

</br>

The above is a trivial scenario.

#### Source Table and Target table Share the Same PRIMARY KEY

```sql
CREATE TABLE `source` (
  `id` int NOT NULL,
  `uuid` varchar(40) DEFAULT NULL,
  `ts` timestamp NULL DEFAULT NULL,
  `customer_id` int,
  PRIMARY KEY (`id`),
  KEY ts_idx(`ts`)
)

CREATE TABLE `target` (
  `id` int NOT NULL,
  `uuid` varchar(40) DEFAULT NULL,
  `ts` timestamp NULL DEFAULT NULL,
  `customer_id` int NOT NULL,
  PRIMARY KEY (`id`)
)
```

</br>

The differences in structure are interesting but irrelevant to VReplication's ability to copy the data.

#### Subset PRIMARY KEY

```sql
CREATE TABLE `source` (
  `id` int NOT NULL,
  `uuid` varchar(40) DEFAULT NULL,
  `ts` timestamp NULL DEFAULT NULL,
  `customer_id` int NOT NULL,
  PRIMARY KEY (`id`, `customer_id`)
)

CREATE TABLE `target` (
  `id` int NOT NULL,
  `uuid` varchar(40) DEFAULT NULL,
  `ts` timestamp NULL DEFAULT NULL,
  `customer_id` int NOT NULL,
  PRIMARY KEY (`id`)
)
```

</br>

#### Superset PRIMARY KEY

```sql
CREATE TABLE `source` (
  `id` int NOT NULL,
  `uuid` varchar(40) DEFAULT NULL,
  `ts` timestamp NULL DEFAULT NULL,
  `customer_id` int NOT NULL,
  PRIMARY KEY (`id`)
)

CREATE TABLE `target` (
  `id` int NOT NULL,
  `uuid` varchar(40) DEFAULT NULL,
  `ts` timestamp NULL DEFAULT NULL,
  `customer_id` int NOT NULL,
  PRIMARY KEY (`id`, `customer_id`)
)
```

</br>

#### Different PRIMARY KEYs

```sql
CREATE TABLE `source` (
  `id` int NOT NULL,
  `uuid` varchar(40) NOT NULL,
  `ts` timestamp NULL DEFAULT NULL,
  `customer_id` int NOT NULL,
  PRIMARY KEY (`id`)
)

CREATE TABLE `target` (
  `id` int NOT NULL,
  `uuid` varchar(40) NOT NULL,
  `ts` timestamp NULL DEFAULT NULL,
  `customer_id` int NOT NULL,
  PRIMARY KEY (`uuid`)
)
```

</br>

No columns are shared between the `PRIMARY KEY`s in the above. However:

- `id`, covered by `source`'s PK, is found in `target`
- `uuid`, covered by `target`'s PK, is found in `source`

#### Mixed Keys

```sql
CREATE TABLE `source` (
  `uuid` varchar(40) NOT NULL,
  `ts` timestamp NULL DEFAULT NULL,
  `customer_id` int NOT NULL,
  PRIMARY KEY (`uuid`)
)

CREATE TABLE `target` (
  `id` int NOT NULL,
  `uuid` varchar(40) NOT NULL,
  `ts` timestamp NULL DEFAULT NULL,
  `customer_id` int NOT NULL,
  PRIMARY KEY (`id`)
  UNIQUE KEY uuid_idx(`uuid`)
)
```

</br>

The only eligible solution in the above is:

- Use `source`'s `PRIMARY KEY` (the column `uuid` is found in `target`)
- Use `target`'s `uuid_idx` key (again using column `uuid` which is found in `source`).

`target`'s `PRIMARY KEY` is not valid because the covered column `id` does not exist in `source`.

Incidentally, in the above, the chosen keys differ by name, but share the same columns (`uuid`).

### Examples of Invalid Cases

#### NULLable Columns

```sql
CREATE TABLE `source` (
  `id` int NOT NULL,
  `uuid` varchar(40) DEFAULT NULL,
  `ts` timestamp NULL DEFAULT NULL,
  `customer_id` int NOT NULL,
  PRIMARY KEY (`id`)
)

CREATE TABLE `target` (
  `id` int NOT NULL,
  `uuid` varchar(40) DEFAULT NULL,
  `ts` timestamp NULL DEFAULT NULL,
  `customer_id` int NOT NULL,
  UNIQUE KEY (`uuid`)
)
```

</br>

The only `UNIQUE KEY` on `target` is `NULL`able, hence _not_ eligible.

#### Missing Columns

```sql
CREATE TABLE `source` (
  `uuid` varchar(40) NOT NULL,
  `ts` timestamp NULL DEFAULT NULL,
  `customer_id` int NOT NULL,
  PRIMARY KEY (`uuid`)
)

CREATE TABLE `target` (
  `id` int NOT NULL,
  `uuid` varchar(40) NOT NULL,
  `ts` timestamp NULL DEFAULT NULL,
  `customer_id` int NOT NULL,
  PRIMARY KEY (`id`)
)
```

</br>

`target` only has one possible key, the `PRIMARY KEY`, covering `id`. But `id` is not found in `source`.

## Configuring The Stream

If both source and target table share the same `PRIMARY KEY` (covering the same columns in the same order) then there's
nothing to be done. VReplication will pick `PRIMARY KEY` on both ends by default.

In all other cases, VReplication must determine which keys are involved and which ones to use.

### Example 1

Let's begin again as a trivial example, both tables have same `PRIMARY KEY`s:

```sql
CREATE TABLE `corder` (
  `order_id` bigint NOT NULL AUTO_INCREMENT,
  `customer_id` bigint DEFAULT NULL,
  `sku` varbinary(128) DEFAULT NULL,
  `price` bigint DEFAULT NULL,
  PRIMARY KEY (`order_id`)
)
```

</br>

And even though we don't _have to_, here's how we could manually configure the VReplication workflow definition
(prettified for readability):

```proto
keyspace:"commerce" shard:"0" filter:{
  rules:{
    match:"corder" 
    filter:"select `order_id` as `order_id`, `customer_id` as `customer_id`, `sku` as `sku`, `price` as `price` from `corder`" 
    source_unique_key_columns:"order_id" 
    target_unique_key_columns:"order_id" 
    source_unique_key_target_columns:"order_id"
  }
}
```

</br>

In the above:

- `source_unique_key_columns` is the (comma delimited) list of columns covered by the chosen key on source table
- `target_unique_key_columns` is the (comma delimited) list of columns covered by the chosen key on target table
- `source_unique_key_target_columns` is the (comma delimited) list of column names in target table, which map
  to `source_unique_key_columns`. This mapping is necessary because columns may change their names.

### Example 2

Again both the source and the target table share same `PRIMARY KEY`, but this time it covers two columns:

```sql
CREATE TABLE `shipment` (
  `order_id` int NOT NULL,
  `customer_id` int NOT NULL,
  `ts` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`order_id`,`customer_id`)
)
```

```proto
keyspace:"commerce" shard:"0" filter:{
  rules:{
    match:"shipment" 
    filter:"select `order_id` as `order_id`, `customer_id` as `customer_id`, `ts` as `ts` from `shipment`" 
    source_unique_key_columns:"order_id,customer_id" 
    target_unique_key_columns:"order_id,customer_id" 
    source_unique_key_target_columns:"order_id,customer_id"
  }
}
```

</br>

Not much changed from the previous example, just note how we comma separate `"order_id,customer_id"`.

### Example 3

Continuing the previous example, we now rename a column the target table:

```sql
CREATE TABLE `shipment` (
  `order_id` int NOT NULL,
  `cust_id` int NOT NULL,
  `ts` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`order_id`,`cust_id`)
)
```

```proto
keyspace:"commerce" shard:"0" filter:{
  rules:{
    match:"shipment"
    filter:"select `order_id` as `order_id`, `customer_id` as `cust_id`, `ts` as `ts` from `shipment`" 
    source_unique_key_columns:"order_id,customer_id" 
    target_unique_key_columns:"order_id,cust_id" 
    source_unique_key_target_columns:"order_id,cust_id"
  }
}
```

</br>

Note:

- `source_unique_key_columns` indicates the names of columns on the source table
- `target_unique_key_columns` indicates the names of columns on the target table
- `source_unique_key_target_columns` repeats `source_unique_key_columns`, but replaces `customer_id` with `cust_id`

## Automation

OnlineDDL has a mechanism to automatically analyze the differences between source and target tables, evaluate eligible
keys, choose the best keys on source and target tables, and populate the filter's
`source_unique_key_columns`, `target_unique_key_columns`, and `source_unique_key_target_columns` fields. Indeed,
OnlineDDL operations are most susceptible to differences in keys. The user can also supply their chosen values as an
override — using those fields in the workflow definition — in the rare case it's needed.

VReplication more broadly will automatically use the most efficient `PRIMARY KEY` equivalent or PKE (non-`NULL`able unique
key) when there's no defined `PRIMARY KEY` on the table.

## Implementation

At a high level, this is how VReplication is able to work with different keys/columns between the source and target.

Originally, VReplication was only designed to work with identical `PRIMARY KEY`s. If not specified, VReplication assumed
the source table's `PRIMARY KEY` _can be used_ on the target table, and that the target table's `PRIMARY KEY` is applied
to the source table. If not, it would error out and the workflow would fail.

With the introduction of mechanisms to automatically determine the optimal key to use and of
the `source_unique_key_columns`, `target_unique_key_columns`, and `source_unique_key_target_columns` fields for more
fine-grained control, VReplication changes its behavior as needed.

#### Notes About The Code

Much of the code uses "PK" terminology. With the introduction of _any_ unique key utilization the "PK" terminology
becomes incorrect. However, to avoid mass rewrites we kept this terminology, and wherever VReplication discusses
a `PRIMARY KEY` or pkColumns, etc., it may refer to a non-PK Unique Key (PKE).

### Streamer

Streaming is done using the `source_unique_key_columns` value if present. When present, `rowstreamer` trusts the
information in `source_unique_key_columns` to be correct. It does not validate that there is indeed a valid unique key
covering those columns, it only validates that the columns exist. When a `source_unique_key_columns` value is not
present, `rowstreamer` uses the `PRIMARY KEY` columns if they exist, otherwise it will determine the best
available `PRIMARY KEY` equivalent if one exists, and lastly if none of these are available it will use all of the
columns in the table.

The streamer iterates the table by the chosen index's column order. It then tracks its progress in `lastPk` as if this
was indeed a true `PRIMARY KEY`.

### Copier

VCopier receives rows from the `rowstreamer` in the chosen index's column order. It complies with the streamer's ordering.
When tracking progress in `_vt.copy_state` it uses `lastPk` values from the streamer, which means it uses the same index
columns as the streamer in that order.

### Player

VPlayer adheres to both `source_unique_key_columns` and `target_unique_key_columns` when present. If not present, again
it attempts to use the `PRIMARY KEY` columns if they exist, otherwise it will determine the best available `PRIMARY KEY`
equivalent if one exists, and lastly if none of these are available it will use all of the columns in the table.

- `TablePlan`'s `isOutsidePKRange()` function needs to compare values according to `rowstreamer`'s ordering, therefore
  uses the chosen index columns in order.
- `tablePlanBuilder`'s `generateWhere()` function uses the target table's `target_unique_key_columns`, and then also
  appends any supplemental columns from `source_unique_key_target_columns` not included in `target_unique_key_columns`
  when they are present. If not present, again it attempts to use the `PRIMARY KEY` columns if they exist, otherwise it
  will determine the best available `PRIMARY KEY` equivalent if one exists, and lastly if none of these are available it
  will use all of the columns in the table.
