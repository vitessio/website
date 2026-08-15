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
| `PrimaryTabletUnreachableByQuorum`                                                                                                                       | VTOrc detects that the primary tablet's `vttablet` process is unreachable while its MySQL keeps running, confirmed by a quorum of the shard's replica/rdonly observers. Opt-in and disabled by default; see [below](#failover-of-an-unreachable-primary-vttablet-via-replica-quorum). | VTOrc runs EmergencyReparentShard to elect a different primary |

### Flags

For a full list of supported flags, please look at [VTOrc reference page](../../../reference/programs/vtorc).

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

Starting in v25, VTOrc automatically excludes any tablet started with the `--unmanaged` flag. Such [unmanaged tablets](../../configuration-advanced/unmanaged-tablet) are never probed, analyzed, or repaired by VTOrc, and do not appear in its API, UI, or metrics. Because of this, a `clusters_to_watch` exclusion is no longer required to keep VTOrc away from unmanaged tablets. Independent of this change, unmanaged tablets are always expected to occupy their own keyspace; mixing unmanaged and managed tablets in a single shard is not supported.

### Cell Awareness

VTOrc requires the `--cell` flag to specify which cell the VTOrc instance is running in. This flag enables VTOrc to be cell-aware, which is used for cross-cell problem validation. VTOrc validates that the cell exists in the topology. If the cell doesn't exist or the flag is not provided, VTOrc will fail to start with a `FAILED_PRECONDITION` error.

### Durability Policies

All the failovers that VTOrc performs will be honoring the [durability policies](../../configuration-basic/durability_policy). Please be careful in setting the
desired durability policies for your keyspace because this will affect what situations VTOrc can recover from and what situations will require manual intervention.

### Failover of an unreachable primary `vttablet` via replica quorum

By default, VTOrc decides that a primary is dead largely from the health of its underlying MySQL. If a primary tablet's `vttablet` process becomes unreachable while its `mysqld` keeps running, VTOrc loses its RPC path to the tablet, but the standard dead-primary detection — which keys off MySQL being gone — never fires. The replicas continue replicating from a primary whose control plane is gone, leaving the shard with no serving primary and no automatic recovery.

Starting in v25, VTOrc can optionally run an `EmergencyReparentShard` in this situation. The action is gated by a quorum so that VTOrc never acts on its own connectivity problems alone, such as a network partition between VTOrc and the primary. The failover proceeds only when the primary's `vttablet` is unreachable to VTOrc **and** a quorum of the shard's `REPLICA`/`RDONLY` tablets independently report it unreachable. VTOrc gathers this liveness signal over the existing `Ping` and `FullStatus` RPCs, so the feature introduces no new protocol or service.

The feature is opt-in and disabled by default on both sides:

- On `vttablet`, set `--track-shard-tablet-health` so the tablet periodically pings its shard's current primary and reports the primary's `vttablet` liveness in `FullStatus`. The ping cadence (and per-ping timeout) is controlled by `--shard-tablet-health-interval` (default `1s`).
- On VTOrc, set `--emergency-reparent-on-primary-tablet-unreachable` to act on the quorum. When the conditions are met, VTOrc surfaces a new `PrimaryTabletUnreachableByQuorum` analysis and runs `EmergencyReparentShard`, honoring the same durability policies and ERS controls as any other emergency reparent.

VTOrc's quorum evaluation is tunable:

| Flag | Default | Description |
|------|---------|-------------|
| `--shard-tablet-health-quorum-fraction` | `1.0` | Required fraction of "down" votes among eligible observers to declare the primary unreachable (`1.0` is unanimous). |
| `--shard-tablet-health-quorum-min-observers` | `1` | Minimum number of eligible observers required before a quorum-based emergency reparent may run. At `1`, a single-observer shard relies on that observer plus VTOrc's own check. |
| `--shard-tablet-health-failure-threshold` | `3` | Consecutive shard-peer ping failures before an observer considers the primary down. |
| `--shard-tablet-health-freshness` | `15s` | Maximum age of an observer's report for it to count toward quorum. This must exceed `--instance-poll-time` (ideally 2-3x), since reports only refresh when VTOrc polls each observer. |

A few behaviors are worth keeping in mind:

- **Only crashes fail over, not intentional shutdowns.** A graceful `vttablet` shutdown stamps a shutdown time on the tablet record, and the quorum path fails closed when that time is set. Taking a primary's `vttablet` down deliberately for maintenance therefore never triggers a reparent, even though its peers correctly observe it as unreachable.
- **The quorum is a genuine majority of the shard's tablets.** The denominator is the shard's `REPLICA`/`RDONLY` count from the topology, so unreported replicas — for example, those that are down — still count against the majority gate. For shards with two or more eligible observers, no single flaky report can drive a reparent. A shard whose only eligible observer is one `REPLICA`/`RDONLY` therefore rests on that observer plus VTOrc's own failed check; raise `--shard-tablet-health-quorum-min-observers` if you want quorum ERS to require more than one observer.
- **The old primary's MySQL keeps running.** Because its `vttablet` is the unreachable component, the old primary cannot be demoted until that `vttablet` comes back and discovers the shard has a new primary. As with any emergency reparent away from an unreachable primary, a semi-sync [durability policy](../../configuration-basic/durability_policy) is what prevents the old primary from acknowledging new writes in the meantime. With `none` durability, anything writing directly to the old MySQL (bypassing `vtgate`) could cause a split brain.

Every quorum decision is observable. VTOrc logs why it did or did not fail over an unreachable primary, records the per-observer vote tally in the recovery audit message, and exposes the live per-shard quorum state — the primary, the verdict, and each observer's vote — at the read-only [`/api/shard-tablet-health-quorum`](../../../reference/vtorc/ui_api_metrics) endpoint.

### Running VTOrc using the Vitess Operator

To find information about deploying VTOrc using Vitess Operator please take a look at this [page](../../../reference/vtorc/running_with_vtop).
