---
title: How traffic is switched
description: How Vitess signals traffic cutover for Reshard and MoveTables
weight: 30
---

# Related persistent Vitess objects

## VSchema

A [VSchema](https://vitess.io/docs/concepts/vschema/) allows you to describe how data is organized within keyspaces and shards.

## Shard Info

The `global` key in the topo contains one key per keyspace which then contains one key per shard that has been created within the keyspace. For each shard that is active there is an attribute `is_master_serving` which is set to true. The other shards which have been created but are still not serving this keyspace will not have this attribute set.

## SrvKeyspace

Each cell has a [SrvKeyspace](https://vitess.io/docs/reference/features/topology-service/#srvkeyspace) in the topo per keyspace. For each tablet type (primary/replica) there is one Partition object. The partition object contains all the current shards in the keyspace. The ones which are active have a key range specified for that shard. The ones which are not active have no key ranges set.

Also the primary can contain a `query_service_disabled` attribute which is set to false during resharding cutovers. This tells the primary in that shard to reject any queries made to it, as a signal to vtgate in case vtgate routes queries to this primary during the cutover or before it discovers the new serving graph. OR the `is_master_serving` parameter is set to false for that shard in the corresponding shard info object.

## Routing Rules

[Routing Rules](https://vitess.io/docs/reference/features/schema-routing-rules) are stored in the topo under `global/routingrules`. Routing Rules contain a list of table-specific routes. You can route a table for all or specific tablet types to another table in the same or different keyspace.

# How VTGate routes a query

This section gives a simplified logic used to determine which keyspace and table vtgate will route a simple query of the form `select * from t1 where id = 1` (a _read_ query) or `insert into t1(id, val) values (1,'abc')` (a _write_ query).

* Check to see if t1 has an appropriate routing rule defined. If so, use the specified target table as an alias for t1
* Locate the keyspace for t1 using the VSchema
* For a non-sharded keyspace locate the appropriate tablet (replica or primary) from the SrvKeyspace.
* For a sharded keyspace the SrvKeyspace is used to find the currently active shards. This is done by checking the list of partitions for the specific tablet type selected for the query (replica for reads, primary for writes) and selecting the ones whose `query_service_disabled` is not set and whose `is_master_serving` is set .
* Finally, based on the vindex for the table from the VSchema, the shard for the relevant row is computed based on the keyrange to which the id is mapped to.

# Changes made to the topo when traffic is switched

This document outlines the steps involved in the cutover process of MoveTables and Reshard workflows when traffic is switched from the source tables/shards to the target tables/shards. We use the resharding flow provided in the local examples and show the relevant snippets from the topo for each step in the workflow.

Note: Items in italics are topo keys and the following snippet the value of the key

## What happens when a Reshard is cutover

For brevity we only show the records for the 80- shard. There will be similar records for the -80 shard.

#### Before Resharding, after -80/80- shards are created

Only shard 0 has `is_master_serving` set to true. The SrvKeyspace has only references to 0 for both primary and replica.

_global/keyspaces/customer/shards/0/shard_

```
master_alias:{cell:"zone1" uid:200}
master_term_start_time:{seconds:1627465761 nanoseconds:600070156}
is_master_serving:true
```

_global/keyspaces/customer/shards/80-/shard_

```
master_alias:{cell:"zone1" uid:400}
master_term_start_time:{seconds:1627465833 nanoseconds:536524508}
key_range:{start:"\x80"}
```

_zone1/keyspace/customer/srvkeyspace_

```
partitions:{served_type:MASTER shard_references:{name:"0"}}
partitions:{served_type:REPLICA shard_references:{name:"0"}}
```

### After replica traffic is switched (aka SwitchReads)

Shard 0 still has the `is_master_serving` set as true. The primary partition is still the same.

The replica partition has the following changes:

* Two more shard_references for -80 and 80-
* Key ranges are specified for these shards
* The key range for shard 0 has been removed
* `query_service_disabled` is set to true for shard 0

_global/keyspaces/customer/shards/0/shard_

```
master_alias:{cell:"zone1" uid:200}
master_term_start_time:{seconds:1627466189 nanoseconds:587021377}
is_master_serving:true
```

_global/keyspaces/customer/shards/80-/shard_

```
master_alias:{cell:"zone1" uid:400}
master_term_start_time:{seconds:1627466263 nanoseconds:16201490}
key_range:{start:"\x80"}``
```

_zone1/keyspace/customer/srvkeyspace_

```
partitions:{served_type:MASTER shard_references:{name:"0"}}

partitions:{served_type:REPLICA
shard_references:{name:"-80" key_range:{end:"\x80"}}
shard_references:{name:"80-" key_range:{start:"\x80"}}
shard_tablet_controls:{name:"0" query_service_disabled:true}
shard_tablet_controls:{name:"-80" key_range:{end:"\x80"}}
shard_tablet_controls:{name:"80-" key_range:{start:"\x80"}}}
```

#### After primary traffic is switched (aka SwitchWrites)

* `is_master_serving` is removed from shard 0
* `is_master_serving` is added to shards -80 and 80-
* In the primary partition the shards -80 and 80- are added with associated key ranges
* In the primary partition the key range for shard 0 are removed
* The replica partition is the same as in the previous step

_global/keyspaces/customer/shards/0/shard_

```
master_alias:{cell:"zone1" uid:200}
master_term_start_time:{seconds:1627466636 nanoseconds:405646818}  
```

_global/keyspaces/customer/shards/80-/shard_

```
master_alias:{cell:"zone1" uid:400}
master_term_start_time:{seconds:1627466710 nanoseconds:579634511}
key_range:{start:"\x80"}
is_master_serving:true
```
_zone1/keyspace/customer/srvkeyspace_

```
partitions:{served_type:MASTER
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

VSchema for source keyspace contains table name, so vtgate routes to that keyspace

#### During MoveTables

Both source and target now contain the tables and both VSchemas refer to them. However we have routing rules that map the tables for each tablet type from the target keyspace to the other

_global/routingrules_

```
rules:{from_table:"customer" to_tables:"commerce.customer"}
rules:{from_table:"customer.customer" to_tables:"commerce.customer"}
rules:{from_table:"customer@replica" to_tables:"commerce.customer"}
rules:{from_table:"customer.customer@replica" to_tables:"commerce.customer"}
```

#### On switching replica traffic to target

The routing rules for replicas are updated to map the table on source to the target

_global/routingrules_

```
rules:{from_table:"customer.customer" to_tables:"commerce.customer"} rules:{from_table:"commerce.customer@replica" to_tables:"customer.customer"}
rules:{from_table:"customer" to_tables:"commerce.customer"}
rules:{from_table:"customer@replica" to_tables:"customer.customer"}
```

#### On switching primary traffic

The routing rules for the primary are updated to map the table on source to the target. In addition the tables are added to the “blacklist” on the source keyspace which vttablet uses to reject writes for tables that have moved. The blacklist/routing rules are temporary and can be removed since the moved tables will only appear in the target VSchema

_global/routingrules_

```
rules:{from_table:"commerce.customer@replica" to_tables:"customer.customer"}
rules:{from_table:"customer.customer@replica" to_tables:"customer.customer"}
rules:{from_table:"commerce.customer" to_tables:"customer.customer"}
rules:{from_table:"customer" to_tables:"customer.customer"}
```

_global/keyspaces/commerce/shards/0/shard_

```
master_alias:{cell:"zone1" uid:100}
master_term_start_time:{seconds:1627477340 nanoseconds:740407602}
tablet_controls:{tablet_type:MASTER blacklisted_tables:"customer"}
is_master_serving:true
```

# Miscellaneous Notes:

* In VReplication workflows cutover is achieved manually by the user
* SwitchReads and SwitchWrites are deprecated terms from the “v1” flows and are now replaced by SwitchTraffic and ReverseTraffic in the “v2” flows. This section mentions both terms since the nomenclature has just recently changed and the v1 names are the ones understood more
* The term SwitchReads it refers to switching traffic for replicas and rdonly tablets. Of course this is by definition read traffic. Traffic to the primary tablets including reads are not affected. Equivalent to SwitchTraffic for replica and rdonly.
* SwitchWrites refers to switching all traffic for the primary tablets. Equivalent to SwitchTraffic for primary
* SwitchReads and SwitchWrites can also reverse traffic based on the options/parameters provided to them
