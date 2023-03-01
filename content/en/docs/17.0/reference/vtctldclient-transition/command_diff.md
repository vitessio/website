---
title: Command Diff
weight: 3
---

The following table highlights the main differences in naming between `vtctlclient` and `vtctldclient`.

Unless noted here, command names have a one-to-one mapping between the legacy `vtctlclient` and `vtctldclient`, though output formats may have changed (e.g. `GetKeyspace` now outputs valid JSON).
For stronger guarantees of compatibility, we highly encourage programming directly against the [`VtctldServer` gRPC API][grpc_api_def].

[grpc_api_def]: https://github.com/vitessio/vitess/blob/04870fc27499ac64dcf6050c41fe9c44aea7099c/proto/vtctlservice.proto#L32-L33.

### Command name differences

| | `vtctldclient` command name (NEW) | `vtctlclient` command name (OLD) |
|-|-|-|
| | `ApplyShardRoutingRules` | N/A |
| | `CreateKeyspace` | N/A |
| | (not yet migrated) | `CopySchemaShard` |
| | (not yet migrated) | `CreateLookupVindex` |
| | `DeleteShards` | `DeleteShard` |
| | `DeleteTablets` | `DeleteTablet` |
| | `ExecuteFetchAsDBA` | `ExecuteFetchAsDba` |
| | (not yet migrated) | `ExternalVindex` |
| | `GetBackups` | `ListBackups` |
| | `GetFullStatus` | N/A |
| | `GetShardRoutingRules` | N/A |
| | N/A | `GetShardReplication` |
| | `GetSrvKeyspaces` | `GetSrvKeyspace` |
| | `GetSrvVSchemas` | N/A |
| | `GetTabletVersion` | N/A |
| | `GetTablets` | `ListAllTablets`, `ListShardTablets`, `ListTablets` |
| | `GetTopologyPath` | N/A |
| | `GetWorkflows` | N/A |
| | (deleted) | `InitShardPrimary` |
| | (not yet migrated) | `Migrate` |
| | (not yet migrated) | `Mount` |
| | (not yet migrated) | `OnlineDDL` |
| | `PingTablet` | `Ping` |
| | `SetKeyspaceDurabilityPolicy` | N/A |
| | `SetWritable` | `SetReadOnly`, `SetReadWrite` |
| | `SleepTablet` | `Sleep` |
| | N/A | `TopoCat`, `TopoCp` |
| | N/A | `UpdateSrvKeyspacePartition` |
| | (deleted) | `UpdateTabletAddrs` |
| | (not yet migrated) | `VReplicationExec` |
| | `ValidatePermissionsKeyspace`, `ValidatePermissionsShard` | N/A |
| | `ValidateSchemaShard` | N/A |
| | N/A | `VtctldCommand` |
| | N/A | `WaitForFilteredReplication` |
| | N/A | `Workflow` |
