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
| | N/A | `ApplyShardRoutingRules` |
| | `CopySchemaShard` | (not yet migrated) |
| | `CreateLookupVindex` | (not yet migrated) |
| | `DeleteShard` | `DeleteShards` |
| | `DeleteTablet` | `DeleteTablets` |
| | `ExecuteFetchAsDba` | `ExecuteFetchAsDBA` |
| | `ExternalizeVindex` | (not yet migrated) |
| | `ListBackups` | `GetBackups` |
| | N/A | `GetFullStatus` |
| | N/A | `GetShardRoutingRules` |
| | `GetShardReplication` | N/A |
| | `GetSrvKeyspace` | `GetSrvKeyspaces` |
| | N/A | `GetSrvVSchemas` |
| | N/A | `GetTabletVersion` |
| | `ListAllTablets`, `ListShardTablets`, `ListTablets` | `GetTablets` |
| | N/A | `GetTopologyPath` |
| | N/A | `GetWorkflows` |
| | `InitShardPrimary` | (deleted) |
| | `Migrate` | (not yet migrated) |
| | `Mount` | (not yet migrated) |
| | `OnlineDDL` | (not yet migrated) |
| | `Ping` | `PingTablet` |
| | N/A | `SetKeyspaceDurabilityPolicy` |
| | `SetReadOnly`, `SetReadWrite` | `SetWritable` |
| | `Sleep` | `SleepTablet` |
| | `TopoCat`, `TopoCp` | N/A |
| | `UpdateSrvKeyspacePartition` | N/A |
| | `UpdateTabletAddrs` | (deleted) |
| | `VReplicationExec` | (not yet migrated) |
| | `ValidatePermissionsKeyspace`, `ValidatePermissionsShard` | N/A |
| | `ValidateSchemaShard` | N/A |
| | `VtctldCommand` | N/A |
| | `WaitForFilteredReplication` | N/A |
| | `Workflow` | N/A |
