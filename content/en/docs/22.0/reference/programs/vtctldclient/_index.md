---
title: vtctldclient
series: vtctldclient
commit: b0b79813f21f8ecbf409f558ad6f8864332637cf
---
## vtctldclient

Executes a cluster management command on the remote vtctld server.

### Synopsis

Executes a cluster management command on the remote vtctld server.
If there are no running vtctld servers -- for example when bootstrapping
a new Vitess cluster -- you can specify a --server value of 'internal'.
When doing so, you would use the --topo* flags so that the client can
connect directly to the topo server(s).

```
vtctldclient [flags]
```

### Options

```
      --action_timeout duration              timeout to use for the command (default 1h0m0s)
      --compact                              use compact format for otherwise verbose outputs
  -h, --help                                 help for vtctldclient
      --server string                        server to use for the connection (required)
      --topo-global-root string              the path of the global topology data in the global topology server (default "/vitess/global")
      --topo-global-server-address strings   the address of the global topology server(s) (default [localhost:2379])
      --topo-implementation string           the topology implementation to use (default "etcd2")
```

### SEE ALSO

* [vtctldclient AddCellInfo](./vtctldclient_addcellinfo/)	 - Registers a local topology service in a new cell by creating the CellInfo.
* [vtctldclient AddCellsAlias](./vtctldclient_addcellsalias/)	 - Defines a group of cells that can be referenced by a single name (the alias).
* [vtctldclient ApplyKeyspaceRoutingRules](./vtctldclient_applykeyspaceroutingrules/)	 - Applies the provided keyspace routing rules.
* [vtctldclient ApplyRoutingRules](./vtctldclient_applyroutingrules/)	 - Applies the VSchema routing rules.
* [vtctldclient ApplySchema](./vtctldclient_applyschema/)	 - Applies the schema change to the specified keyspace on every primary, running in parallel on all shards. The changes are then propagated to replicas via replication.
* [vtctldclient ApplyShardRoutingRules](./vtctldclient_applyshardroutingrules/)	 - Applies the provided shard routing rules.
* [vtctldclient ApplyVSchema](./vtctldclient_applyvschema/)	 - Applies the VTGate routing schema to the provided keyspace. Shows the result after application.
* [vtctldclient Backup](./vtctldclient_backup/)	 - Uses the BackupStorage service on the given tablet to create and store a new backup.
* [vtctldclient BackupShard](./vtctldclient_backupshard/)	 - Finds the most up-to-date REPLICA, RDONLY, or SPARE tablet in the given shard and uses the BackupStorage service on that tablet to create and store a new backup.
* [vtctldclient ChangeTabletTags](./vtctldclient_changetablettags/)	 - Changes the tablet tags for the specified tablet, if possible.
* [vtctldclient ChangeTabletType](./vtctldclient_changetablettype/)	 - Changes the db type for the specified tablet, if possible.
* [vtctldclient CheckThrottler](./vtctldclient_checkthrottler/)	 - Issue a throttler check on the given tablet.
* [vtctldclient CreateKeyspace](./vtctldclient_createkeyspace/)	 - Creates the specified keyspace in the topology.
* [vtctldclient CreateShard](./vtctldclient_createshard/)	 - Creates the specified shard in the topology.
* [vtctldclient DeleteCellInfo](./vtctldclient_deletecellinfo/)	 - Deletes the CellInfo for the provided cell.
* [vtctldclient DeleteCellsAlias](./vtctldclient_deletecellsalias/)	 - Deletes the CellsAlias for the provided alias.
* [vtctldclient DeleteKeyspace](./vtctldclient_deletekeyspace/)	 - Deletes the specified keyspace from the topology.
* [vtctldclient DeleteShards](./vtctldclient_deleteshards/)	 - Deletes the specified shards from the topology.
* [vtctldclient DeleteSrvVSchema](./vtctldclient_deletesrvvschema/)	 - Deletes the SrvVSchema object in the given cell.
* [vtctldclient DeleteTablets](./vtctldclient_deletetablets/)	 - Deletes tablet(s) from the topology.
* [vtctldclient DistributedTransaction](./vtctldclient_distributedtransaction/)	 - Perform commands on distributed transaction
* [vtctldclient EmergencyReparentShard](./vtctldclient_emergencyreparentshard/)	 - Reparents the shard to the new primary. Assumes the old primary is dead and not responding.
* [vtctldclient ExecuteFetchAsApp](./vtctldclient_executefetchasapp/)	 - Executes the given query as the App user on the remote tablet.
* [vtctldclient ExecuteFetchAsDBA](./vtctldclient_executefetchasdba/)	 - Executes the given query as the DBA user on the remote tablet.
* [vtctldclient ExecuteHook](./vtctldclient_executehook/)	 - Runs the specified hook on the given tablet.
* [vtctldclient ExecuteMultiFetchAsDBA](./vtctldclient_executemultifetchasdba/)	 - Executes given multiple queries as the DBA user on the remote tablet.
* [vtctldclient FindAllShardsInKeyspace](./vtctldclient_findallshardsinkeyspace/)	 - Returns a map of shard names to shard references for a given keyspace.
* [vtctldclient GenerateShardRanges](./vtctldclient_generateshardranges/)	 - Print a set of shard ranges assuming a keyspace with N shards.
* [vtctldclient GetBackups](./vtctldclient_getbackups/)	 - Lists backups for the given shard.
* [vtctldclient GetCellInfo](./vtctldclient_getcellinfo/)	 - Gets the CellInfo object for the given cell.
* [vtctldclient GetCellInfoNames](./vtctldclient_getcellinfonames/)	 - Lists the names of all cells in the cluster.
* [vtctldclient GetCellsAliases](./vtctldclient_getcellsaliases/)	 - Gets all CellsAlias objects in the cluster.
* [vtctldclient GetFullStatus](./vtctldclient_getfullstatus/)	 - Outputs a JSON structure that contains full status of MySQL including the replication information, semi-sync information, GTID information among others.
* [vtctldclient GetKeyspace](./vtctldclient_getkeyspace/)	 - Returns information about the given keyspace from the topology.
* [vtctldclient GetKeyspaceRoutingRules](./vtctldclient_getkeyspaceroutingrules/)	 - Displays the currently active keyspace routing rules.
* [vtctldclient GetKeyspaces](./vtctldclient_getkeyspaces/)	 - Returns information about every keyspace in the topology.
* [vtctldclient GetMirrorRules](./vtctldclient_getmirrorrules/)	 - Displays the VSchema mirror rules.
* [vtctldclient GetPermissions](./vtctldclient_getpermissions/)	 - Displays the permissions for a tablet.
* [vtctldclient GetRoutingRules](./vtctldclient_getroutingrules/)	 - Displays the VSchema routing rules.
* [vtctldclient GetSchema](./vtctldclient_getschema/)	 - Displays the full schema for a tablet, optionally restricted to the specified tables/views.
* [vtctldclient GetShard](./vtctldclient_getshard/)	 - Returns information about a shard in the topology.
* [vtctldclient GetShardReplication](./vtctldclient_getshardreplication/)	 - Returns information about the replication relationships for a shard in the given cell(s).
* [vtctldclient GetShardRoutingRules](./vtctldclient_getshardroutingrules/)	 - Displays the currently active shard routing rules as a JSON document.
* [vtctldclient GetSrvKeyspaceNames](./vtctldclient_getsrvkeyspacenames/)	 - Outputs a JSON mapping of cell=>keyspace names served in that cell. Omit to query all cells.
* [vtctldclient GetSrvKeyspaces](./vtctldclient_getsrvkeyspaces/)	 - Returns the SrvKeyspaces for the given keyspace in one or more cells.
* [vtctldclient GetSrvVSchema](./vtctldclient_getsrvvschema/)	 - Returns the SrvVSchema for the given cell.
* [vtctldclient GetSrvVSchemas](./vtctldclient_getsrvvschemas/)	 - Returns the SrvVSchema for all cells, optionally filtered by the given cells.
* [vtctldclient GetTablet](./vtctldclient_gettablet/)	 - Outputs a JSON structure that contains information about the tablet.
* [vtctldclient GetTabletVersion](./vtctldclient_gettabletversion/)	 - Print the version of a tablet from its debug vars.
* [vtctldclient GetTablets](./vtctldclient_gettablets/)	 - Looks up tablets according to filter criteria.
* [vtctldclient GetThrottlerStatus](./vtctldclient_getthrottlerstatus/)	 - Get the throttler status for the given tablet.
* [vtctldclient GetTopologyPath](./vtctldclient_gettopologypath/)	 - Gets the value associated with the particular path (key) in the topology server.
* [vtctldclient GetVSchema](./vtctldclient_getvschema/)	 - Prints a JSON representation of a keyspace's topo record.
* [vtctldclient GetWorkflows](./vtctldclient_getworkflows/)	 - Gets all vreplication workflows (Reshard, MoveTables, etc) in the given keyspace.
* [vtctldclient LegacyVtctlCommand](./vtctldclient_legacyvtctlcommand/)	 - Invoke a legacy vtctlclient command. Flag parsing is best effort.
* [vtctldclient LookupVindex](./vtctldclient_lookupvindex/)	 - Perform commands related to creating, backfilling, and externalizing Lookup Vindexes using VReplication workflows.
* [vtctldclient Materialize](./vtctldclient_materialize/)	 - Perform commands related to materializing query results from the source keyspace into tables in the target keyspace.
* [vtctldclient Migrate](./vtctldclient_migrate/)	 - Migrate is used to import data from an external cluster into the current cluster.
* [vtctldclient Mount](./vtctldclient_mount/)	 - Mount is used to link an external Vitess cluster in order to migrate data from it.
* [vtctldclient MoveTables](./vtctldclient_movetables/)	 - Perform commands related to moving tables from a source keyspace to a target keyspace.
* [vtctldclient OnlineDDL](./vtctldclient_onlineddl/)	 - Operates on online DDL (schema migrations).
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
* [vtctldclient Reshard](./vtctldclient_reshard/)	 - Perform commands related to resharding a keyspace.
* [vtctldclient RestoreFromBackup](./vtctldclient_restorefrombackup/)	 - Stops mysqld on the specified tablet and restores the data from either the latest backup or closest before `backup-timestamp`.
* [vtctldclient RunHealthCheck](./vtctldclient_runhealthcheck/)	 - Runs a healthcheck on the remote tablet.
* [vtctldclient SetKeyspaceDurabilityPolicy](./vtctldclient_setkeyspacedurabilitypolicy/)	 - Sets the durability-policy used by the specified keyspace.
* [vtctldclient SetShardIsPrimaryServing](./vtctldclient_setshardisprimaryserving/)	 - Add or remove a shard from serving. This is meant as an emergency function. It does not rebuild any serving graphs; i.e. it does not run `RebuildKeyspaceGraph`.
* [vtctldclient SetShardTabletControl](./vtctldclient_setshardtabletcontrol/)	 - Sets the TabletControl record for a shard and tablet type. Only use this for an emergency fix or after a finished MoveTables.
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
* [vtctldclient UpdateThrottlerConfig](./vtctldclient_updatethrottlerconfig/)	 - Update the tablet throttler configuration for all tablets in the given keyspace (across all cells)
* [vtctldclient VDiff](./vtctldclient_vdiff/)	 - Perform commands related to diffing tables involved in a VReplication workflow between the source and target.
* [vtctldclient Validate](./vtctldclient_validate/)	 - Validates that all nodes reachable from the global replication graph, as well as all tablets in discoverable cells, are consistent.
* [vtctldclient ValidateKeyspace](./vtctldclient_validatekeyspace/)	 - Validates that all nodes reachable from the specified keyspace are consistent.
* [vtctldclient ValidateSchemaKeyspace](./vtctldclient_validateschemakeyspace/)	 - Validates that the schema on the primary tablet for shard 0 matches the schema on all other tablets in the keyspace.
* [vtctldclient ValidateShard](./vtctldclient_validateshard/)	 - Validates that all nodes reachable from the specified shard are consistent.
* [vtctldclient ValidateVersionKeyspace](./vtctldclient_validateversionkeyspace/)	 - Validates that the version on the primary tablet of shard 0 matches all of the other tablets in the keyspace.
* [vtctldclient ValidateVersionShard](./vtctldclient_validateversionshard/)	 - Validates that the version on the primary matches all of the replicas.
* [vtctldclient Workflow](./vtctldclient_workflow/)	 - Administer VReplication workflows (Reshard, MoveTables, etc) in the given keyspace.

