---
title: Applying MySQL schema
weight: 1
---

For applying schema changes for MySQL instances managed by Vitess, there are a few options.

## ApplySchema

`ApplySchema` is a vtctlclient command that can be used to apply a schema to a keyspace. The main advantage of using this
tool is that it performs some sanity checks about the schema before applying it. For example, if the schema change
affects too many rows of a table, it will reject it.

However, the down side is that it is a little too strict, and may not work for all use cases.

## VTGate

You can send a DDL directly to a VTGate just like you would send to a mysql instance. If the target is a sharded keyspace,
then the DDL would be sprayed to all shards.

If a specific shard fails you can target it directly using the `keyspace/shard` syntax to retry the apply just to that shard.

If VTGate does not recognize a DDL syntax, the statement will get rejected.

This approach is not recommended for changing large tables.

## Directly to MySQL

You can apply schema changes directly to MySQL. VTTablet will eventually notice the change and update itself. You can also
explicitly issue the vtctlclient `ReloadSchema` command to make it reload immediately.

This approach can be extended to use schema deployment tools like `gh-ost` or `pt-online-schema-change`. Using these schema
deployment tools is the recommended approach for large tables, because they incur no downtime.
