---
title: Foreign Keys in Vitess
weight: 8
---

There are several options for running Vitess with Foreign Key constraints.

### Vitess Unaware of Foreign Keys

You can run Vitess such that it ignores any foreign key constraints defined at the MySQL level. To run Vitess in this mode, set the VSchema property `foreignKeyMode` to `unmanaged` at the keyspace level. This is the default mode if nothing is specified.

It is up to the user to configure foreign keys in MySQL such that rows that are related by foreign keys end up living in the same shard.
In order for this to work, tables related by foreign keys should use a shared vindex. For details please refer to the [shared vindexes](../shared-vindexes/#foreign-keys) documentation.

#### Limitations

- In a sharded keyspace, the schema has to be structured such that rows for tables linked by foreign keys live on the same shard. This constrains schema design and sharding key options.
- If using reference actions for foreign keys that cause a change on a child table when the parent is updated, e.g. `ON DELETE CASCADE`, `ON UPDATE CASCADE`, `ON DELETE SET NULL` etc., MySQL does not record the updates on the child table in the binary log. They happen at the InnoDB level. This can cause problems with [MoveTables](../../migration/move-tables/) and other VReplication based workflows because VReplication relies on binary log updates.
- [OnlineDDL](../../schema-changes/managed-online-schema-changes/) doesn't work well with tables that have foreign key constraints on them.

### Vitess Handles Foreign Keys [EXPERIMENTAL]

{{< info >}}
Please note that this feature is experimental and should be used with caution.
{{< /info >}}

You can run Vitess such that it keeps track of all foreign key constraints using the schema tracker. To run Vitess in this mode, set the VSchema property `foreignKeyMode` to `managed` at the keyspace level.

In this mode, Vitess will handle DMLs (INSERT/UPDATE/DELETE) that could cause changes to child tables "correctly". Vitess will generate and execute DMLs on child tables in the correct order so that all of them show up in the binary log. This allows VReplication to work properly, thus relaxing one of the limitations of the previous approach.

For more details on what operations Vitess performs for each type of DML, please refer to the [design document for foreign keys](https://github.com/vitessio/vitess/issues/12967).

#### Limitations

- Currently, Vitess only supports shard-scoped foreign key constraints even in the `managed` mode. Support for cross-shard foreign keys is planned for a future release.
- `UPDATE` statements only support updating to a literal value. For example, `UPDATE t1 SET col1 = 3 WHERE id = col + 1` is accepted, but `UPDATE t1 SET col1 = col + 3` is not.
- [OnlineDDL](../../schema-changes/managed-online-schema-changes/) doesn't work well with tables that have foreign key constraints on them.

### Vitess Disallows Foreign Keys

You can run Vitess such that it explicitly disallows any DDL statements that try to create a foreign key constraint. To run Vitess in this mode, set the VSchema property `foreignKeyMode` to `disallow` at the keyspace level.

This mode is for users that don't use foreign keys and want to prevent accidentally introducing them in their schema.


