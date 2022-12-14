---
title: How traffic is switched
description: How Vitess signals traffic cutover for Reshard and MoveTables
weight: 30
---

# Related persistent Vitess objects

{{< info >}}
As the objects or keys noted below are stored in [the topo server](../../../reference/features/topology-service/) and cached locally, the processes involved will refresh their topo data throughout the cutover process. For example, each tablet on the source and target shards that are involved in a [VReplication](../../../reference/vreplication/) workflow will refresh their topo data multiple times as the state of things transition during the cutover. If we are *not* able to confirm that all tablets involved in a VReplication worfklow are able to refresh their topo data then the cutover command — e.g. [`vtctlclient SwitchTraffic`](../../../reference/vreplication/switchtraffic/) — will cancel the operation and return an error indicating which tablet(s) is unhealthy (including `--dry_run` executions).
{{< /info >}}

## VSchema

A [VSchema](../../../concepts/vschema/) allows you to describe how data is organized within keyspaces and shards.

## Shard Info

The [`global` topo](../../../reference/features/topology-service/#global-vs-local) contains one [`Shard`](../../../reference/features/topology-service/#shard) key per keyspace which then contains one key per shard that has been created within the keyspace. For each shard that is healthy there is an attribute `is_primary_serving` which is set to true. The other shards which have been created but are still not healthy and serving within the keyspace will not have this attribute set. Here is an example shard info record from an unsharded keyspace named commerce (without the `--cell` flag being passed the `global` topo base path is used):
```bash
$ vtctlclient --server=localhost:15999 TopoCat -- --decode_proto '/keyspaces/commerce/shards/0/Shard'
primary_alias:{cell:"zone1" uid:100} primary_term_start_time:{seconds:1650341417 nanoseconds:374817485} is_primary_serving:true
```

## SrvKeyspace

Each cell has a [`SrvKeyspace`](../../../reference/features/topology-service/#srvkeyspace) key in the [`local` topo](../../../reference/features/topology-service/#global-vs-local) (per cell info) for each keyspace. For each tablet type (primary/replica) there is one `partitions` object. The `partitions` objects contain all of the current shards in the keyspace. For sharded keyspaces, the tablets which are healthy and serving have a key range specified for that shard.

Also the primary can contain a `query_service_disabled` attribute which is set to false during resharding cutovers. This tells the primary in that shard to reject any queries made to it, as a signal to vtgate in case vtgate routes queries to this primary during the cutover or before it discovers the new serving graph. Here is an example using the same unsharded commerce keyspace and here we specify the `--cell` flag so that cell's topo base path — stored in its `CellInfo` record in the `global` topo — is used:
```bash
$ vtctlclient --server=localhost:15999 TopoCat -- --decode_proto '/cells/zone1/CellInfo'
server_address:"localhost:2379" root:"/vitess/zone1"

$ vtctlclient --server=localhost:15999 TopoCat -- --decode_proto --cell=zone1 '/keyspaces/commerce/SrvKeyspace'
partitions:{served_type:PRIMARY shard_references:{name:"0"}} partitions:{served_type:REPLICA shard_references:{name:"0"}} partitions:{served_type:RDONLY shard_references:{name:"0"}}
```

## Routing Rules

[Routing Rules](../../../reference/features/schema-routing-rules) are stored in the `RoutingRules` key within the `global` topo. Routing Rules contain a list of table-specific routes. You can route a table for all or specific tablet types to another table in the same or different keyspace. Here is an example using the same commerce keyspace where we have an active [`MoveTables`](../../../reference/vreplication/movetables/) workflow to move tables to the customer keyspace but we have not switched any traffic yet:
```bash
$ vtctlclient --server=localhost:15999 TopoCat -- --decode_proto '/RoutingRules'
rules:{from_table:"corder@rdonly" to_tables:"commerce.corder"} rules:{from_table:"customer.corder" to_tables:"commerce.corder"} rules:{from_table:"customer.corder@replica" to_tables:"commerce.corder"} rules:{from_table:"customer@rdonly" to_tables:"commerce.customer"} rules:{from_table:"customer.customer@rdonly" to_tables:"commerce.customer"} rules:{from_table:"customer.corder@rdonly" to_tables:"commerce.corder"} rules:{from_table:"customer@replica" to_tables:"commerce.customer"} rules:{from_table:"corder@replica" to_tables:"commerce.corder"} rules:{from_table:"commerce.corder@replica" to_tables:"commerce.corder"} rules:{from_table:"commerce.corder@rdonly" to_tables:"commerce.corder"} rules:{from_table:"commerce.customer@rdonly" to_tables:"commerce.customer"} rules:{from_table:"corder" to_tables:"commerce.corder"} rules:{from_table:"customer.customer@replica" to_tables:"commerce.customer"} rules:{from_table:"commerce.customer@replica" to_tables:"commerce.customer"} rules:{from_table:"customer" to_tables:"commerce.customer"} rules:{from_table:"customer.customer" to_tables:"commerce.customer"}
```

{{< info >}}
In practice you would instead typically view the routing rules via the dedicated [`vtctl GetRoutingRules`](../../../reference/programs/vtctl/schema-version-permissions/#getroutingrules) command which will return the rules for all keyspaces in the topo.
{{< /info >}}

# How VTGate routes a query

This section gives a simplified logic used to determine which keyspace and table vtgate will route a simple query of the form `select * from t1 where id = 1` (a _read_ query) or `insert into t1 (id, val) values (1,'abc')` (a _write_ query).

* Check to see if t1 has an appropriate routing rule defined. If so, use the specified target table as an alias for t1
* Locate the keyspace for t1 using the VSchema
* For a non-sharded keyspace locate the appropriate tablet (primary, by default) from the (cached) `SrvKeyspace` `local` (per cell) topo record.
* For a sharded keyspace the `SrvKeyspace` record is used to find the currently active shards. This is done by checking the list of partitions for the specific tablet type selected for the query (primary, by default, for reads and writes) and selecting the ones whose `query_service_disabled` is not set and whose `is_primary_serving` is true.
* Finally, based on the vindex for the table from the cached `VSchema` (stored in the `global` topo), the shard for the relevant row is computed based on the keyrange to which the id is mapped to using the declared vindex function/type.

# Changes made to the topo when traffic is switched

This document outlines the steps involved in the cutover process of [`MoveTables`](../../../reference/vreplication/movetables/) and [`Reshard`](../../../reference/vreplication/reshard/) workflows when traffic is switched from the source tables/shards to the target tables/shards. We use the resharding flow provided in the local examples and show the relevant snippets from the topo for each step in the workflow.

Note: Items in italics are topo keys and the following snippet the value of the key

## What happens when a Reshard is cutover

For brevity we only show the records for the 80- shard. There will be similar records for the -80 shard.

#### Before Resharding, after -80/80- shards are created

Only shard 0 has `is_primary_serving` set to true. The `SrvKeyspace` record only has references to 0 for both primary and replica.

_global/keyspaces/customer/shards/0/Shard_

```
primary_alias:{cell:"zone1" uid:200}
primary_term_start_time:{seconds:1627465761 nanoseconds:600070156}
is_primary_serving:true
```

_global/keyspaces/customer/shards/80-/Shard_

```
primary_alias:{cell:"zone1" uid:400}
primary_term_start_time:{seconds:1627465833 nanoseconds:536524508}
key_range:{start:"\x80"}
```

_zone1/keyspaces/customer/SrvKeyspace_

```
partitions:{served_type:PRIMARY shard_references:{name:"0"}}
partitions:{served_type:REPLICA shard_references:{name:"0"}}
```

### After replica traffic is switched (aka SwitchReads)

Shard 0 still has the `is_primary_serving` set as true. The primary partition is still the same.

The replica partition has the following changes:

* Two more shard_references for -80 and 80-
* Key ranges are specified for these shards
* The key range for shard 0 has been removed
* `query_service_disabled` is set to true for shard 0

_global/keyspaces/customer/shards/0/Shard_

```
primary_alias:{cell:"zone1" uid:200}
primary_term_start_time:{seconds:1627466189 nanoseconds:587021377}
is_primary_serving:true
```

_global/keyspaces/customer/shards/80-/Shard_

```
primary_alias:{cell:"zone1" uid:400}
primary_term_start_time:{seconds:1627466263 nanoseconds:16201490}
key_range:{start:"\x80"}``
```

_zone1/keyspaces/customer/SrvKeyspace_

```
partitions:{served_type:PRIMARY shard_references:{name:"0"}}

partitions:{served_type:REPLICA
shard_references:{name:"-80" key_range:{end:"\x80"}}
shard_references:{name:"80-" key_range:{start:"\x80"}}
shard_tablet_controls:{name:"0" query_service_disabled:true}
shard_tablet_controls:{name:"-80" key_range:{end:"\x80"}}
shard_tablet_controls:{name:"80-" key_range:{start:"\x80"}}}
```

#### After primary traffic is switched (aka SwitchWrites)

* `is_primary_serving` is removed from shard 0
* `is_primary_serving` is added to shards -80 and 80-
* In the primary partition the shards -80 and 80- are added with associated key ranges
* In the primary partition the key range for shard 0 are removed
* The replica partition is the same as in the previous step

_global/keyspaces/customer/shards/0/Shard_

```
primary_alias:{cell:"zone1" uid:200}
primary_term_start_time:{seconds:1627466636 nanoseconds:405646818}
```

_global/keyspaces/customer/shards/80-/Shard_

```
primary_alias:{cell:"zone1" uid:400}
primary_term_start_time:{seconds:1627466710 nanoseconds:579634511}
key_range:{start:"\x80"}
is_primary_serving:true
```

_zone1/keyspace/customer/SrvKeyspace_

```
partitions:{served_type:PRIMARY
shard_references:{name:"-80" key_range:{end:"\x80"}}
shard_references:{name:"80-"
key_range:{start:"\x80"}}} {name:"0"}

partitions:{served_type:REPLICA
shard_references:{name:"-80" key_range:{end:"\x80"}}
shard_references:{name:"80-" key_range:{start:"\x80"}}}
shard_tablet_controls:{name:"0" query_service_disabled:true}
shard_tablet_controls:{name:"-80" key_range:{end:"\x80"}}
shard_tablet_controls:{name:"80-" key_range:{start:"\x80"}}
```

## What happens when a MoveTables workflow is cutover

#### Before MoveTables is initiated

VSchema for the source keyspace contains the table name, so vtgate routes to that keyspace

#### During MoveTables

Both the source and target now contain the tables and both VSchemas refer to them. However we have routing rules that map the tables for each tablet type from the target keyspace to the other

_global/RoutingRules_

```
rules:{from_table:"customer" to_tables:"commerce.customer"}
rules:{from_table:"customer.customer" to_tables:"commerce.customer"}
rules:{from_table:"customer@replica" to_tables:"commerce.customer"}
rules:{from_table:"customer.customer@replica" to_tables:"commerce.customer"}
```

#### On switching replica traffic to target

The routing rules for replicas are updated to map the table on the source to the target

_global/RoutingRules_

```
rules:{from_table:"customer.customer" to_tables:"commerce.customer"} rules:{from_table:"commerce.customer@replica" to_tables:"customer.customer"}
rules:{from_table:"customer" to_tables:"commerce.customer"}
rules:{from_table:"customer@replica" to_tables:"customer.customer"}
```

#### On switching primary traffic

The routing rules for the primary are updated to map the table on the source to the target. In addition the tables are added to the “denylist” on the source keyspace which vttablet uses to reject writes for tables that have moved. The denylist/routing rules are temporary and can be removed since the moved tables will only appear in the target VSchema

_global/RoutingRules_

```
rules:{from_table:"commerce.customer@replica" to_tables:"customer.customer"}
rules:{from_table:"customer.customer@replica" to_tables:"customer.customer"}
rules:{from_table:"commerce.customer" to_tables:"customer.customer"}
rules:{from_table:"customer" to_tables:"customer.customer"}
```

_global/keyspaces/commerce/shards/0/Shard_

```
primary_alias:{cell:"zone1" uid:100}
primary_term_start_time:{seconds:1627477340 nanoseconds:740407602}
tablet_controls:{tablet_type:PRIMARY denylisted_tables:"customer"}
is_primary_serving:true
```

# Miscellaneous Notes:

* In VReplication workflows, cutovers are performed manually by the user executing the noted `vtctl` commands
* [`SwitchReads`](../../../reference/vreplication/v1/switchreads/) and [`SwitchWrites`](../../../reference/vreplication/v1/switchwrites/) are deprecated terms from the [“v1” workflows](../../../reference/vreplication/v1/) and are now replaced by [`SwitchTraffic`](../../../reference/vreplication/switchtraffic/) and [`ReverseTraffic`](../../../reference/vreplication/reversetraffic/) in the [“v2” workflows](../../../reference/vreplication/) . This section mentions both terms since the nomenclature has changed in recent versions and the v1 names may be more well known.
* The term [`SwitchReads`](../../../reference/vreplication/v1/switchreads/) refers to switching traffic for replica and rdonly tablets. Of course this is by definition read-only traffic. Traffic to the primary tablets is not affected. This is equivalent to [`SwitchTraffic`](../../../reference/vreplication/switchtraffic/) for replica and rdonly tablets (if you do not specify primary as a tablet_type for the [`SwitchTraffic`](../../../reference/vreplication/switchtraffic/) command).
* [`SwitchWrites`](../../../reference/vreplication/v1/switchwrites/) refers to switching all traffic for the primary tablets. Equivalent to [`SwitchTraffic`](../../../reference/vreplication/switchtraffic/) for primary tablet types.
* [`SwitchReads`](../../../reference/vreplication/v1/switchreads/) and [`SwitchWrites`](../../../reference/vreplication/v1/switchwrites/) can also reverse traffic based on the options/parameters provided to them
