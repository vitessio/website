---
author: 'Vitess Maintainer Team'
date: 2026-04-30
slug: '2026-04-30-announcing-vitess-24'
tags: [ 'release', 'Vitess', 'v24', 'MySQL', 'kubernetes', 'operator', 'vreplication', 'tracing', 'observability',
        'backup' ]
title: 'Announcing Vitess 24'
description: "Vitess 24 is now Generally Available"
---

# **Announcing Vitess 24**

The Vitess maintainers are happy to announce the release of [version 24.0.0](https://github.com/vitessio/vitess/releases/tag/v24.0.0), along with [version 2.17.0](https://github.com/planetscale/vitess-operator/releases/tag/v2.17.0) of the Vitess Kubernetes Operator.

Version 24.0.0 expands query serving capabilities for sharded keyspaces, modernizes Vitess's observability stack, and introduces faster replica provisioning through native MySQL CLONE support.
The companion v2.17.0 operator release brings significant improvements to scheduled backups, with new cluster- and keyspace-level schedules that make production backup management much easier to configure at scale.
This blog post highlights some of the major changes that went into the release.
For a more detailed description of the release, please refer to the [release notes](https://github.com/vitessio/vitess/releases/tag/v24.0.0) and the [v24.0.0 summary](https://github.com/vitessio/vitess/blob/main/changelog/24.0/24.0.0/summary.md).

---

## Summary

* **Query Serving**: Window function pushdown for sharded keyspaces, view routing rules, tablet targeting via `USE`, and dynamic `JSON_EXTRACT` path arguments
* **VTGate**: GTID-based binlog streaming, a new session-aware balancer mode, and refined replication-lag defaults
* **Observability**: Structured JSON logging, OpenTelemetry tracing, extended Go runtime metrics, and new QueryThrottler metrics
* **Cluster Management & VTOrc**: Ordered recovery execution with safer semi-sync rollouts, a new `--cell` flag, and several deprecations cleared out
* **Backup & Restore**: MySQL CLONE plugin support for fast replica provisioning, plus restore hook improvements
* **VReplication**: Per-shard start/stop control and automatic tablet retry on tablet-specific errors
* **Vitess Kubernetes Operator**: Cluster- and keyspace-level backup schedules, configurable backup methods per schedule, shared PITR binlog storage, Kubernetes 1.35 support

---

## Let's Dive Deeper

### Query Serving

#### Window Function Pushdown for Sharded Keyspaces

Window functions can now be pushed down to individual shards when the `PARTITION BY` clause aligns with a unique vindex.
Previously, all window function queries required single-shard routing, which limited their applicability on sharded tables.
With this change, eligible queries are executed on each shard in parallel, dramatically improving performance and scalability for analytical workloads on sharded data.
See the [MySQL compatibility documentation](https://vitess.io/docs/24.0/reference/compatibility/mysql-compatibility/#window-functions) for examples and details.

#### View Routing Rules

Vitess now supports routing rules for views, applied with `vtctldclient ApplyRoutingRules` the same way as tables.
When a view routing rule is active, VTGate rewrites queries that reference the source view to use the target view's definition instead.
This makes it easier to migrate views between keyspaces or to evolve schemas without coordinating client changes.

View routing rules require schema tracking, so VTGate must be started with `--enable-views` and VTTablet with `--queryserver-enable-views`.
For full details, see the [Schema Routing Rules documentation](https://vitess.io/docs/24.0/reference/features/schema-routing-rules/).

#### Tablet Targeting via `USE`

VTGate now supports routing queries to a specific tablet by alias using an extended `USE` statement:

```sql
USE keyspace:shard@tablet_type|tablet_alias;
```

For example, to target a specific replica tablet:

```sql
USE commerce:-80@replica|zone1-0000000100;
```

Once set, all subsequent queries in the session are routed to the specified tablet until cleared with a standard `USE keyspace` or `USE keyspace@tablet_type` statement.
This is useful for debugging, per-tablet monitoring, cache warming, and other operational tasks where a specific tablet must be targeted.
As with shard targeting, this bypasses vindex-based routing, so it should be used with care.

#### `JSON_EXTRACT` with Dynamic Path Arguments

The `JSON_EXTRACT` function now supports dynamic path arguments such as bind variables or results from other function calls — previously only static string literals were accepted.
NULL handling now matches MySQL behavior: the function returns NULL when either the document or the path argument is NULL.
Static path arguments continue to be optimized, even when mixed with dynamic ones, so existing queries see no performance regression.

### VTGate

#### Binlog Streaming Support

VTGate can now stream GTID-based binlogs to clients through two protocols:

- **MySQL protocol**: Clients can connect using the standard `COM_BINLOG_DUMP_GTID` replication protocol command — no special VStream-aware adapters or direct MySQL access required.
- **gRPC**: A new `BinlogDumpGTID` streaming RPC in `vtgateservice` provides native gRPC access for custom clients without the MySQL protocol dependency.

The feature is disabled by default and is enabled with the new `--enable-binlog-dump` flag.
The `--binlog-dump-authorized-users` flag controls which users may execute binlog dump operations (set to `%` to allow all users).

Each stream operates on a single tablet — there is no aggregation across shards or automatic failover — so this is best suited to point-in-time consumption rather than `MoveTables` or `Reshard` use cases, where the VStream API remains the right tool.

#### Session-Aware Balancer Mode and Replication Lag Defaults

`--vtgate-balancer-mode` now supports a new `session` mode in addition to the existing `cell`, `prefer-cell`, and `random` modes.
Session mode routes each session consistently to the same tablet for the session's duration, which can simplify per-session caching and connection affinity.

`--legacy-replication-lag-algorithm` now defaults to `false`, disabling the legacy approach to handling replication lag by default.
The simpler algorithm based on low lag, high lag, and a minimum number of tablets has proven more stable in production environments.
The legacy behavior can still be re-enabled with `--legacy-replication-lag-algorithm=true`, but the flag will be deprecated in v25 and removed in the following release — see the [tracking issue](https://github.com/vitessio/vitess/issues/18914) for details.

#### Removed `--grpc-send-session-in-streaming` Flag

The deprecated `--grpc-send-session-in-streaming` flag has been removed.
Sessions are now always sent as the last packet in `StreamExecute` and `StreamExecuteMulti` streaming responses, which is required to support transactions in streaming.
Remove any usage of this flag from VTGate startup scripts or configuration before upgrading.

### Observability

#### Structured Logging

Vitess now uses structured JSON logging by default — log output is emitted as JSON to stderr.
Pass `--log-level` (one of `debug`, `info`, `warn`, `error`; default `info`) to configure verbosity, or `--log-format=text` for a human-readable format with automatic color detection.
The legacy `glog` backend remains available via `--log-structured=false`, but `glog` is deprecated as of v24 and will be removed in v25.

#### OpenTelemetry Tracing Support

Vitess now supports [OpenTelemetry](https://opentelemetry.io/) as a tracing backend.
Set `--tracer opentelemetry` on any Vitess binary to enable it; traces are exported via OTLP/gRPC and configured with `--otel-endpoint`, `--otel-insecure`, and `--tracing-sampling-rate`.
Any OTEL-compatible backend (Jaeger v1.35+, Grafana Tempo, Datadog Agent, etc.) can receive these traces.

The existing `opentracing-jaeger` and `opentracing-datadog` tracers are deprecated in v24 and will be removed in v25.
The Jaeger client-go library that backs `opentracing-jaeger` has been archived, and the Jaeger project [recommends migrating to OpenTelemetry](https://www.jaegertracing.io/docs/next-release/getting-started/#migrating-from-jaeger-clients-to-opentelemetry-sdk).
To migrate, replace `--tracer opentracing-jaeger` with `--tracer opentelemetry`, and `--jaeger-agent-host host:port` with `--otel-endpoint host:4317`.

#### QueryThrottler Observability and Configuration

VTTablet now exposes new metrics to track QueryThrottler behavior:

- **`QueryThrottlerRequests`** — total requests evaluated by the throttler
- **`QueryThrottlerThrottled`** — requests that were throttled
- **`QueryThrottlerTotalLatencyNs`** — total time per request in throttling overhead
- **`QueryThrottlerEvaluateLatencyNs`** — time taken to make the throttling decision

All of these are labeled by `Strategy`, `Workload`, and `Priority`, with `QueryThrottlerThrottled` adding `MetricName`, `MetricValue`, and `DryRun` to identify which metric triggered each decision and validate behavior in dry-run mode before changing configuration.

QueryThrottler configuration is also now stored in `SrvKeyspace` in the topology and propagated to tablets via `WatchSrvKeyspace`.
Tablets receive updates immediately rather than polling every 60 seconds, all tablets in a keyspace see configuration changes at roughly the same time, and changes are versioned and auditable through standard topology tools.

#### Extended Go Runtime Metrics

All Vitess components — vtgate, vttablet, vtctld, vtorc, vtbackup, mysqlctld — now expose roughly 150 additional metrics from Go's `runtime/metrics` package via Prometheus.
These cover heap allocation histograms, GC cycle counts and pause histograms, memory class breakdowns, goroutine state breakdowns, scheduler latency histograms, and CPU time by class (user, GC, scavenge, idle).
A new `go_info_ext` gauge with `compiler`, `GOARCH`, and `GOOS` labels is also exposed.
No configuration is required — these metrics appear automatically on the `/metrics` endpoint for all components using the Prometheus backend.

### Cluster Management and VTOrc

VTOrc now executes recoveries per-shard with a defined ordering rather than per-tablet in isolation.
Problems with ordering dependencies — semi-sync configuration in particular — are executed serially first, while independent problems are executed concurrently.
The most visible improvement is in semi-sync rollouts: VTOrc now ensures replicas have semi-sync enabled before updating the primary, avoiding stalls where the primary would otherwise wait on acknowledgements from replicas that were not yet prepared to send them.

A new `--cell` flag has been added to VTOrc, which is optional in v24 but will be required in v25+ (mirroring VTGate's `--cell` flag).
When provided, VTOrc validates that the cell exists in the topology service on startup.
This sets the foundation for cross-cell problem validation in future releases, where VTOrc will be able to ask another cell to validate detected problems before taking recovery actions.
Multi-cell deployments should adopt the flag now to prepare for the v25 requirement.

Several deprecated VTOrc surfaces have been cleaned up in this release:

- The `DiscoverInstanceTimings` metric, deprecated in v23, has been removed. Use `DiscoveryInstanceTimings` instead, which provides the same timing information.
- The `/api/replication-analysis` HTTP endpoint has been removed. Use `/api/detection-analysis`, which accepts the same query parameters and returns the same JSON.
- The Snapshot Topology feature, enabled via `--snapshot-topology-interval`, is deprecated and slated for removal in v25 — see [#18691](https://github.com/vitessio/vitess/issues/18691) for context.

### VReplication

The `start` and `stop` commands for `MoveTables` and `Reshard` workflows now accept a `--shards` flag, allowing operators to start or stop workflows on a specific subset of shards rather than all shards at once:

```bash
# Start workflow on specific shards only
vtctldclient MoveTables --target-keyspace customer --workflow commerce2customer start --shards="-80,80-"

# Stop workflow on specific shards only
vtctldclient Reshard --target-keyspace customer --workflow cust2cust stop --shards="80-"
```

VReplication workflows now automatically retry against different tablets when they hit tablet-specific errors such as binary log purging (MySQL error 1236 or 1789) or GTID set mismatches.
The failing tablet is added to an ignore list and other tablets across all cells are tried; once all matching tablets have been tried, the ignore list is cleared and the workflow retries from scratch.
This is particularly useful in multi-cell deployments where a tablet in the local cell may lack the required binary logs, while tablets in other cells still have them.

### VTTablet

#### Connection Pool Waiter Cap

VTTablet now allows operators to cap the number of requests waiting for a connection from each connection pool, with new flags:

* `--queryserver-config-query-pool-waiter-cap`
* `--queryserver-config-stream-pool-waiter-cap`
* `--queryserver-config-txpool-waiter-cap`

All default to `0` (no limit), preserving the previous behavior.
Setting a cap can help shed load and surface backpressure earlier instead of letting waiter queues grow unbounded under saturation.

#### Experimental `--init-tablet-type-lookup`

The new experimental `--init-tablet-type-lookup` flag allows VTTablet to restore its previous tablet type on restart by looking up the existing topology record, rather than always using the static `--init-tablet-type` value.
This lets tablets keep changed roles (for example, `RDONLY` or `DRAINED`) across restarts without manual reconfiguration.
When the flag is disabled or no topology record exists, the standard `--init-tablet-type` value is used instead.
Note that Vitess Operator–managed deployments generally do not preserve matching tablet records across pod replacements, so this flag has more limited effect in those environments.

### Backup and Restore

#### MySQL CLONE Support for Replica Provisioning

VTTablet and VTBackup now support MySQL's native [CLONE plugin](https://dev.mysql.com/doc/refman/en/clone-plugin.html) to provision new replicas by copying data directly from a donor tablet over the network.
Physical-level data copying is significantly faster than logical backup and restore, particularly for large datasets.
This requires MySQL 8.0.17+ and InnoDB-only tables.

A typical clone-from-primary configuration looks like:

```bash
vttablet \
  --mysql-clone-enabled \
  --restore-with-clone \
  --clone-from-primary \
  ...
```

To clone from a specific tablet, use `--clone-from-tablet=zone1-0000000100` instead of `--clone-from-primary`.
All tablets participating in CLONE operations — both donors and recipients — must have `--mysql-clone-enabled` set during MySQL initialization to ensure the CLONE plugin is loaded and the clone user exists.
Donor authentication is configured with `--db-clone-user`, `--db-clone-password`, and optionally `--db-clone-use-ssl`.

#### Restore Hook Improvements

The `vttablet_restore_done` hook now also fires when restores are triggered via `vtctldclient RestoreFromBackup`; previously it only ran during tablet startup or clone operations.
The hook now also receives a `TM_RESTORE_DATA_BACKUP_ENGINE` environment variable indicating which backup engine produced the restore (`builtin`, `xtrabackup`, etc.), drawn from the manifest's `BackupMethod` field.
The variable is only set when a restore reads from an actual backup — not for clone-based restores or when no backup is used — which lets hook scripts perform engine-specific actions when needed.

### Vitess Kubernetes Operator

Vitess v24.0.0 ships alongside v2.17.0 of the [Vitess Kubernetes Operator](https://github.com/planetscale/vitess-operator/releases/tag/v2.17.0), with a strong focus on improving how scheduled backups are configured and managed.

#### Cluster- and Keyspace-Level Backup Schedules

`VitessBackupSchedule` resources can now be defined at the cluster and keyspace level, rather than requiring each schedule to be configured per-shard.
This makes it dramatically easier to maintain consistent backup policies across large deployments — a single schedule can cover an entire cluster, or apply uniformly to every shard in a keyspace, without per-shard duplication as topology evolves.

#### Per-Schedule Backup Method

`VitessBackupSchedule` now supports a `backupMethod` field, letting operators choose the backup engine (for example `builtin`, `xtrabackup`, or `mysqlshell`) on a schedule-by-schedule basis.
This makes it straightforward to mix different backup strategies for different cadences — for instance, a frequent logical backup plus a less frequent physical backup — without needing to reconfigure the underlying tablets.

#### Shared Storage for PITR Binary Logs

Binary logs used for point-in-time recovery are now placed in a shared directory, so they can be reliably accessed across the pods and processes that participate in PITR workflows.
This addresses a long-standing source of friction for operator users restoring to specific points in time.

#### Other Notable Changes

- **Concurrent backup limit**: A new cap on the maximum number of simultaneously reconciled backups improves operational stability when many backups are scheduled or triggered together.
- **`vtbackup` extra flags**: Operators can now pass arbitrary extra flags through to `vtbackup`, allowing finer-grained tuning of backup behavior without operator changes.
- **Storage-size rolling restart**: VTTablet now triggers a rolling restart automatically when the configured storage size changes, so resize operations propagate without manual intervention.
- **Kubernetes 1.35 support**: The officially supported Kubernetes version has been bumped to v1.35.
- **mysqld_exporter v0.15.0+**: Compatibility has been added for newer `mysqld_exporter` releases.
- **`init_db.sql` synced**: The bundled `init_db.sql` has been synchronized with upstream Vitess.

Please refer to the [operator release notes](https://github.com/planetscale/vitess-operator/releases/tag/v2.17.0) for the full list of changes in v2.17.0.

---

## Breaking Changes

### External Decompressor No Longer Read from Backup `MANIFEST` by Default

The external decompressor command stored in a backup's `MANIFEST` file is no longer used at restore time by default.
Previously, when no `--external-decompressor` flag was provided, VTTablet would fall back to the command specified in the `MANIFEST` — a security risk, since an attacker with write access to backup storage could modify the manifest to execute arbitrary commands on the tablet at restore time.

Starting in v24, the `MANIFEST`-based decompressor is ignored unless you explicitly opt in with the new `--external-decompressor-use-manifest` flag.
If you rely on this behavior, add the flag to your VTTablet configuration, but be aware of the security implications.
See [#19460](https://github.com/vitessio/vitess/pull/19460) for details.

---

### Migrate and Learn More

To ease migration from a previous version to v24.0.0, we highly recommend reviewing the release notes for both [Vitess](https://github.com/vitessio/vitess/releases/tag/v24.0.0) and the [Kubernetes Operator](https://github.com/planetscale/vitess-operator/releases/tag/v2.17.0), along with the [v24.0.0 summary](https://github.com/vitessio/vitess/blob/main/changelog/24.0/24.0.0/summary.md).
The full [changelog](https://github.com/vitessio/vitess/blob/main/changelog/24.0/24.0.0/changelog.md) for this version is available too.

We also encourage you to explore the [v24.0 documentation](https://vitess.io/docs/24.0/), which contains step-by-step user guides, best practices, and tips to make the most of Vitess 24.

### Community

As an open-source project, we truly appreciate feedback, insights, and contributions from our community.
Whether you want to share a story, ask a question, or anything else, you can reach out to us on [GitHub](https://github.com/vitessio/vitess) or in our [Slack](http://vitess.io/slack).

---

*The Vitess Maintainer Team*
