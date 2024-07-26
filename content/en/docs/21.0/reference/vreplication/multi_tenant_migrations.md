---
title: Multi Tenant Migrations
description: Importing multiple tenant databases into a single Vitess cluster
weight: 120
aliases: [ '/docs/reference/vreplication/v2/multitenant-migrations/' ]
---

## Description

{{< warning >}}
This feature is an **experimental** variant of
the [`MoveTables`](../../../reference/programs/vtctldclient/vtctldclient_movetables/) command that
allows you to migrate from a multi-tenant architecture, with one database per tenant, into a single Vitess cluster.
Please be sure to understand the limitations and requirements below.
{{< /warning >}}

The full set of options for the `MoveTables`
command [can be found here](../../../reference/programs/vtctldclient/vtctldclient_movetables/).
The options and other aspects specific to multi-tenant migrations will be covered here.

## Use Case

The user has a multi-tenant database architecture. They have several separate MySQL databases, with common schemas,
one per tenant. This design has several disadvantages, including the need to manage multiple databases, needing to
update the schema on all databases before the app can start using the new schema, inability to run cross-tenant
queries, etc.

This system maps well to a sharded Vitess cluster, providing a single logical database where tenants are mapped to
specific shards.

## Assumptions

- The target keyspace has its schema already initialized.
- Each table in the target keyspace has a tenant id column with the same name and type on both source and target, and it
  should be part of the primary key of each table.
- If the target keyspace is sharded, the vindex should be a multicolumn vindex with the tenant id column
  as the first column.

## Design

### VSchema 
A new vschema object is required which defines the column name which defines the tenant id.  The actual tenant id is
specified for each migration. It should be added at the root level (like `tables`, `vindexes`)
```
"multi_tenant_spec": {
"tenant_id_column_name": "app_id",
"tenant_id_column_type": "INT64"
}
```


## Key Parameter

#### --source-shards

**mandatory** (for shard level migrations)
<div class="cmd">

A list of one or more shards that you want to migrate from the source keyspace
to the target keyspace.

</div>

## Sample Flow

### Create unmanaged keyspace

Create a source keyspace, say `import_1234` with unmanaged tablets pointing to one tenant's database, whose tenant 
id is 1234. (https://vitess.io/docs/user-guides/configuration-advanced/unmanaged-tablet/)


### Create MoveTables Workflow

`MoveTables --workflow=wf_1234 --target-keyspace=vitess_sharded Create --source-keyspace=import_1234 --all-tables --tenant-id=1234`

Like other vreplication workflows, once this workflow starts, it will first run the Copy phase. Once it is in the 
Running phase with a low VReplication lag, ideally a second or so, you can switch traffic.

### Monitor Workflow

`Workflow --keyspace=vitess_sharded Show –workflow=wf_1234 --include-logs=false`

### Switch Traffic

`MoveTables --workflow=wf_1234 --target-keyspace=vitess_sharded SwitchTraffic`

### Complete Workflow

`MoveTables --workflow=wf_1234 --target-keyspace=vitess_sharded Complete`

### Migrate all tenants

Multiple tenants can be migrated concurrently. Note that previously migrated tenants will be pointing to the Vitess 
cluster for their production load. So you may want to limit the concurrency so that the imports are not impacting 
live performance.

When all tenants have been imported the migration will be complete and once you are satisfied with the behaviour of 
the Vitess cluster, you can turn off your existing database setup.

Note that, as tenants get migrated, you will have some tenants served by Vitess and others by the existing database 
cluster. A mechanism will be needed for the app to cutover the migrated tenant by pointing the database connection 
to the Vitess cluster.

## Reverse Replication

While reverse replication will run after SwitchTraffic, we cannot run a ReverseTraffic for multi-tenant migrations. 
This is because we cannot stop writes on the target, which will have live traffic for several other tenants.
Currently, for reversing we will need to perform, several manual reverse steps:
* manually switch the routing in the app to point to the existing database for the tenant
* delete the data from the target for that tenant manually
* drop the external keyspace 
* delete related keyspace routing rules (https://vitess.io/docs/20.0/reference/programs/vtctldclient/vtctldclient_applykeyspaceroutingrules/)
* delete the vreplication workflow


## Optimizations
The `MoveTables` and `Workflow` commands now take an additional --shards parameter. This ensures that these commands 
only communicate with the primary of that shard instead of all shards. It is strongly recommended to provide this 
while working with large number of shards (say 32 and above), while working with multi-tenant migrations.

Usually a tenant will be mapped to very few shards, (probably one for smaller tenants). If `--shards` is not specified
then these commands will unnecessarily contact the remaining shards. For larger number of shards this can take 
several seconds and indeed `SwitchTraffic` might end up timing out.

Note that an incorrect shard naming can result in an incorrect migration or reporting of an incorrect status. So you 
would build in some automation if you intend to use it. 

One way of finding out the shard to which a tenant will be mapped is by running this query in vtgate:
`select shard from <your_vindex_name> where id = <tenant_id>;`


