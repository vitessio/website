---
title: How Traffic Is Switched
description: How Vitess signals traffic cutover for Reshard and MoveTables
weight: 2
aliases: ['/docs/design-docs/vreplication/cutover/']
---

# Related Persistent Vitess Objects

{{< info >}}
As the objects or keys noted below are stored in [the topo server](../../../features/topology-service/) and
cached locally, the processes involved will refresh their topo data throughout the cutover process. For example, each
tablet on the source and target shards that are involved in a [VReplication](../../) workflow
will refresh their topo data multiple times as the state of things transition during the cutover. If we are *not* able
to confirm that all tablets involved in a VReplication worfklow are able to refresh their topo data then the cutover
command — e.g. [`vtctlclient SwitchTraffic`](../../switchtraffic) — will cancel the operation
and return an error indicating which tablet(s) are unhealthy (including for `--dry_run` executions).
{{< /info >}}

## VSchema

A [VSchema](../../../../concepts/vschema/) allows you to describe how data is organized within keyspaces and shards.

## Shard Info

The [`global` topo](../../../features/topology-service/#global-vs-local) contains
one [`Shard`](../../../features/topology-service/#shard) key per keyspace which then contains one key per
shard that has been created within the keyspace. For each shard that is healthy there is an
attribute `is_primary_serving` which is set to true. The other shards which have been created but are still not healthy
and serving within the keyspace will not have this attribute set. Here is an example shard info record from an unsharded
keyspace named commerce (without the `--cell` flag being passed the `global` topo base path is used):

```bash
$ vtctlclient --server=localhost:15999 TopoCat -- --decode_proto '/keyspaces/commerce/shards/0/Shard'
primary_alias:{cell:"zone1" uid:100} primary_term_start_time:{seconds:1650341417 nanoseconds:374817485} is_primary_serving:true
```

## SrvKeyspace

Each cell has a [`SrvKeyspace`](../../../features/topology-service/#srvkeyspace) key in
the [`local` topo](../../../features/topology-service/#global-vs-local) (per cell info) for each keyspace. For
each tablet type (e.g. `PRIMARY` or `REPLICA`) there is one `partitions` object. The `partitions` objects contain all of the
current shards in the keyspace. For sharded keyspaces, the tablets which are healthy and serving have a key range specified
for that shard.

Also the primary can contain a `query_service_disabled` attribute which is set to `true` during resharding cutovers.
This tells the primary in that shard to reject any queries made to it, as a signal to vtgate in case vtgate routes
queries to this primary during the cutover or before it discovers the new serving graph. Here is an example using the
same unsharded commerce keyspace and here we specify the `--cell` flag so that cell's topo base path — stored in
its `CellInfo` record in the `global` topo — is used:

```bash
$ vtctlclient --server=localhost:15999 TopoCat -- --decode_proto '/cells/zone1/CellInfo'
server_address:"localhost:2379" root:"/vitess/zone1"

$ vtctlclient --server=localhost:15999 TopoCat -- --decode_proto --cell=zone1 '/keyspaces/commerce/SrvKeyspace'
partitions:{served_type:PRIMARY shard_references:{name:"0"}} partitions:{served_type:REPLICA shard_references:{name:"0"}} partitions:{served_type:RDONLY shard_references:{name:"0"}}
```

## Routing Rules

[Routing Rules](../../../features/schema-routing-rules) are stored in the `RoutingRules` key within
the `global` topo. Routing Rules contain a list of table-specific routes. You can route a table for all or specific
tablet types to another table in the same or different keyspace. Here is an example using the same commerce keyspace
where we have an active [`MoveTables`](../../../vreplication/movetables/) workflow to move tables to the
customer keyspace but we have not switched any traffic yet:

```bash
$ vtctlclient --server=localhost:15999 TopoCat -- --decode_proto '/RoutingRules'
rules:{from_table:"corder@rdonly" to_tables:"commerce.corder"} rules:{from_table:"customer.corder" to_tables:"commerce.corder"} rules:{from_table:"customer.corder@replica" to_tables:"commerce.corder"} rules:{from_table:"customer@rdonly" to_tables:"commerce.customer"} rules:{from_table:"customer.customer@rdonly" to_tables:"commerce.customer"} rules:{from_table:"customer.corder@rdonly" to_tables:"commerce.corder"} rules:{from_table:"customer@replica" to_tables:"commerce.customer"} rules:{from_table:"corder@replica" to_tables:"commerce.corder"} rules:{from_table:"commerce.corder@replica" to_tables:"commerce.corder"} rules:{from_table:"commerce.corder@rdonly" to_tables:"commerce.corder"} rules:{from_table:"commerce.customer@rdonly" to_tables:"commerce.customer"} rules:{from_table:"corder" to_tables:"commerce.corder"} rules:{from_table:"customer.customer@replica" to_tables:"commerce.customer"} rules:{from_table:"commerce.customer@replica" to_tables:"commerce.customer"} rules:{from_table:"customer" to_tables:"commerce.customer"} rules:{from_table:"customer.customer" to_tables:"commerce.customer"}
```

</br>

{{< info >}}
In practice you would instead typically view the routing rules via the
dedicated [`GetRoutingRules`](../../../programs/vtctl/schema-version-permissions/#getroutingrules)
vtctl client command which will return the rules for all keyspaces in the topo.
{{< /info >}}

# How VTGate Routes a Query

This section walks through a simplified version of the logic used to determine which keyspace and table vtgate will route
a simple query of the form `select * from t1 where id = 1` (a _read_ query) or `insert into t1 (id, val) values (1,'abc')`
(a _write_ query).

1. Check to see if `t1` has an appropriate routing rule defined. If so, use the specified target table as an alias for `t1`.
2. Locate the keyspace for `t1` using the [`VSchema`](../../../features/vschema/).
3. For a non-sharded keyspace locate the appropriate tablet (`PRIMARY`, by default) from the (cached) `SrvKeyspace` `local`
(per cell) topo record.
4. For a sharded keyspace the `SrvKeyspace` record is used to find the currently active shards. This is done by checking
the list of partitions for the specific tablet type selected for the query (`PRIMARY`, by default, for both reads and writes)
and selecting the ones whose `query_service_disabled` field is *not* set and whose `is_primary_serving` value is true.
5. Finally, based on the [`VIndex`](../../../features/vindexes/) defined for the table from the cached
[`VSchema`](../../../features/vschema/) (stored in the `global` topo), the shard for the relevant row is computed based
on the keyrange to which the id is mapped to using the declared [`VIndex` function/type](../../../features/vindexes/#predefined-vindexes).

# Changes Made to the Topo When Traffic Is Switched

This document outlines the steps involved in the cutover process
of [`MoveTables`](../../movetables/) and [`Reshard`](../../reshard/)
workflows when traffic is switched from the source tables/shards to the target tables/shards. We use the resharding flow
provided in the [local examples](../../../../get-started/local/) and show the relevant snippets from the topo for each step
in the workflow.

{{< info >}}
Items in italics are topo keys and the following snippet the value of the key
{{< /info >}}

## What Happens When a Reshard Is Cutover

For brevity we only show the records for the `80-` shard. There will be similar records for the `-80` shard.

#### Before Resharding, After -80/80- Shards Are Created

Only shard `0` has `is_primary_serving` set to true. The `SrvKeyspace` record only has references to `0` for both `PRIMARY`
and `REPLICA` tablet types.

*global/keyspaces/customer/shards/0/Shard*

```proto
primary_alias:{cell:"zone1" uid:200}
primary_term_start_time:{seconds:1627465761 nanoseconds:600070156}
is_primary_serving:true
```

</br>

*global/keyspaces/customer/shards/80-/Shard*

```proto
primary_alias:{cell:"zone1" uid:400}
primary_term_start_time:{seconds:1627465833 nanoseconds:536524508}
key_range:{start:"\x80"}
```

</br>

*zone1/keyspaces/customer/SrvKeyspace*

```proto
partitions:{served_type:PRIMARY shard_references:{name:"0"}}
partitions:{served_type:REPLICA shard_references:{name:"0"}}
```

### After Replica Traffic Is Switched Using `SwitchTraffic` (Previously Known as SwitchReads)

Shard `0` still has the `is_primary_serving` set as true. The primary partition is still the same.

The replica partition has the following changes:

* Two more shard_references for `-80` and `80-`
* Key ranges are specified for these shards
* The key range for shard `0` has been removed
* `query_service_disabled` is set to true for shard `0`

*global/keyspaces/customer/shards/0/Shard*

```proto
primary_alias:{cell:"zone1" uid:200}
primary_term_start_time:{seconds:1627466189 nanoseconds:587021377}
is_primary_serving:true
```

</br>

*global/keyspaces/customer/shards/80-/Shard*

```proto
primary_alias:{cell:"zone1" uid:400}
primary_term_start_time:{seconds:1627466263 nanoseconds:16201490}
key_range:{start:"\x80"}``
```

</br>

_zone1/keyspaces/customer/SrvKeyspace_

```proto
partitions:{served_type:PRIMARY shard_references:{name:"0"}}

partitions:{served_type:REPLICA
  shard_references:{name:"-80" key_range:{end:"\x80"}}
  shard_references:{name:"80-" key_range:{start:"\x80"}}
  shard_tablet_controls:{name:"0" query_service_disabled:true}
  shard_tablet_controls:{name:"-80" key_range:{end:"\x80"}}
  shard_tablet_controls:{name:"80-" key_range:{start:"\x80"}}
}
```

</br>

#### After Primary Traffic Is Switched Using `SwitchTraffic` (Previously Known as SwitchWrites)

* `is_primary_serving` is removed from shard `0`
* `is_primary_serving` is added to shards `-80` and `80-`
* In the primary partition the shards `-80` and `80-` are added with their associated key ranges
* In the primary partition the key range for shard `0` is removed
* The replica partition remains the same as in the previous step

*global/keyspaces/customer/shards/0/Shard*

```proto
primary_alias:{cell:"zone1" uid:200}
primary_term_start_time:{seconds:1627466636 nanoseconds:405646818}
```

</br>

*global/keyspaces/customer/shards/80-/Shard*

```proto
primary_alias:{cell:"zone1" uid:400}
primary_term_start_time:{seconds:1627466710 nanoseconds:579634511}
key_range:{start:"\x80"}
is_primary_serving:true
```

</br>

*zone1/keyspaces/customer/SrvKeyspace*

```proto
partitions:{served_type:PRIMARY
  shard_references:{name:"-80" key_range:{end:"\x80"}}
  shard_references:{name:"80-"
  key_range:{start:"\x80"}}
} {name:"0"}

partitions:{served_type:REPLICA
  shard_references:{name:"-80" key_range:{end:"\x80"}}
  shard_references:{name:"80-" key_range:{start:"\x80"}}}
  shard_tablet_controls:{name:"0" query_service_disabled:true}
  shard_tablet_controls:{name:"-80" key_range:{end:"\x80"}}
  shard_tablet_controls:{name:"80-" key_range:{start:"\x80"}}
}
```

## What Happens When a MoveTables Workflow Is Cutover

#### Before MoveTables Is Initiated

The [`VSchema`](../../../features/vschema/) for the source keyspace contains the table name, so vtgate routes queries to that
keyspace.

#### During MoveTables

Both the source and target now contain the tables and both [`VSchemas`](../../../features/vschema/) refer to them. However we
have routing rules that map the tables for each tablet type from the target keyspace to the source keyspace.

*global/RoutingRules*

```proto
rules:{from_table:"customer" to_tables:"commerce.customer"}
rules:{from_table:"customer.customer" to_tables:"commerce.customer"}
rules:{from_table:"customer@replica" to_tables:"commerce.customer"}
rules:{from_table:"customer.customer@replica" to_tables:"commerce.customer"}
```

</br>

#### On Switching Replica Traffic to Target

The routing rules for replica targeted reads are updated to map the table on the source to the target.

*global/RoutingRules*

```proto
rules:{from_table:"customer.customer" to_tables:"commerce.customer"} rules:{from_table:"commerce.customer@replica" to_tables:"customer.customer"}
rules:{from_table:"customer" to_tables:"commerce.customer"}
rules:{from_table:"customer@replica" to_tables:"customer.customer"}
```

</br>

#### On Switching Primary Traffic

The routing rules for default read-write traffic are updated to map the table on the source to the target. In addition the
tables are added to the “denylist” on the source keyspace which `vttablet` uses to reject queries for these tables on the
old/inactive shards.

*global/RoutingRules*

```proto
rules:{from_table:"commerce.customer@replica" to_tables:"customer.customer"}
rules:{from_table:"customer.customer@replica" to_tables:"customer.customer"}
rules:{from_table:"commerce.customer" to_tables:"customer.customer"}
rules:{from_table:"customer" to_tables:"customer.customer"}
```

</br>

*global/keyspaces/commerce/shards/0/Shard*

```proto
primary_alias:{cell:"zone1" uid:100}
primary_term_start_time:{seconds:1627477340 nanoseconds:740407602}
tablet_controls:{tablet_type:PRIMARY denylisted_tables:"customer"}
is_primary_serving:true
```

# Miscellaneous Notes

* In VReplication workflows, cutovers are performed manually by the user executing the `SwitchTraffic` and `ReverseTraffic`
actions e.g. for a [`MoveTables`](../../movetables/) or [`Reshard`](../../reshard/) vtctl
client command.
* When traffic for `REPLICA` and `RDONLY` tablets is switched not all read traffic is switched: primary/default reads will
still be served from the source shards, until `PRIMARY` tablet traffic is also switched.
