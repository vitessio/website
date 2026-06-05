---
title: VTOrc
weight: 8
---

VTOrc is the automated fault detection and repair tool of Vitess. It started off as a fork of the [Orchestrator](https://github.com/openark/orchestrator), which was then custom-fitted to the Vitess use-case running as a Vitess component.
An overview of the architecture of VTOrc can be found on this [page](../../../reference/vtorc/architecture).

Setting up VTOrc lets you avoid performing the `InitShardPrimary` step. It automatically detects that the new shard doesn't have a primary and elects one for you.
It detects any configuration problems in the cluster and fixes them. Here is the list of things VTOrc can do for you:

| Recovery Name                                                                                                                                            | Description                                                                                                                                                                                                      | Fix that VTOrc does                                            |
|----------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------------------|
| `ClusterHasNoPrimary`                                                                                                                                    | VTOrc detects when a shard doesn't have any primary tablet elected                                                                                                                                               | VTOrc runs PlannedReparentShard to elect a new primary         |
| `DeadPrimary`                                                                                                                                            | VTOrc detects when the primary tablet is dead                                                                                                                                                                    | VTOrc runs EmergencyReparentShard to elect a different primary |
| `IncapacitatedPrimary`                                                                                                                                   | VTOrc detects when the primary tablet is consistently failing health checks but is still network-reachable                                                                                                       | VTOrc runs PlannedReparentShard, falling back to EmergencyReparentShard if that fails |
| `PrimaryIsReadOnly`, `PrimarySemiSyncMustBeSet`, `PrimarySemiSyncMustNotBeSet`                                                                           | VTOrc detects when the primary tablet has configuration issues like being read-only, semi-sync being set or not being set                                                                                        | VTOrc fixes the configurations on the primary.                 |
| `NotConnectedToPrimary`, `ConnectedToWrongPrimary`, `ReplicationStopped`, `ReplicaIsWritable`, `ReplicaSemiSyncMustBeSet`, `ReplicaSemiSyncMustNotBeSet` | VTOrc detects when a replica has configuration issues like not being connected to the primary, connected to the wrong primary, replication stopped, replica being writable, semi-sync being set or not being set | VTOrc fixes the configurations on the replica.                 |
| `StaleTopoPrimary`                                                                                                                                       | VTOrc detects when a tablet still has type PRIMARY in the topology but a newer primary has already been elected. This can happen if a topology update fails during an emergency reparent operation.              | VTOrc demotes the stale primary to a read-only replica, updates its type to REPLICA in the topology, and configures it to replicate from the current primary. |

### Flags

For a full list of supported flags, please look at [VTOrc reference page](../../../reference/command-line-reference/vtorc).

### UI, API and Metrics

For information about the UI, API and metrics that VTOrc exports, please consult this [page](../../../reference/vtorc/ui_api_metrics).

### Example invocation of VTOrc

You can bring VTOrc using the following invocation:

```sh
vtorc --topo-implementation etcd2 \
  --topo-global-server-address "localhost:2379" \
  --topo-global-root /vitess/global \
  --cell zone1 \
  --port 15000 \
  --log-dir=${VTDATAROOT}/tmp \
  --recovery-period-block-duration "10m" \
  --instance-poll-time "1s" \
  --topo-information-refresh-duration "30s" \
  --alsologtostderr
 ```

You can optionally add a `clusters_to_watch` flag that contains a comma separated list of keyspaces or `keyspace/shard` values. If specified, VTOrc will manage only those clusters.

### Cell Awareness

Starting in v24, VTOrc supports the `--cell` flag to specify which cell the VTOrc instance is running in. This flag is optional in v24 but will become required in v25 and later versions.

The `--cell` flag enables VTOrc to be cell-aware, which will be used in future releases for cross-cell problem validation. When specified, VTOrc validates that the cell exists in the topology. If the cell doesn't exist, VTOrc will fail to start. If the flag is not provided in v24, VTOrc will log a warning but continue to operate normally.

### Durability Policies

All the failovers that VTOrc performs will be honoring the [durability policies](../../configuration-basic/durability_policy). Please be careful in setting the
desired durability policies for your keyspace because this will affect what situations VTOrc can recover from and what situations will require manual intervention.

### Running VTOrc using the Vitess Operator

To find information about deploying VTOrc using Vitess Operator please take a look at this [page](../../../reference/vtorc/running_with_vtop).
