---
title: Command Diff
weight: 3
---

The following table highlights the main differences in naming between `vtctlclient` and `vtctldclient`.

Unless noted here, command names have a one-to-one mapping between the legacy `vtctlclient` and `vtctldclient`, though output formats may have changed (e.g. `GetKeyspace` now outputs valid JSON).
For stronger guarantees of compatibility, we highly encourage programming directly against the [`VtctldServer` gRPC API][grpc_api_def].

[grpc_api_def]: https://github.com/vitessio/vitess/blob/04870fc27499ac64dcf6050c41fe9c44aea7099c/proto/vtctlservice.proto#L32-L33.

### Command name differences

| | `vtctlclient` command name (OLD) | `vtctldclient` command name (NEW) |
|-|-|-|
| | N/A | [`ApplyShardRoutingRules`](../../programs/vtctldclient/vtctldclient_applyroutingrules/) |
| | `CopySchemaShard` | (deleted) |
| | `CreateLookupVindex` | (not yet migrated) |
| | `DeleteShard` | [`DeleteShards`](../../programs/vtctldclient/vtctldclient_deleteshards/) |
| | `DeleteTablet` | [`DeleteTablets`](../../programs/vtctldclient/vtctldclient_deletetablets/) |
| | `ExecuteFetchAsDba` | [`ExecuteFetchAsDBA`](../../programs/vtctldclient/vtctldclient_executefetchasdba/) |
| | `ExternalizeVindex` | (not yet migrated) |
| | `ListBackups` | [`GetBackups`](../../programs/vtctldclient/vtctldclient_getbackups/) |
| | N/A | [`GetFullStatus`](../../programs/vtctldclient/vtctldclient_getfullstatus/) |
| | N/A | [`GetShardRoutingRules`](../../programs/vtctldclient/vtctldclient_getshardroutingrules/) |
| | `GetShardReplication` | [`ShardReplicationPositions`](../../programs/vtctldclient/vtctldclient_shardreplicationpositions/) |
| | `GetSrvKeyspace` | [`GetSrvKeyspaces`](../../programs/vtctldclient/vtctldclient_getsrvkeyspaces/) |
| | N/A | [`GetSrvVSchemas`](../../programs/vtctldclient/vtctldclient_getsrvvschemas/) |
| | N/A | [`GetTabletVersion`](../../programs/vtctldclient/vtctldclient_gettabletversion/) |
| | `ListAllTablets`, `ListShardTablets`, `ListTablets` | [`GetTablets`](../../programs/vtctldclient/vtctldclient_gettablets/) |
| | N/A | [`GetTopologyPath`](../../programs/vtctldclient/vtctldclient_gettopologypath/) |
| | N/A | [`GetWorkflows`](../../programs/vtctldclient/vtctldclient_getworkflows/) |
| | `InitShardPrimary` | (deleted) |
| | `Migrate` | (not yet migrated) |
| | `Mount` | (not yet migrated) |
| | `OnlineDDL` | (not yet migrated) |
| | `Ping` | [`PingTablet`](../../programs/vtctldclient/vtctldclient_pingtablet/) |
| | N/A | [`SetKeyspaceDurabilityPolicy`](../../programs/vtctldclient/vtctldclient_setkeyspacedurabilitypolicy/) |
| | `SetReadOnly`, `SetReadWrite` | [`SetWritable`](../../programs/vtctldclient/vtctldclient_setwritable/) |
| | `Sleep` | [`SleepTablet`](../../programs/vtctldclient/vtctldclient_sleeptablet/) |
| | `TopoCat`, `TopoCp` | (not yet migrated) |
| | `UpdateSrvKeyspacePartition` | (not yet migrated) |
| | `UpdateTabletAddrs` | (deleted) |
| | `VReplicationExec` | (not yet migrated) |
| | `ValidatePermissionsKeyspace`, `ValidatePermissionsShard` | (deleted) |
| | `VtctldCommand` | N/A |
| | `WaitForFilteredReplication` | (deleted) |
| | `Workflow` | (deleted) |
