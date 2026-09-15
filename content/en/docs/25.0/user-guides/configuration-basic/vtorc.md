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

### Partitioning shard monitoring across instances

By default, every VTOrc instance watches every shard in the topology it is responsible for: it polls each shard's tablets for health and processes their topology events. Running several instances gives you high availability, but not horizontal scale, because each instance still carries the full monitoring workload. That does not hold up for a fleet watching a large number of shards.

The consistent hash ring, added in v25, is an opt-in way to split that work across a pool of VTOrc instances so each instance watches only a subset of shards. You do not have to enumerate keyspaces to divide the work: every instance independently computes the same shard-to-instance mapping, so there is no central coordinator.

A shard's primary owner is the instance at position `FNV-32a(keyspace + "/" + shard) % ring-size`. For high availability, the two ring-adjacent instances also watch the shard (positions wrap around, so the neighbors of position `0` are position `1` and position `ring-size - 1`), so each shard is watched by three instances — its owner plus its two neighbors. If one of those three is unavailable, the other two keep monitoring the shard.

Enable partitioning with `--vtorc-ring-size` and `--vtorc-ring-index`:

| Flag | Default | Description |
|------|---------|-------------|
| `--vtorc-ring-size` | `1` | Total number of VTOrc instances in the ring. `1` disables partitioning, so every instance watches every shard. Set it to `4` or more to partition the work. `2` and `3` are accepted but have no effect (see below). |
| `--vtorc-ring-index` | `0` | This instance's 0-based position in the ring. It must be in the range `[0, ring-size)`. |
| `--vtorc-ring-assignments-file` | `""` | Optional path to a JSON file mapping hash buckets to ring partitions for a more even distribution. Unset by default, which uses direct hash-modulo assignment. VTOrc loads it only when the ring size is `4` or more. |

Sizes of `2` and `3` are accepted but do nothing. Because each shard is watched by its owner and two neighbors, a ring of `2` or `3` makes every instance an owner or neighbor of every shard, so all instances still watch everything. VTOrc logs a warning at those sizes, and partitioning takes effect only at a ring size of `4` or more.

VTOrc reads the ring flags, including the assignments file, only at startup, so changing the ring size, an instance's index, or the assignments file requires restarting VTOrc.

{{< warning >}}
Set the ring flags consistently across the fleet. Keep `--vtorc-ring-size` identical on every instance, and give each instance a distinct `--vtorc-ring-index`. VTOrc does not coordinate these values between instances. Its startup validation checks only that an instance's own `--vtorc-ring-index` falls in `[0, ring-size)`, so it cannot detect that two instances share an index: a duplicate silently skews coverage, with the two instances watching the same segment while another segment goes under-watched. Confirm the distribution through the ring metrics below rather than relying on startup validation to catch a collision. Roll out a ring-size change fleet-wide as well, so every instance converges on the same size. While some instances still run the old size and others the new one, they compute different shard-to-instance mappings, and coverage stays skewed until the sizes match.
{{< /warning >}}

Direct hash-modulo assignment can leave shards distributed unevenly across instances. To even out the distribution, point `--vtorc-ring-assignments-file` at a JSON file that maps hash buckets to ring partitions. The file has this shape:

```json
{
  "num_buckets": 16,
  "bucket_assignments": [0, 0, 0, 0, 1, 1, 1, 2, 2, 2, 3, 3, 3, 3, 3, 3]
}
```

Using more buckets than ring partitions lets you control how many buckets each partition owns — here partition `3` owns six buckets and partition `0` owns four — which smooths out an uneven hash distribution. `num_buckets` must be greater than zero, `bucket_assignments` must have exactly `num_buckets` entries, and every entry must be a partition index in the range `[0, ring-size)`. With a file in place, a shard's owner becomes `bucket_assignments[hash % num_buckets]` rather than `hash % ring-size`.

The ring composes with the `clusters_to_watch` flag rather than replacing it. A shard is monitored only if it falls in this instance's ring segment **and** matches `clusters_to_watch`. At the default ring size of `1`, the ring adds no filter and only `clusters_to_watch` applies, exactly as before.

Ring partitioning is independent of `--cells-no-recovery`: the ring decides which shards this instance watches, while `--cells-no-recovery` governs only whether it acts on recoveries within those shards.

VTOrc validates the ring configuration at startup and fails to start if:

- `--vtorc-ring-size` is less than `1`,
- `--vtorc-ring-index` is outside `[0, ring-size)`, or
- the assignments file is malformed: `num_buckets` is not positive, `bucket_assignments` does not have exactly `num_buckets` entries, or any entry is out of range.

Correct the offending value and restart VTOrc.

The feature is entirely opt-in and off by default: with `--vtorc-ring-size=1` and no assignments file, VTOrc watches every shard exactly as it did before. To disable partitioning after enabling it, set `--vtorc-ring-size` back to `1` and restart; every instance then returns to watching all shards. VTOrc exposes the ring configuration and coverage as [metrics](../../../reference/vtorc/ui_api_metrics): `VtorcRingSize`, `VtorcRingIndex`, and `VtorcRingBuckets` for the ring configuration, and `KeyspaceShardsWatched` for the number of shards this instance watches. Use them to confirm how the work is divided across the fleet.

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
