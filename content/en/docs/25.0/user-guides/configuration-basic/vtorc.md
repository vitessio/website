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

### Cell Awareness

VTOrc requires the `--cell` flag to specify which cell the VTOrc instance is running in. This flag enables VTOrc to be cell-aware, which is used for cross-cell problem validation. VTOrc validates that the cell exists in the topology. If the cell doesn't exist or the flag is not provided, VTOrc will fail to start with a `FAILED_PRECONDITION` error.

### Skipping recovery actions in specific cells

For a keyspace that spans multiple cells, you can tell VTOrc to leave recovery in certain cells alone with the `--cells-no-recovery` flag. The flag takes a comma-separated list of cell names, for example `--cells-no-recovery zone1,zone2`, and is empty by default, so VTOrc's behavior does not change unless you set it. VTOrc reads it only at startup, so changing or removing the denylist requires restarting VTOrc. This is a denylist on recovery actions only. VTOrc still discovers tablets across all cells and still records detections for cells on the list. You keep full visibility into a cross-cell keyspace even though VTOrc suppresses recovery there.

For a per-tablet analysis, VTOrc skips the recovery action whenever the analyzed tablet's cell is on the list.

VTOrc handles the `ClusterHasNoPrimary` recovery at the shard level rather than per tablet, so it follows a stricter rule. **VTOrc suppresses it only when every cell that has tablets in the shard is on the list; a partial denylist still lets the primary election proceed.** This recovery maps to `PlannedReparentShard`.

At startup, VTOrc validates the listed cells against the cells the topology knows about:

- A listed cell does not exist while the topology is reachable: VTOrc exits at startup.
- The topology is unreachable at startup: VTOrc defers validation and holds all recovery clusterwide until validation succeeds (see the warning below).
- A listed cell is found absent once the topology becomes reachable: VTOrc exits.

{{< warning >}}
**While startup validation is deferred because the topology was unreachable, VTOrc holds all recovery clusterwide — not only in the listed cells.** Every held recovery is recorded under `SkippedRecoveries` with the reason `CellNoRecoveryUnvalidated`, and recovery stays suppressed everywhere until validation succeeds.
{{< /warning >}}

Recoveries that this flag suppresses are counted under the existing `SkippedRecoveries` stat with the reason `CellNoRecovery`, which is how you confirm that the flag is taking effect.

{{< warning >}}
This flag does not stop a replica in a no-recovery cell from being chosen as a promotion candidate during an `EmergencyReparentShard` or reparent triggered elsewhere. If you need to keep a cell's tablets from being promoted, use `--prevent-cross-cell-failover`.
{{< /warning >}}

**Upgrading from `--cells-to-watch`?** If you are upgrading and have set VTOrc's `--cells-to-watch` flag, remove it: VTOrc no longer accepts that flag. `--cells-no-recovery` is not a like-for-like replacement — the removed flag filtered which tablets VTOrc discovered, whereas `--cells-no-recovery` only suppresses recovery actions and leaves discovery unchanged.

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

### Requiring the last known primary position in an emergency reparent

When VTOrc reparents away from a dead primary, its `EmergencyReparentShard` promotes the most advanced replica among those still reachable. ERS ranks the candidates only against each other, so when every replica has lost the same received transactions — for example after a `CHANGE REPLICATION SOURCE TO` or a restart with `relay_log_recovery=1` clears the relay logs — the replicas all look fully caught up, and ERS cannot tell that they are behind the failed primary. The promotion then drops transactions the primary had already acknowledged to clients.

Starting in v25, VTOrc can require that the new primary has received the last position VTOrc saw on the failed primary. VTOrc stores the primary's `gtid_executed` on every successful poll and passes that stored set to ERS as a [required position](../../configuration-advanced/reparenting/#requiring-a-position-on-the-new-primary). If no reachable replica has received it, ERS fails rather than promoting a stale one.

The feature is opt-in and disabled by default. Set `--emergency-reparent-require-primary-position` on VTOrc. VTOrc then passes the stored position to ERS only when all of the following hold:

- **The failed tablet is the primary.** A recovery detected on a replica has no primary position to require.
- **The keyspace [durability policy](../../configuration-basic/durability_policy) uses semi-sync.** Under a policy without semi-sync the primary can hold transactions that no replica received, and that policy accepts their loss, so VTOrc skips the requirement. A semi-sync policy still gets the requirement even if replication had fallen back to asynchronous at the last poll, because clients were told those transactions had committed.
- **VTOrc has a stored position for the primary.** See the limitation below.

{{< warning >}}
**With the requirement enabled, a shard can stop failing over automatically.** If no reachable replica has received the required position, VTOrc promotes none of them: the `EmergencyReparentShard` fails, and the shard has no serving primary until an operator runs `EmergencyReparentShard` by hand. This trades availability for durability — it stops VTOrc from promoting a replica that is missing already-acknowledged transactions.
{{< /warning >}}

VTOrc can require only a position it saw on the primary before the primary failed. It does not keep its stored data across a restart and cannot poll a dead primary, so VTOrc has no stored position if it restarted after the primary failed, or if the primary failed before VTOrc first polled it. In those cases VTOrc runs the reparent **without** the requirement — the same behavior as when the flag is off — and records a warning in the recovery audit. Running more than one VTOrc per shard makes this less likely but does not prevent it, because VTOrc instances do not share stored data and a restarted VTOrc can acquire the shard lock first.

The recovery audit records the outcome either way: the position VTOrc required, or the reason it required none, and the ERS error — including the most advanced positions the replicas had received — when the requirement is not met.

### Running VTOrc using the Vitess Operator

To find information about deploying VTOrc using Vitess Operator please take a look at this [page](../../../reference/vtorc/running_with_vtop).
