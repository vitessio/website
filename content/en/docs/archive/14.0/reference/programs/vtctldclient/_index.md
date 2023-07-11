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
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient AddCellInfo](./vtctldclient_addcellinfo/)	 - Registers a local topology service in a new cell by creating the CellInfo.
* [vtctldclient AddCellsAlias](./vtctldclient_addcellsalias/)	 - Defines a group of cells that can be referenced by a single name (the alias).
* [vtctldclient ApplyRoutingRules](./vtctldclient_applyroutingrules/)	 - Applies the VSchema routing rules.
* [vtctldclient ApplySchema](./vtctldclient_applyschema/)	 - Applies the schema change to the specified keyspace on every primary, running in parallel on all shards. The changes are then propagated to replicas via replication.
* [vtctldclient ApplyVSchema](./vtctldclient_applyvschema/)	 - Applies the VTGate routing schema to the provided keyspace. Shows the result after application.
* [vtctldclient Backup](./vtctldclient_backup/)	 - Uses the BackupStorage service on the given tablet to create and store a new backup.
* [vtctldclient BackupShard](./vtctldclient_backupshard/)	 - Finds the most up-to-date REPLICA, RDONLY, or SPARE tablet in the given shard and uses the BackupStorage service on that tablet to create and store a new backup.
* [vtctldclient ChangeTabletType](./vtctldclient_changetablettype/)	 - Changes the db type for the specified tablet, if possible.
* [vtctldclient CreateKeyspace](./vtctldclient_createkeyspace/)	 - Creates the specified keyspace in the topology.
* [vtctldclient CreateShard](./vtctldclient_createshard/)	 - Creates the specified shard in the topology.
* [vtctldclient DeleteCellInfo](./vtctldclient_deletecellinfo/)	 - Deletes the CellInfo for the provided cell.
* [vtctldclient DeleteCellsAlias](./vtctldclient_deletecellsalias/)	 - Deletes the CellsAlias for the provided alias.
* [vtctldclient DeleteKeyspace](./vtctldclient_deletekeyspace/)	 - Deletes the specified keyspace from the topology.
* [vtctldclient DeleteShards](./vtctldclient_deleteshards/)	 - Deletes the specified shards from the topology.
* [vtctldclient DeleteSrvVSchema](./vtctldclient_deletesrvvschema/)	 - Deletes the SrvVSchema object in the given cell.
* [vtctldclient DeleteTablets](./vtctldclient_deletetablets/)	 - Deletes tablet(s) from the topology.
* [vtctldclient EmergencyReparentShard](./vtctldclient_emergencyreparentshard/)	 - Reparents the shard to the new primary. Assumes the old primary is dead and not responding.
* [vtctldclient ExecuteFetchAsApp](./vtctldclient_executefetchasapp/)	 - Executes the given query as the App user on the remote tablet.
* [vtctldclient ExecuteFetchAsDBA](./vtctldclient_executefetchasdba/)	 - Executes the given query as the DBA user on the remote tablet.
* [vtctldclient ExecuteHook](./vtctldclient_executehook/)	 - Runs the specified hook on the given tablet.
* [vtctldclient FindAllShardsInKeyspace](./vtctldclient_findallshardsinkeyspace/)	 - Returns a map of shard names to shard references for a given keyspace.
* [vtctldclient GetBackups](./vtctldclient_getbackups/)	 - Lists backups for the given shard.
* [vtctldclient GetCellInfo](./vtctldclient_getcellinfo/)	 - Gets the CellInfo object for the given cell.
* [vtctldclient GetCellInfoNames](./vtctldclient_getcellinfonames/)	 - Lists the names of all cells in the cluster.
* [vtctldclient GetCellsAliases](./vtctldclient_getcellsaliases/)	 - Gets all CellsAlias objects in the cluster.
* [vtctldclient GetKeyspace](./vtctldclient_getkeyspace/)	 - Returns information about the given keyspace from the topology.
* [vtctldclient GetKeyspaces](./vtctldclient_getkeyspaces/)	 - Returns information about every keyspace in the topology.
* [vtctldclient GetPermissions](./vtctldclient_getpermissions/)	 - Displays the permissions for a tablet.
* [vtctldclient GetRoutingRules](./vtctldclient_getroutingrules/)	 - Displays the VSchema routing rules.
* [vtctldclient GetSchema](./vtctldclient_getschema/)	 - Displays the full schema for a tablet, optionally restricted to the specified tables/views.
* [vtctldclient GetShard](./vtctldclient_getshard/)	 - Returns information about a shard in the topology.
* [vtctldclient GetSrvKeyspaceNames](./vtctldclient_getsrvkeyspacenames/)	 - Outputs a JSON mapping of cell=>keyspace names served in that cell. Omit to query all cells.
* [vtctldclient GetSrvKeyspaces](./vtctldclient_getsrvkeyspaces/)	 - Returns the SrvKeyspaces for the given keyspace in one or more cells.
* [vtctldclient GetSrvVSchema](./vtctldclient_getsrvvschema/)	 - Returns the SrvVSchema for the given cell.
* [vtctldclient GetSrvVSchemas](./vtctldclient_getsrvvschemas/)	 - Returns the SrvVSchema for all cells, optionally filtered by the given cells.
* [vtctldclient GetTablet](./vtctldclient_gettablet/)	 - Outputs a JSON structure that contains information about the tablet.
* [vtctldclient GetTabletVersion](./vtctldclient_gettabletversion/)	 - Print the version of a tablet from its debug vars.
* [vtctldclient GetTablets](./vtctldclient_gettablets/)	 - Looks up tablets according to filter criteria.
* [vtctldclient GetVSchema](./vtctldclient_getvschema/)	 - Prints a JSON representation of a keyspace's topo record.
* [vtctldclient GetWorkflows](./vtctldclient_getworkflows/)	 - Gets all vreplication workflows (Reshard, MoveTables, etc) in the given keyspace.
* [vtctldclient InitShardPrimary](./vtctldclient_initshardprimary/)	 - Sets the initial primary for the shard.
* [vtctldclient LegacyVtctlCommand](./vtctldclient_legacyvtctlcommand/)	 - Invoke a legacy vtctlclient command. Flag parsing is best effort.
* [vtctldclient PingTablet](./vtctldclient_pingtablet/)	 - Checks that the specified tablet is awake and responding to RPCs. This command can be blocked by other in-flight operations.
* [vtctldclient PlannedReparentShard](./vtctldclient_plannedreparentshard/)	 - Reparents the shard to a new primary, or away from an old primary. Both the old and new primaries must be up and running.
* [vtctldclient RebuildKeyspaceGraph](./vtctldclient_rebuildkeyspacegraph/)	 - Rebuilds the serving data for the keyspace(s). This command may trigger an update to all connected clients.
* [vtctldclient RebuildVSchemaGraph](./vtctldclient_rebuildvschemagraph/)	 - Rebuilds the cell-specific SrvVSchema from the global VSchema objects in the provided cells (or all cells if none provided).
* [vtctldclient RefreshState](./vtctldclient_refreshstate/)	 - Reloads the tablet record on the specified tablet.
* [vtctldclient RefreshStateByShard](./vtctldclient_refreshstatebyshard/)	 - Reloads the tablet record all tablets in the shard, optionally limited to the specified cells.
* [vtctldclient ReloadSchema](./vtctldclient_reloadschema/)	 - Reloads the schema on a remote tablet.
* [vtctldclient ReloadSchemaKeyspace](./vtctldclient_reloadschemakeyspace/)	 - Reloads the schema on all tablets in a keyspace. This is done on a best-effort basis.
* [vtctldclient ReloadSchemaShard](./vtctldclient_reloadschemashard/)	 - Reloads the schema on all tablets in a shard. This is done on a best-effort basis.
* [vtctldclient RemoveBackup](./vtctldclient_removebackup/)	 - Removes the given backup from the BackupStorage used by vtctld.
* [vtctldclient RemoveKeyspaceCell](./vtctldclient_removekeyspacecell/)	 - Removes the specified cell from the Cells list for all shards in the specified keyspace (by calling RemoveShardCell on every shard). It also removes the SrvKeyspace for that keyspace in that cell.
* [vtctldclient RemoveShardCell](./vtctldclient_removeshardcell/)	 - Remove the specified cell from the specified shard's Cells list.
* [vtctldclient ReparentTablet](./vtctldclient_reparenttablet/)	 - Reparent a tablet to the current primary in the shard.
* [vtctldclient RestoreFromBackup](./vtctldclient_restorefrombackup/)	 - Stops mysqld on the specified tablet and restores the data from either the latest backup or closest before `backup-timestamp`.
* [vtctldclient RunHealthCheck](./vtctldclient_runhealthcheck/)	 - Runs a healthcheck on the remote tablet.
* [vtctldclient SetKeyspaceDurabilityPolicy](./vtctldclient_setkeyspacedurabilitypolicy/)	 - Sets the durability-policy used by the specified keyspace.
* [vtctldclient SetShardIsPrimaryServing](./vtctldclient_setshardisprimaryserving/)	 - Add or remove a shard from serving. This is meant as an emergency function. It does not rebuild any serving graphs; i.e. it does not run `RebuildKeyspaceGraph`.
* [vtctldclient SetShardTabletControl](./vtctldclient_setshardtabletcontrol/)	 - Sets the TabletControl record for a shard and tablet type. Only use this for an emergency fix or after a finished MoveTables. The MigrateServedFrom and MigrateServedType commands set this record appropriately already.
* [vtctldclient SetWritable](./vtctldclient_setwritable/)	 - Sets the specified tablet as writable or read-only.
* [vtctldclient ShardReplicationFix](./vtctldclient_shardreplicationfix/)	 - Walks through a ShardReplication object and fixes the first error encountered.
* [vtctldclient ShardReplicationPositions](./vtctldclient_shardreplicationpositions/)	 - 
* [vtctldclient SleepTablet](./vtctldclient_sleeptablet/)	 - Blocks the action queue on the specified tablet for the specified amount of time. This is typically used for testing.
* [vtctldclient SourceShardAdd](./vtctldclient_sourceshardadd/)	 - Adds the SourceShard record with the provided index for emergencies only. It does not call RefreshState for the shard primary.
* [vtctldclient SourceShardDelete](./vtctldclient_sourcesharddelete/)	 - Deletes the SourceShard record with the provided index. This should only be used for emergency cleanup. It does not call RefreshState for the shard primary.
* [vtctldclient StartReplication](./vtctldclient_startreplication/)	 - Starts replication on the specified tablet.
* [vtctldclient StopReplication](./vtctldclient_stopreplication/)	 - Stops replication on the specified tablet.
* [vtctldclient TabletExternallyReparented](./vtctldclient_tabletexternallyreparented/)	 - Updates the topology record for the tablet's shard to acknowledge that an external tool made this tablet the primary.
* [vtctldclient UpdateCellInfo](./vtctldclient_updatecellinfo/)	 - Updates the content of a CellInfo with the provided parameters, creating the CellInfo if it does not exist.
* [vtctldclient UpdateCellsAlias](./vtctldclient_updatecellsalias/)	 - Updates the content of a CellsAlias with the provided parameters, creating the CellsAlias if it does not exist.
* [vtctldclient Validate](./vtctldclient_validate/)	 - Validates that all nodes reachable from the global replication graph, as well as all tablets in discoverable cells, are consistent.
* [vtctldclient ValidateKeyspace](./vtctldclient_validatekeyspace/)	 - Validates that all nodes reachable from the specified keyspace are consistent.
* [vtctldclient ValidateSchemaKeyspace](./vtctldclient_validateschemakeyspace/)	 - Validates that the schema on the primary tablet for shard 0 matches the schema on all other tablets in the keyspace.
* [vtctldclient ValidateShard](./vtctldclient_validateshard/)	 - Validates that all nodes reachable from the specified shard are consistent.
* [vtctldclient ValidateVersionKeyspace](./vtctldclient_validateversionkeyspace/)	 - Validates that the version on the primary tablet of shard 0 matches all of the other tablets in the keyspace.

