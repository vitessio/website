---
title: Schema Management
weight: 16
aliases: ['/docs/schema-management/','/docs/user-guides/schema-management/','/docs/reference/schema-management/']
---

Using Vitess requires you to work with two different types of schemas:

1. The MySQL database schema. This is the schema of the individual MySQL instances.
2. The [VSchema](../vschema), which describes all the keyspaces and how they're sharded.

The workflow for the `VSchema` is as follows:

1. Apply the `VSchema` for each keyspace using the `ApplyVschema` command. This saves the VSchemas in the global topology service.
2. Execute `RebuildVSchemaGraph` for each cell (or all cells). This command propagates a denormalized version of the combined VSchema to all the specified cells. The main purpose for this propagation is to minimize the dependency of each cell from the global topology. The ability to push a change to only specific cells allows you to canary the change to make sure that it's good before deploying it everywhere.

This document describes the [`vtctl`](../../../reference/programs/vtctl/) commands that you can use to [review](#reviewing-your-schema) or [update](#changing-your-schema) your schema in Vitess.

It is not recommended to run schema changes through this command. Instead, use [managed, online schema changes](../../../user-guides/schema-changes/managed-online-schema-changes/).

## Reviewing Your Schema

This section describes the following vtctl commands, which let you look at the schema and validate its consistency across tablets or shards:

* [GetSchema](#getschema)
* [ValidateSchemaShard](#validateschemashard)
* [ValidateSchemaKeyspace](#validateschemakeyspace)
* [GetVSchema](#getvschema)
* [GetSrvVSchema](#getsrvvschema)

### GetSchema

The [GetSchema](../../programs/vtctl/schema-version-permissions#getschema) command displays the full schema for a tablet or a subset of the tablet's tables. When you call `GetSchema`, you specify the tablet alias that uniquely identifies the tablet. The `<tablet alias>` argument value has the format `<cell name>-<uid>`.

**Note**: You can use the [`vtctl ListAllTablets`](../../../reference/programs/vtctl/#listalltablets) command to retrieve a list of tablets in a cell and their unique IDs.

The following example retrieves the schema for the tablet with the unique ID test-000000100:

``` sh
GetSchema test-000000100
```

### ValidateSchemaShard

The [`ValidateSchemaShard`](../../../reference/programs/vtctl/#validateschemashard) command confirms that for a given keyspace, all of the replica tablets in a specified shard have the same schema as the primary tablet in that shard. When you call `ValidateSchemaShard`, you specify both the keyspace and the shard that you are validating.

The following command confirms that the primary and replica tablets in shard `0` all have the same schema for the `user` keyspace:

``` sh
ValidateSchemaShard user/0
```

### ValidateSchemaKeyspace

The [`ValidateSchemaKeyspace`](../../../reference/programs/vtctl/#validateschemakeyspace) command confirms that all of the tablets in a given keyspace have the the same schema as the primary tablet on shard `0` in that keyspace. Thus, whereas the `ValidateSchemaShard` command confirms the consistency of the schema on tablets within a shard for a given keyspace, `ValidateSchemaKeyspace` confirms the consistency across all tablets in all shards for that keyspace.

The following command confirms that all tablets in all shards have the same schema as the primary tablet in shard 0 for the user keyspace:

``` sh
ValidateSchemaKeyspace user
```

### GetVSchema

The [`GetVSchema`](../../../reference/programs/vtctl/#getvschema) command displays the global VSchema for the specified keyspace.

### GetSrvVSchema

The [`GetSrvVSchema`](../../../reference/programs/vtctl/#getsrvvschema) command displays the combined VSchema for a given cell.

## Changing Your Schema

This section describes the following commands:

* [ApplySchema](#applyschema)
* [ApplyVSchema](#applyvschema)
* [RebuildVSchemaGraph](#rebuildvschemagraph)

### ApplySchema

Vitess offers [managed schema migration](../../../user-guides/schema-changes/managed-online-schema-changes/), and notably supports online schema migrations (aka Online DDL), transparently to the user. Vitess Online DDL offers:

* Non-blocking migrations
* Migrations are asyncronously auto-scheduled, queued and executed by tablets
* Migration state is trackable
* Migrations are cancellable
* Migrations are retry-able
* Lossless, [revertible migrations](../../../user-guides/schema-changes/revertible-migrations/)
* Support for [declarative migrations](../../../user-guides/schema-changes/declarative-migrations/)
* Support for [postponed migrations](../../../user-guides/schema-changes/postponed-migrations/)
* Support for [failover agnostic migrations](../../../user-guides/schema-changes/recoverable-migrations/)
* Support for [concurrent migrations](../../../user-guides/schema-changes/concurrent-migrations/)

The [ApplySchema](../../../reference/programs/vtctl/schema-version-permissions/#applyschema) command applies a schema change to the specified keyspace on all shards. The command format is: `ApplySchema -- {--sql=<sql> || --sql_file=<filename>} <keyspace>`

Further reading:

* [Making schema changes](../../../user-guides/schema-changes/)
* [Managed schema changes](../../../user-guides/schema-changes/managed-online-schema-changes/)
* [DDL strategies](../../../user-guides/schema-changes/ddl-strategies/)

#### Permitted Schema Changes

The `ApplySchema` command supports these commands:

* `CREATE TABLE`, `ALTER TABLE`, `DROP TABLE`, `CREATE VIEW`, `ALTER VIEW`, `DROP VIEW` in Online DDL
* In addition, `CREATE INDEX`, `DROP INDEX`, `RENAME TABLE`, in non Online DDL

`ApplySchema` does not support creation or modifications of stored routines, including functions, procedures, triggers, and events.

### ApplyVSchema

The [`ApplyVSchema`](../../../reference/programs/vtctl/#applyvschema) command applies the specified VSchema to the keyspace. The VSchema can be specified as a string or in a file.

### RebuildVSchemaGraph

The [`RebuildVSchemaGraph`](../../../reference/programs/vtctl/#rebuildvschemagraph) command propagates the global VSchema to a specific cell or the list of specified cells.
