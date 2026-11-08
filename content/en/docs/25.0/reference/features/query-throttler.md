---
title: Query Throttler
weight: 22
---

VTTablet runs a query throttler that protects tablets from being overloaded by incoming queries. Unlike the [Tablet Throttler](../tablet-throttler/), which manages outgoing operations like VReplication and OnlineDDL, the query throttler manages incoming user queries to prevent database overload.

## Why throttle incoming queries?

When tablets experience high load from incoming queries, they can become overloaded. This can cause:

- **Increased query latency**: High query volume increases query execution times as the database struggles to process all requests.
- **Resource exhaustion**: Too many concurrent queries can consume all available connections, memory, or CPU resources.
- **Cascading failures**: An overloaded tablet can affect replica lag, which impacts the entire shard and can lead to system-wide issues.
- **Degraded user experience**: When tablets are overwhelmed, all users suffer from poor performance instead of just lower-priority workloads.

The query throttler monitors tablet health metrics and selectively rejects queries when the tablet is under stress. This keeps critical queries running with acceptable performance while temporarily rejecting lower-priority traffic.

## How it works

The query throttler evaluates each incoming query before execution. When a configuration is enabled, it:

1. Skips statements that it never throttles. See [Statements that are never throttled](#statements-that-are-never-throttled).
2. Checks the query's priority, set with the `PRIORITY` comment directive.
3. Finds the rules that match the tablet type and the statement type.
4. Compares the current tablet throttler metrics, such as replication lag or load average, with each rule's thresholds.
5. Rejects the configured share of matching queries with a `RESOURCE_EXHAUSTED` error.

The throttler adds minimal overhead in healthy conditions (typically less than 5% latency increase) through fast-path optimization and aggressive caching.

## Strategies

A configuration names the strategy that makes throttling decisions. `TABLET_THROTTLER` is the only strategy you can configure. It throttles queries based on the metrics of a dedicated tablet throttler instance that runs inside each tablet while the query throttler is enabled.

A disabled configuration runs no strategy, and the tablet throttles nothing. A tablet that does not recognize the configured strategy, such as a v24 tablet, falls back to a NoOp strategy that throttles nothing and logs `Unknown strategy ..., using NoOp`.

## Configuration

The query throttler configuration is stored per keyspace in the topology server. Set it with `vtctldclient UpdateQueryThrottlerConfig`, which validates an enabled configuration and writes it to the `Keyspace` record and to each cell's `SrvKeyspace` record:

```shell
vtctldclient UpdateQueryThrottlerConfig --config-file query_throttler.json commerce
```

You can also pass the JSON inline with `--config`. Tablets watch their `SrvKeyspace` record and apply a change as soon as it arrives, without a restart. `vtctldclient GetKeyspace` shows the current configuration, and `vtctldclient GetSrvKeyspaces` shows each cell's copy.

The command replaces the keyspace's whole configuration. To change one rule, pass the full configuration with that change. To disable throttling, pass `{"enabled":false}`, which also removes every rule. To keep the rules while disabling throttling, pass the whole configuration with `"enabled": false`.

If the command can't update some cells, it fails with `UNAVAILABLE` after the `Keyspace` record and the other cells already have the new configuration. Re-run it to update the remaining cells.

### Basic configuration

The following configuration throttles 25% of `INSERT` queries on `PRIMARY` tablets while replication lag is above 10 seconds:

```json
{
  "enabled": true,
  "strategy": "TABLET_THROTTLER",
  "tablet_strategy_config": {
    "tablet_rules": {
      "PRIMARY": {
        "statement_rules": {
          "INSERT": {
            "metric_rules": {
              "lag": {
                "thresholds": [
                  {"above": 10.0, "throttle": 25}
                ]
              }
            }
          }
        }
      }
    }
  }
}
```

Rules are keyed by tablet type under `tablet_rules`, then by statement type under `statement_rules`, then by metric under `metric_rules`. Each metric has a list of thresholds:

- `above`: The metric value above which the threshold applies. It must be a finite number of 0 or more, and each threshold of a metric needs a different `above`.
- `throttle`: The percentage of matching queries to reject, from 0 to 100.

When a metric breaches several thresholds, the highest breached threshold applies. When several metrics of a rule breach a threshold, the highest throttle percentage applies.

### Advanced configuration

You can define several thresholds for graduated throttling, and monitor several metrics:

```json
{
  "enabled": true,
  "strategy": "TABLET_THROTTLER",
  "tablet_strategy_config": {
    "tablet_rules": {
      "PRIMARY": {
        "statement_rules": {
          "INSERT": {
            "metric_rules": {
              "lag": {
                "thresholds": [
                  {"above": 5.0, "throttle": 10},
                  {"above": 15.0, "throttle": 25},
                  {"above": 30.0, "throttle": 50}
                ]
              },
              "threads_running": {
                "thresholds": [
                  {"above": 50, "throttle": 15},
                  {"above": 100, "throttle": 35}
                ]
              }
            }
          },
          "UPDATE": {
            "metric_rules": {
              "lag": {
                "thresholds": [
                  {"above": 10.0, "throttle": 20}
                ]
              }
            }
          }
        }
      },
      "REPLICA": {
        "statement_rules": {
          "SELECT": {
            "metric_rules": {
              "lag": {
                "thresholds": [
                  {"above": 60.0, "throttle": 20}
                ]
              },
              "loadavg": {
                "thresholds": [
                  {"above": 4.0, "throttle": 25},
                  {"above": 8.0, "throttle": 50}
                ]
              }
            }
          }
        }
      }
    }
  }
}
```

This configuration:

- Sets different rules for `PRIMARY` and `REPLICA` tablets
- Uses graduated thresholds, so higher metric values throttle a larger share of queries
- Monitors several metrics (`lag`, `threads_running`, `loadavg`)
- Applies different rules to different statement types (`INSERT`, `UPDATE`, `SELECT`)

### Tablet types and statement types

Rules can name the tablet types `PRIMARY`, `REPLICA`, `RDONLY`, and `EXPERIMENTAL`.

Rules can name the statement types `SELECT`, `INSERT`, `REPLACE`, `UPDATE`, `DELETE`, `DDL`, `SHOW`, `OTHER`, `ANALYZE`, `EXPLAIN`, `FLUSH`, and `CALL_PROC`. A `REPLACE` rule matches only `REPLACE` statements, and an `INSERT` rule doesn't match them. VTTablet's plans, query logs, and metrics still report a `REPLACE` with the `Insert` plan type.

`UpdateQueryThrottlerConfig` refuses rules for other statement types, and tablets ignore them:

- `MIGRATION`, `SET`, and `UNLOCK_TABLES`, because rejecting them would block `ALTER VITESS_MIGRATION ... CANCEL`, session setup, and the `UNLOCK TABLES` that releases a `FLUSH TABLES ... WITH READ LOCK`.
- `SAVEPOINT`, `SAVEPOINT_ROLLBACK`, and `RELEASE`, because they run only inside a transaction, where the query throttler never throttles.

### Supported metrics

The `TABLET_THROTTLER` strategy can monitor the following [Tablet Throttler](../tablet-throttler/) metrics:

- `lag`: Replication lag in seconds
- `threads_running`: MySQL's `Threads_running` status value
- `loadavg`: Load average per core on the tablet server
- `mysqld-loadavg`: Load average per core on the MySQL server
- `mysqld-datadir-used-ratio`: Disk space usage (0.0 to 1.0)
- `history_list_length`: InnoDB's history list length

A rule names a metric bare, such as `lag`, or with a scope, such as `shard/lag` or `self/lag`. The `custom` metric is not supported, and neither are `default`, `self`, and `shard` on their own. A metric can appear in any number of rules, but always spelled the same way, so a configuration can't name both `lag` and `shard/lag`.

A rule whose metric can't be read does not throttle.

### Replication lag on a primary

On a primary, `lag` (or `shard/lag`) is the highest of the primary's own heartbeat lag and the lag of the tablets of the `--throttle-tablet-types` types (default `replica`). On a replica, `lag` is the replica's own lag.

A single lagging replica therefore makes the primary reject queries that match a `PRIMARY` rule on `lag`, for as long as that replica lags. This includes a replica whose replication is stopped for maintenance or broken. The primary leaves a replica out only when it can't probe the replica or read its lag. It also leaves out a replica that doesn't run the query throttler, for example while it isn't serving. VTGate does not retry these rejections. Before maintenance, take the tablet out of the probed types, for example by changing its type to `DRAINED`.

After a reparent, `lag` reads high on every tablet of the shard until the new primary writes its first heartbeat. With the default `--heartbeat-interval` of 1 second, that lasts for the duration of the reparent plus up to about 3 seconds. A rule whose lowest `above` is below that value can reject matching queries for up to one `--query-throttler-cache-update-interval` after a reparent.

### Heartbeats

While a `TABLET_THROTTLER` configuration is enabled, including in dry-run mode, the primary writes a heartbeat every `--heartbeat-interval` (default `1s`), even with the default heartbeat settings or with `--heartbeat-on-demand-duration`. Without these heartbeats, a lapsed on-demand lease would read as replication lag on an idle, healthy shard. Each heartbeat is a row write on the primary and a binary log event that every replica applies.

### Timing

Tablets apply a configuration change as soon as their `SrvKeyspace` watch delivers it. Their throttling decisions, however, use throttler check results that they refresh every `--query-throttler-cache-update-interval` (default `10s`). So throttling starts and stops up to that long after a metric crosses its threshold, plus the time the throttler takes to collect the metric. A tablet that has just enabled a configuration throttles nothing until its first check completes.

If refreshing the check keeps failing, for example because of timeouts, the tablet stops throttling. It does so once its last check result is more than six intervals old.

## Dry-run mode

Set `"dry_run": true` to evaluate the rules and record metrics without rejecting any query. A query that would have been rejected counts in `QueryThrottlerThrottled` with `DryRun` set to `true`, and in `QueryThrottlerTabletStrategyDecisionCount` with the `would_throttle` outcome. The tablet also logs the decisions, at most once every 5 seconds.

Try a new configuration in dry-run mode before you enforce it, especially one with `lag` rules.

## Statements that are never throttled

VTTablet doesn't throttle some statements, because rejecting them would cost more than running them. The query throttler doesn't evaluate them, so dry-run mode doesn't count them either:

- Statements inside a transaction, because VTGate rolls back the whole transaction when one of its statements is rejected. Besides explicit `BEGIN` ... `COMMIT` blocks, this includes:
  - Statements in a session with `autocommit=0`, which is common with ORMs. VTGate opens a transaction at the session's first statement that isn't one of the following: a `SELECT` that names no table, `SET`, `USE`, `PREPARE`, `DEALLOCATE PREPARE`, `SHOW CREATE`, or a `SHOW` statement that reads only server state.
  - DML that VTGate runs in a transaction of its own under autocommit. This includes an `INSERT`, `UPDATE`, or `DELETE` that spans several shards without the `MULTI_SHARD_AUTOCOMMIT` comment directive. It also includes a write to a table with an owned lookup vindex, unless the lookup vindex sets `autocommit=true`.
- Sequence fetches, which VTGate runs outside the user's transaction.
- Statements that take or release an advisory lock, such as `GET_LOCK()`, `RELEASE_LOCK()`, and `RELEASE_ALL_LOCKS()`, so that clients can release their locks while the tablet is overloaded.
- `SELECT` statements that name no table, such as `SELECT SLEEP(1)`. VTGate sends such statements to check a `SET` and to keep connections alive. The exemption depends only on the tables a statement names. It also covers a `SELECT` that names no table but still loads the server, such as one that calls a stored function or `BENCHMARK()`.

Statements that VTGate runs outside the user's transaction, or as autocommit statements of their own, can still be throttled:

- The reads of a lookup vindex with `autocommit=true`, and its inserts when they go to a single shard or the vindex also sets `multi_shard_autocommit=true`. Outside a transaction, VTGate commits the lookup rows before it writes the table, so a rejected single-shard write can leave the lookup rows behind.
- Each shard's part of an `INSERT`, `UPDATE`, or `DELETE` with the `MULTI_SHARD_AUTOCOMMIT` comment directive. A rejection can leave the statement applied on some shards only.

## Priority-based throttling

The query throttler supports priority-based query execution using the `PRIORITY` comment directive. This ensures critical queries are never throttled while allowing lower-priority queries to be throttled more aggressively.

### How priority works

Priority is specified as a value from 0 to 100, with 0 being the highest priority and 100 the lowest. A query's priority scales the share of matching queries that a rule rejects:

- **Priority 0**: Never throttled. Reserved for the most critical queries.
- **Priority 1-99**: Evaluated with a probability equal to the priority value. A query with priority 50 is rejected half as often as a query with priority 100.
- **Priority 100**: Always evaluated for potential throttling.

If no priority is specified, queries default to priority 100.

### Using priority in queries

Specify priority using the `PRIORITY` comment directive:

```sql
SELECT /*vt+ PRIORITY=0 */ * FROM critical_table;
SELECT /*vt+ PRIORITY=50 */ * FROM normal_table;
SELECT /*vt+ PRIORITY=100 */ * FROM batch_table;
```

### Priority evaluation

The throttler uses probabilistic priority checking:

1. Generate a random number between 0 and 99
2. If the random number is less than the query's priority, evaluate throttling rules
3. If the random number is greater than or equal to the priority, allow the query without checking metrics

This means:

- Priority 0 queries always skip throttling (random 0-99 is never < 0)
- Priority 50 queries are checked 50% of the time
- Priority 100 queries are always checked

## Workload classification

The query throttler can track metrics by workload using the `WORKLOAD_NAME` comment directive. This lets you monitor which workloads are being throttled most frequently.

```sql
SELECT /*vt+ WORKLOAD_NAME=analytics */ * FROM large_table;
```

To label the query throttler metrics with workload names, set the `--enable-per-workload-table-metrics` flag on vttablet. Without the flag, the `Workload` label is always `unknown`, which bounds the number of time series. With the flag, a query without a `WORKLOAD_NAME` directive is labeled `unknown`.

## Monitoring

The query throttler emits the following metrics:

- `QueryThrottlerRequests`: Number of queries evaluated by the throttler
- `QueryThrottlerThrottled`: Number of queries that were throttled, or would have been throttled in dry-run mode
- `QueryThrottlerTotalLatencyNs`: Total latency added by the throttler
- `QueryThrottlerEvaluateLatencyNs`: Latency of the throttling decision

These metrics include the `Strategy`, `Workload`, and `Priority` labels. They don't count the statements that the query throttler doesn't evaluate.

The `TABLET_THROTTLER` strategy also exports metrics with the `QueryThrottlerTabletStrategy` prefix, such as `QueryThrottlerTabletStrategyDecisionCount`, which counts decisions by tablet type, statement type, outcome, and reason. The dedicated tablet throttler instance that the strategy checks exports metrics with the `QueryThrottlerDedicated` prefix, such as `QueryThrottlerDedicatedCheckAnyTotal`, separately from the tablet throttler's `Throttler*` metrics. A tablet registers these metrics only once it first enables the query throttler.

See [Query Serving Metrics](../../query-serving/metrics/) for details.

### Inspect the dedicated throttler

`vtctldclient CheckThrottler` and `vtctldclient GetThrottlerStatus` inspect the tablet throttler by default. To inspect the dedicated instance that the query throttler checks, pass `--throttler-type DEDICATED_QUERY_THROTTLER`:

```shell
vtctldclient GetThrottlerStatus --throttler-type DEDICATED_QUERY_THROTTLER zone1-0000000101
```

The dedicated throttler keeps one threshold per metric, the lowest `above` among that metric's rules, and its status shows that threshold. Each rule still applies its own thresholds.

## Error messages

When a query is throttled, VTTablet returns a `RESOURCE_EXHAUSTED` error, which MySQL clients receive through VTGate as `ER_OUT_OF_RESOURCES` (1041). The message names the statement type, workload, priority, the metric that triggered throttling, its current value, the breached threshold, and the throttle percentage:

```
[QueryThrottler] query throttled: stmtType=INSERT workload="unknown" priority=100 metric=lag value=15.23 breached threshold=10.00 throttle=25%
```

VTGate doesn't retry a throttled query. To keep a critical query from being throttled, give it priority 0 with the `PRIORITY` comment directive.

## Upgrading

Upgrade every `vtctld`, `vttablet`, and `vtgate` to v25 before you enable a `TABLET_THROTTLER` configuration. Until every component is upgraded, query throttling can stop without anything reporting it, and `lag` rules can reject queries on a healthy shard. A v24 `vtgate` also returns throttled queries to clients as `ER_TOO_MANY_USER_CONNECTIONS` (1203) rather than 1041. See the [v25.0.0 release notes](https://github.com/vitessio/vitess/blob/main/changelog/25.0/25.0.0/summary.md) for details.

## Differences from tablet throttler

The query throttler differs from the [Tablet Throttler](../tablet-throttler/):

| Feature | Tablet Throttler | Query Throttler |
|---------|------------------|-----------------|
| **Purpose** | Throttles outgoing operations (VReplication, OnlineDDL) | Throttles incoming user queries |
| **What it protects** | Prevents background jobs from overloading the database | Prevents user queries from overloading the database |
| **Default behavior** | Enabled by default | Disabled by default |
| **Configuration** | `vtctldclient UpdateThrottlerConfig` | `vtctldclient UpdateQueryThrottlerConfig` |

Both throttlers can monitor the same set of metrics and can coexist in the same cluster. The query throttler checks a dedicated tablet throttler instance of its own, not the tablet throttler that Online DDL and VReplication use.

## Performance considerations

The query throttler adds minimal overhead:

- **Healthy systems**: Less than 5% latency increase due to fast-path optimization
- **Cache hit rate**: Greater than 95% in normal operations, reducing the need for metric collection
- **Under load**: Graduated throttling (10-50% throttle rates) prevents complete overload while allowing some queries through
- **Priority 0 queries**: Zero throttling overhead, allowing critical queries to bypass all checks

## Best practices

1. **Start in dry-run mode**: Enable a configuration with `"dry_run": true` and watch `QueryThrottlerThrottled` before you enforce it
2. **Use priority carefully**: Reserve priority 0 for truly critical queries only
3. **Set graduated thresholds**: Use multiple threshold levels to gradually increase throttling as metrics worsen
4. **Plan for replica maintenance**: Remove a replica from the probed tablet types before you stop its replication, so `PRIMARY` rules on `lag` don't reject queries
5. **Test in development**: Test throttling configurations in non-production environments first
6. **Combine with workload names**: Use `WORKLOAD_NAME` with `--enable-per-workload-table-metrics` to track which workloads are being throttled most
7. **Adjust thresholds**: Start with conservative thresholds and adjust based on observed behavior

## See also

- [Tablet Throttler](../tablet-throttler/): For throttling outgoing operations
- [Comment Directives](../../../user-guides/configuration-advanced/comment-directives/): For using `PRIORITY` and `WORKLOAD_NAME`
- [Query Serving Metrics](../../query-serving/metrics/): For monitoring throttler behavior
