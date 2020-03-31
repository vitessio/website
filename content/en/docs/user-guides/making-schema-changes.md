---
title: Making Schema Changes
weight: 11
aliases: ['/docs/schema-management/mysql-schema/', '/docs/user-guides/mysql-schema/']
---

For applying schema changes for MySQL instances managed by Vitess, there are a few options.

## ApplySchema

`ApplySchema` is a `vtctlclient` command that can be used to apply a schema to a keyspace. The main advantage of using this
tool is that it performs some sanity checks about the schema before applying it. For example, if the schema change
affects too many rows of a table, it will reject it.

However, the downside is that it is a little too strict, and may not work for all use cases.

## VTGate

You can send a DDL statement directly to a VTGate just like you would send to a MySQL instance. If the target is a sharded keyspace,
then the DDL would be scattered to all shards.

If a specific shard fails you can target it directly using the `keyspace/shard` syntax to retry the apply just to that shard.

If VTGate does not recognize a DDL syntax, the statement will get rejected.

This approach is not recommended for changing large tables.

## Directly to MySQL

You can apply schema changes directly to the underlying MySQL shard master instances. VTTablet will eventually notice the change
and update itself (this is controlled by the `-queryserver-config-schema-reload-time` parameter and defaults to 1800 seconds).
You can also explicitly issue the `vtctlclient` `ReloadSchema` command to make it reload immediately.

This approach can be extended to use schema deployment tools like `gh-ost` or `pt-online-schema-change`. Using these schema
deployment tools is the recommended approach for large tables, because they incur no downtime.
