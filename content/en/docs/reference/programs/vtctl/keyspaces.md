---
title: vtctl Keyspace Command Reference
series: vtctl
---

The following `vtctl` commands are available for administering Keyspaces.

## Commands

### CreateKeyspace
 `CreateKeyspace  [-sharding_column_name=name] [-sharding_column_type=type] [-served_from=tablettype1:ks1,tablettype2:ks2,...] [-force] [-keyspace_type=type] [-base_keyspace=base_keyspace] [-snapshot_time=time] <keyspace name>`

### DeleteKeyspace
 `DeleteKeyspace  [-recursive] <keyspace>`

### RemoveKeyspaceCell
 `RemoveKeyspaceCell  [-force] [-recursive] <keyspace> <cell>`

### GetKeyspace
 `GetKeyspace  <keyspace>`

### GetKeyspaces
 `GetKeyspaces  `

### SetKeyspaceShardingInfo
 `SetKeyspaceShardingInfo  [-force] <keyspace name> [<column name>] [<column type>]`

### SetKeyspaceServedFrom
 `SetKeyspaceServedFrom  [-source=<source keyspace name>] [-remove] [-cells=c1,c2,...] <keyspace name> <tablet type>`

### RebuildKeyspaceGraph
 `RebuildKeyspaceGraph  [-cells=c1,c2,...] <keyspace> ...`

### ValidateKeyspace
 `ValidateKeyspace  [-ping-tablets] <keyspace name>`

### Reshard
 `Reshard  [-skip_schema_copy] <keyspace.workflow> <source_shards> <target_shards>`

### MoveTables
 `MoveTables  [-cell=<cell>] [-tablet_types=<source_tablet_types>] -workflow=<workflow> <source_keyspace> <target_keyspace> <table_specs>`

### DropSources
 `DropSources  [-dry_run] <keyspace.workflow>`

### CreateLookupVindex
 `CreateLookupVindex  [-cell=<cell>] [-tablet_types=<source_tablet_types>] <keyspace> <json_spec>`

### ExternalizeVindex
 `ExternalizeVindex  <keyspace>.<vindex>`

### Materialize
 `Materialize  <json_spec>, example : '{"workflow": "aaa", "source_keyspace": "source", "target_keyspace": "target", "table_settings": [{"target_table": "customer", "source_expression": "select * from customer", "create_ddl": "copy"}]}'`

### SplitClone
 `SplitClone  <keyspace> <from_shards> <to_shards>`

### VerticalSplitClone
 `VerticalSplitClone  <from_keyspace> <to_keyspace> <tables>`

### VDiff
 `VDiff  [-source_cell=<cell>] [-target_cell=<cell>] [-tablet_types=replica] [-filtered_replication_wait_time=30s] <keyspace.workflow>`

### MigrateServedTypes
 `MigrateServedTypes  [-cells=c1,c2,...] [-reverse] [-skip-refresh-state] <keyspace/shard> <served tablet type>`

### MigrateServedFrom
 `MigrateServedFrom  [-cells=c1,c2,...] [-reverse] <destination keyspace/shard> <served tablet type>`

### SwitchReads
 `SwitchReads  [-cells=c1,c2,...] [-reverse] -tablet_type={replica|rdonly} [-dry-run] <keyspace.workflow>`

### SwitchWrites
 `SwitchWrites  [-filtered_replication_wait_time=30s] [-cancel] [-reverse_replication=false] [-dry-run] <keyspace.workflow>`

### CancelResharding
 `CancelResharding  <keyspace/shard>`

### ShowResharding
 `ShowResharding  <keyspace/shard>`

### FindAllShardsInKeyspace
 `FindAllShardsInKeyspace  <keyspace>`

### WaitForDrain
 `WaitForDrain  [-timeout <duration>] [-retry_delay <duration>] [-initial_wait <duration>] <keyspace/shard> <served tablet type>`

## See Also

* [vtctl command index](../../vtctl)
