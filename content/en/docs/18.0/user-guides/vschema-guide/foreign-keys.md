---
title: Foreign Keys in Vitess
weight: 8
---

For running foreign keys in Vitess, the users have a few options. Let's explore each of them in detail.

### Vitess Unaware of Foreign Keys

Users can run Vitess such that it doesn't know about or care for the foreign key constraints existing on MySQL. To run Vitess in this mode, `foreignKeyMode` VSchema property has to be set to `FK_UNMANAGED` for the given keyspace. This is the default mode for Vitess as well.

It is upto the users to configure the foreign keys in MySQL such that rows that are related by foreign keys end up living in the same shard.
To this end, users can configure tables related by foreign keys to use the same shared vindex. More detail about this can be read in [shared vindexes](../shared-vindexes/#foreign-keys).

#### Limitations

- In a sharded keyspace, the current restrictions require the schema to be structured such that rows for tables linked by foreign keys need to live on the same shard. This constrains schema design and sharding key options. 
- If `ON DELETE CASCADE`, `ON UPDATE CASCADE`, `ON DELETE SET NULL`, etc reference actions are used for foreign keys that cause a change on a child table when the parent is updated, MySQL doesn't report the updates on the child table in the binary log. They happen at the InnoDB level. This causes VReplication to not see the updates on the child, causing issues in [MoveTables](../../migration/move-tables/) and other VReplication based workflows.
- [OnlineDDL](../../schema-changes/managed-online-schema-changes/) doesn't work well with tables that have foreign key constraints on them.

### Vitess Aware Foreign Keys [EXPERIMENTAL]

{{< info >}}
Please note, that in this version of Vitess, this mode is experimental and should be used cautiously.
{{< /info >}}

Users can run Vitess such that it keeps track of all the foreign key constraints using the schema tracker. To run Vitess in this mode, `foreignKeyMode` VSchema property has to be set to `FK_MANAGED` for the given keyspace.

In this mode, Vitess takes care of splitting up DMLs that would cause updates on a child table in a foreign key constraint. All the queries on MySQL are executed such that InnoDB doesn't end up running any updates which don't make their way into the binary log. This allows VReplication to work properly, thus relaxing one of the limitations of the previous approach.

For more details on what operations Vitess takes please refer to the [design document for foreign keys](https://github.com/vitessio/vitess/issues/12967).

#### Limitations

- Currently, Vitess only supports shard-scoped foreign key constraints even in the managed mode. Support for cross-shard foreign keys is underway.
- `UPDATE` statements only support updating to a literal value. For example, `UPDATE t1 SET col1 = 3 WHERE id = col + 1` is accepted, but `UPDATE t1 SET col1 = col + 3` is not.
- [OnlineDDL](../../schema-changes/managed-online-schema-changes/) doesn't work well with tables that have foreign key constraints on them.

### Vitess Disallows Foreign Keys

Users can run Vitess such that it explicitly disallows any DDL statements that try to create a foreign key constraint. To run Vitess in this mode, `foreignKeyMode` VSchema property has to be set to `FK_DISALLOW` for the given keyspace.

This mode is for users that don't use foreign keys and want to prevent accidentally introducing them in their schema.
