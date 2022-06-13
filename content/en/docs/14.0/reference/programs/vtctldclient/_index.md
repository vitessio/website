---
title: vtctldclient
series: vtctldclient
description:
---
## vtctldclient

Executes a cluster management command on the remote vtctld server.

### Options

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
  -h, --help                      help for vtctldclient
      --server string             server to use for connection
```

### SEE ALSO

* [vtctldclient AddCellInfo](vtctldclient_AddCellInfo.md)	 - Registers a local topology service in a new cell by creating the CellInfo.
* [vtctldclient AddCellsAlias](vtctldclient_AddCellsAlias.md)	 - Defines a group of cells that can be referenced by a single name (the alias).
* [vtctldclient ApplyRoutingRules](vtctldclient_ApplyRoutingRules.md)	 - Applies the VSchema routing rules.
* [vtctldclient ApplySchema](vtctldclient_ApplySchema.md)	 - Applies the schema change to the specified keyspace on every primary, running in parallel on all shards. The changes are then propagated to replicas via replication.
* [vtctldclient ApplyVSchema](vtctldclient_ApplyVSchema.md)	 - Applies the VTGate routing schema to the provided keyspace. Shows the result after application.
* [vtctldclient Backup](vtctldclient_Backup.md)	 - Uses the BackupStorage service on the given tablet to create and store a new backup.
* [vtctldclient BackupShard](vtctldclient_BackupShard.md)	 - Finds the most up-to-date REPLICA, RDONLY, or SPARE tablet in the given shard and uses the BackupStorage service on that tablet to create and store a new backup.
* [vtctldclient ChangeTabletType](vtctldclient_ChangeTabletType.md)	 - Changes the db type for the specified tablet, if possible.
* [vtctldclient CreateKeyspace](vtctldclient_CreateKeyspace.md)	 - Creates the specified keyspace in the topology.
* [vtctldclient CreateShard](vtctldclient_CreateShard.md)	 - Creates the specified shard in the topology.
* [vtctldclient DeleteCellInfo](vtctldclient_DeleteCellInfo.md)	 - Deletes the CellInfo for the provided cell.
* [vtctldclient DeleteCellsAlias](vtctldclient_DeleteCellsAlias.md)	 - Deletes the CellsAlias for the provided alias.
* [vtctldclient DeleteKeyspace](vtctldclient_DeleteKeyspace.md)	 - Deletes the specified keyspace from the topology.
* [vtctldclient DeleteShards](vtctldclient_DeleteShards.md)	 - Deletes the specified shards from the topology.
* [vtctldclient DeleteSrvVSchema](vtctldclient_DeleteSrvVSchema.md)	 - Deletes the SrvVSchema object in the given cell.
* [vtctldclient DeleteTablets](vtctldclient_DeleteTablets.md)	 - Deletes tablet(s) from the topology.
* [vtctldclient EmergencyReparentShard](vtctldclient_EmergencyReparentShard.md)	 - 
* [vtctldclient ExecuteFetchAsApp](vtctldclient_ExecuteFetchAsApp.md)	 - Executes the given query as the App user on the remote tablet.
* [vtctldclient ExecuteFetchAsDBA](vtctldclient_ExecuteFetchAsDBA.md)	 - Executes the given query as the DBA user on the remote tablet.
* [vtctldclient ExecuteHook](vtctldclient_ExecuteHook.md)	 - Runs the specified hook on the given tablet.
* [vtctldclient FindAllShardsInKeyspace](vtctldclient_FindAllShardsInKeyspace.md)	 - Returns a map of shard names to shard references for a given keyspace.
* [vtctldclient GetBackups](vtctldclient_GetBackups.md)	 - 
* [vtctldclient GetCellInfo](vtctldclient_GetCellInfo.md)	 - 
* [vtctldclient GetCellInfoNames](vtctldclient_GetCellInfoNames.md)	 - 
* [vtctldclient GetCellsAliases](vtctldclient_GetCellsAliases.md)	 - 
* [vtctldclient GetKeyspace](vtctldclient_GetKeyspace.md)	 - Returns information about the given keyspace from the topology.
* [vtctldclient GetKeyspaces](vtctldclient_GetKeyspaces.md)	 - Returns information about every keyspace in the topology.
* [vtctldclient GetPermissions](vtctldclient_GetPermissions.md)	 - Displays the permissions for a tablet.
* [vtctldclient GetRoutingRules](vtctldclient_GetRoutingRules.md)	 - Displays the VSchema routing rules.
* [vtctldclient GetSchema](vtctldclient_GetSchema.md)	 - Displays the full schema for a tablet, optionally restricted to the specified tables/views.
* [vtctldclient GetShard](vtctldclient_GetShard.md)	 - Returns information about a shard in the topology.
* [vtctldclient GetSrvKeyspaceNames](vtctldclient_GetSrvKeyspaceNames.md)	 - Outputs a JSON mapping of cell=>keyspace names served in that cell. Omit to query all cells.
* [vtctldclient GetSrvKeyspaces](vtctldclient_GetSrvKeyspaces.md)	 - Returns the SrvKeyspaces for the given keyspace in one or more cells.
* [vtctldclient GetSrvVSchema](vtctldclient_GetSrvVSchema.md)	 - Returns the SrvVSchema for the given cell.
* [vtctldclient GetSrvVSchemas](vtctldclient_GetSrvVSchemas.md)	 - Returns the SrvVSchema for all cells, optionally filtered by the given cells.
* [vtctldclient GetTablet](vtctldclient_GetTablet.md)	 - Outputs a JSON structure that contains information about the tablet.
* [vtctldclient GetTabletVersion](vtctldclient_GetTabletVersion.md)	 - Print the version of a tablet from its debug vars.
* [vtctldclient GetTablets](vtctldclient_GetTablets.md)	 - Looks up tablets according to filter criteria.
* [vtctldclient GetVSchema](vtctldclient_GetVSchema.md)	 - Prints a JSON representation of a keyspace's topo record.
* [vtctldclient GetWorkflows](vtctldclient_GetWorkflows.md)	 - 
* [vtctldclient InitShardPrimary](vtctldclient_InitShardPrimary.md)	 - 
* [vtctldclient LegacyVtctlCommand](vtctldclient_LegacyVtctlCommand.md)	 - Invoke a legacy vtctlclient command. Flag parsing is best effort.
* [vtctldclient PingTablet](vtctldclient_PingTablet.md)	 - Checks that the specified tablet is awake and responding to RPCs. This command can be blocked by other in-flight operations.
* [vtctldclient PlannedReparentShard](vtctldclient_PlannedReparentShard.md)	 - 
* [vtctldclient RebuildKeyspaceGraph](vtctldclient_RebuildKeyspaceGraph.md)	 - Rebuilds the serving data for the keyspace(s). This command may trigger an update to all connected clients.
* [vtctldclient RebuildVSchemaGraph](vtctldclient_RebuildVSchemaGraph.md)	 - Rebuilds the cell-specific SrvVSchema from the global VSchema objects in the provided cells (or all cells if none provided).
* [vtctldclient RefreshState](vtctldclient_RefreshState.md)	 - Reloads the tablet record on the specified tablet.
* [vtctldclient RefreshStateByShard](vtctldclient_RefreshStateByShard.md)	 - Reloads the tablet record all tablets in the shard, optionally limited to the specified cells.
* [vtctldclient ReloadSchema](vtctldclient_ReloadSchema.md)	 - Reloads the schema on a remote tablet.
* [vtctldclient ReloadSchemaKeyspace](vtctldclient_ReloadSchemaKeyspace.md)	 - Reloads the schema on all tablets in a keyspace. This is done on a best-effort basis.
* [vtctldclient ReloadSchemaShard](vtctldclient_ReloadSchemaShard.md)	 - Reloads the schema on all tablets in a shard. This is done on a best-effort basis.
* [vtctldclient RemoveBackup](vtctldclient_RemoveBackup.md)	 - Removes the given backup from the BackupStorage used by vtctld.
* [vtctldclient RemoveKeyspaceCell](vtctldclient_RemoveKeyspaceCell.md)	 - Removes the specified cell from the Cells list for all shards in the specified keyspace (by calling RemoveShardCell on every shard). It also removes the SrvKeyspace for that keyspace in that cell.
* [vtctldclient RemoveShardCell](vtctldclient_RemoveShardCell.md)	 - Remove the specified cell from the specified shard's Cells list.
* [vtctldclient ReparentTablet](vtctldclient_ReparentTablet.md)	 - 
* [vtctldclient RestoreFromBackup](vtctldclient_RestoreFromBackup.md)	 - Stops mysqld on the specified tablet and restores the data from either the latest backup or closest before `backup-timestamp`.
* [vtctldclient RunHealthCheck](vtctldclient_RunHealthCheck.md)	 - Runs a healthcheck on the remote tablet.
* [vtctldclient SetKeyspaceDurabilityPolicy](vtctldclient_SetKeyspaceDurabilityPolicy.md)	 - Sets the durability-policy used by the specified keyspace.
* [vtctldclient SetShardIsPrimaryServing](vtctldclient_SetShardIsPrimaryServing.md)	 - Add or remove a shard from serving. This is meant as an emergency function. It does not rebuild any serving graphs; i.e. it does not run `RebuildKeyspaceGraph`.
* [vtctldclient SetShardTabletControl](vtctldclient_SetShardTabletControl.md)	 - Sets the TabletControl record for a shard and tablet type. Only use this for an emergency fix or after a finished MoveTables. The MigrateServedFrom and MigrateServedType commands set this record appropriately already.
* [vtctldclient SetWritable](vtctldclient_SetWritable.md)	 - Sets the specified tablet as writable or read-only.
* [vtctldclient ShardReplicationFix](vtctldclient_ShardReplicationFix.md)	 - Walks through a ShardReplication object and fixes the first error encountered.
* [vtctldclient ShardReplicationPositions](vtctldclient_ShardReplicationPositions.md)	 - 
* [vtctldclient SleepTablet](vtctldclient_SleepTablet.md)	 - Blocks the action queue on the specified tablet for the specified amount of time. This is typically used for testing.
* [vtctldclient SourceShardAdd](vtctldclient_SourceShardAdd.md)	 - Adds the SourceShard record with the provided index for emergencies only. It does not call RefreshState for the shard primary.
* [vtctldclient SourceShardDelete](vtctldclient_SourceShardDelete.md)	 - Deletes the SourceShard record with the provided index. This should only be used for emergency cleanup. It does not call RefreshState for the shard primary.
* [vtctldclient StartReplication](vtctldclient_StartReplication.md)	 - Starts replication on the specified tablet.
* [vtctldclient StopReplication](vtctldclient_StopReplication.md)	 - Stops replication on the specified tablet.
* [vtctldclient TabletExternallyReparented](vtctldclient_TabletExternallyReparented.md)	 - 
* [vtctldclient UpdateCellInfo](vtctldclient_UpdateCellInfo.md)	 - Updates the content of a CellInfo with the provided parameters, creating the CellInfo if it does not exist.
* [vtctldclient UpdateCellsAlias](vtctldclient_UpdateCellsAlias.md)	 - Updates the content of a CellsAlias with the provided parameters, creating the CellsAlias if it does not exist.
* [vtctldclient Validate](vtctldclient_Validate.md)	 - Validates that all nodes reachable from the global replication graph, as well as all tablets in discoverable cells, are consistent.
* [vtctldclient ValidateKeyspace](vtctldclient_ValidateKeyspace.md)	 - Validates that all nodes reachable from the specified keyspace are consistent.
* [vtctldclient ValidateSchemaKeyspace](vtctldclient_ValidateSchemaKeyspace.md)	 - 
* [vtctldclient ValidateShard](vtctldclient_ValidateShard.md)	 - Validates that all nodes reachable from the specified shard are consistent.
* [vtctldclient ValidateVersionKeyspace](vtctldclient_ValidateVersionKeyspace.md)	 - 

