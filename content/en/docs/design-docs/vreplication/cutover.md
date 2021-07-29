---
title: Switching Traffic
description: How Vitess records a traffic cutover for Reshard and MoveTables
weight: 30
---

# Changes made to the topo when traffic is switched

This document outlines the steps involved in the cutover process of MoveTables and Reshard workflows when traffic is switched from the source tables/shards to the target tables/shards. We use the resharding flow provided in the local examples and show the relevant snippets from the topo.

Note: Items in italics are topo keys with the values following

## What happens when a Reshard is cutover

For brevity we only show the records for the 80- shard. There will be similar records for the -80 shard.

**Before Resharding, after -80/80- shards are created**

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

**After replica traffic is switched (aka SwitchReads)**

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

**After primary traffic is switched (aka SwitchWrites)**

_global/keyspaces/customer/shards/0/shard_
```
master_alias:{cell:"zone1" uid:200}
master_term_start_time:{seconds:1627466636 nanoseconds:405646818}  
is_master_serving:true
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

**Before MoveTables is initiated**

VSchema for source keyspace contains table name, so vtgate routes to that keyspace

**During MoveTables**

Both source and target now contain the tables and both VSchemas refer to them. However we have routing rules that map the tables for each tablet type from the target keyspace to the other

_global/routingrules_
```
rules:{from_table:"customer" to_tables:"commerce.customer"}
rules:{from_table:"customer.customer" to_tables:"commerce.customer"}
rules:{from_table:"customer@replica" to_tables:"commerce.customer"}
rules:{from_table:"customer.customer@replica" to_tables:"commerce.customer"}
```

**On switching replica traffic to target**

The routing rules for replicas are updated to map the table on source to the target

_global/routingrules_
```
rules:{from_table:"customer.customer" to_tables:"commerce.customer"} rules:{from_table:"commerce.customer@replica" to_tables:"customer.customer"}
rules:{from_table:"customer" to_tables:"commerce.customer"}
rules:{from_table:"customer@replica" to_tables:"customer.customer"}
```

**On switching primary traffic**

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

## Miscellaneous Notes:

* In VReplication workflows cutover is achieved manually by the user
* SwitchReads and SwitchWrites are deprecated terms from the “v1” flows and are now replaced by SwitchTraffic and ReverseTraffic in the “v2” flows. This section mentions both terms since the nomenclature has just recently changed and the v1 names are the ones understood more
* The term SwitchReads it refers to switching traffic for replicas and rdonly tablets. Of course this is by definition read traffic. Traffic to the primary tablets including reads are not affected. Equivalent to SwitchTraffic for replica and rdonly.
* SwitchWrites refers to switching all traffic for the primary tablets. Equivalent to SwitchTraffic for primary
* SwitchReads and SwitchWrites can also reverse traffic based on the options/parameters provided to them
