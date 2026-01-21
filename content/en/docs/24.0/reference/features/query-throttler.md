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

The query throttler evaluates each incoming query before execution. When enabled, it:

1. Checks the query's priority (if specified via the `PRIORITY` comment directive)
2. Determines which throttling strategy to apply based on configuration
3. Evaluates current system metrics (replication lag, load average, running threads, etc.)
4. Makes a decision to allow or reject the query based on configured thresholds
5. Returns a `RESOURCE_EXHAUSTED` error if the query should be throttled

The throttler adds minimal overhead in healthy conditions (typically less than 5% latency increase) through fast-path optimization and aggressive caching.

## Architecture

The query throttler uses a pluggable strategy architecture.

### Strategies

The throttler supports different throttling strategies, which can be selected via configuration:

- **NoOp**: The default strategy. Does not throttle any queries. This is a safe fallback that ensures queries are never blocked if configuration is missing or invalid.
- **TabletThrottler**: A production-ready strategy that uses the existing tablet throttler's metrics to make throttling decisions. This strategy can be configured with detailed rules for different tablet types and SQL statement types.
- **Custom strategies**: The architecture supports custom throttling strategies through a registry system, allowing you to implement your own logic.

### Configuration

The query throttler reads its configuration from the topology server's `SrvKeyspace` record. Storing configuration in the topology server means changes propagate immediately to all tablets in the keyspace, without waiting for periodic refreshes. This also centralizes configuration management and makes changes easier to track and audit.

When vttablet starts, it loads the initial configuration from `SrvKeyspace.QueryThrottlerConfig` and then watches for subsequent changes. Updates are applied automatically without requiring tablet restarts.

### Basic configuration

The throttler uses JSON configuration:

```json
{
  "enabled": true,
  "strategy": "NoOp"
}
```

### TabletThrottler strategy

When using the `TabletThrottler` strategy, you can define rules for different tablet types and SQL statement types:

```json
{
  "enabled": true,
  "strategy": "TabletThrottler",
  "tablet_strategy_config": {
    "tablet_rules": {
      "PRIMARY": {
        "INSERT": {
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
```

This configuration:

- Enables the throttler
- Uses the `TabletThrottler` strategy
- Applies a rule to `PRIMARY` tablets for `INSERT` statements
- When replication lag exceeds 10 seconds, throttles 25% of `INSERT` queries

### Advanced configuration

You can define multiple thresholds for graduated throttling along with monitoring multiple metrics:

```json
{
  "enabled": true,
  "strategy": "TabletThrottler",
  "tablet_strategy_config": {
    "tablet_rules": {
      "PRIMARY": {
        "INSERT": {
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
        },
        "UPDATE": {
          "lag": {
            "thresholds": [
              {"above": 10.0, "throttle": 20}
            ]
          }
        }
      },
      "REPLICA": {
        "SELECT": {
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
```

This configuration:

- Sets different rules for `PRIMARY` and `REPLICA` tablets
- Uses graduated thresholds (higher metric values trigger more aggressive throttling)
- Monitors multiple metrics simultaneously (`lag`, `threads_running`, `loadavg`)
- Applies different rules for different SQL statement types (`INSERT`, `UPDATE`, `SELECT`)

### Supported metrics

The `TabletThrottler` strategy can monitor the same metrics as the [Tablet Throttler](../tablet-throttler/):

- `lag`: Replication lag in seconds
- `threads_running`: MySQL's `Threads_running` status value
- `loadavg`: Load average per core on the tablet server
- `mysqld-loadavg`: Load average per core on the MySQL server
- `custom`: Custom query results
- `mysqld-datadir-used-ratio`: Disk space usage (0.0 to 1.0)
- `history_list_length`: InnoDB's history list length

## Priority-based throttling

The query throttler supports priority-based query execution using the `PRIORITY` comment directive. This ensures critical queries are never throttled while allowing lower-priority queries to be throttled more aggressively.

### How priority works

Priority is specified as a value from 0 to 100, with 0 being the highest priority and 100 the lowest. The value determines whether or not the query is *potentially* throttled based on the current configuration and system state:

- **Priority 0**: Never throttled. Reserved for the most critical queries.
- **Priority 1-99**: Probabilistically throttled based on the priority value. Higher numbers mean it's more likely to be throttled.
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

When combined with the `--enable-per-workload-table-metrics` flag on vttablet, you can track throttling behavior per workload in the `QueryThrottlerRequests` and `QueryThrottlerThrottled` metrics.

## Monitoring

The query throttler emits several metrics:

- `QueryThrottlerRequests`: Total number of queries evaluated by the throttler
- `QueryThrottlerThrottled`: Number of queries that were throttled
- `QueryThrottlerTotalLatencyNs`: Total latency added by throttler evaluation
- `QueryThrottlerEvaluateLatencyNs`: Latency of the throttling decision evaluation

These metrics include labels for:

- `strategy`: The throttling strategy used (`NoOp`, `TabletThrottler`)
- `workload`: The workload name (if specified via `WORKLOAD_NAME` directive)
- `priority`: The query priority (if specified via `PRIORITY` directive)

See [Query Serving Metrics](../../query-serving/metrics/) for details.

## Error messages

When a query is throttled, the query throttler returns a `RESOURCE_EXHAUSTED` error with details about why the query was rejected:

```
vttablet: rpc error: code = ResourceExhausted desc = [VTTabletThrottler] Query throttled: metric=lag value=15.23 breached threshold=10.00 throttle=25%
```

The error message includes:

- The metric that triggered throttling
- The current metric value
- The configured threshold
- The throttle percentage applied

## Differences from tablet throttler

The query throttler differs from the [Tablet Throttler](../tablet-throttler/):

| Feature | Tablet Throttler | Query Throttler |
|---------|------------------|-----------------|
| **Purpose** | Throttles outgoing operations (VReplication, OnlineDDL) | Throttles incoming user queries |
| **What it protects** | Prevents background jobs from overloading the database | Prevents user queries from overloading the database |
| **Default behavior** | Enabled by default | Disabled by default (`NoOp` strategy) |
| **Strategies** | Single strategy | Pluggable strategies (`NoOp`, `TabletThrottler`, or custom) |

Both throttlers can monitor the same set of metrics and can coexist in the same cluster.

## Performance considerations

The query throttler adds minimal overhead:

- **Healthy systems**: Less than 5% latency increase due to fast-path optimization
- **Cache hit rate**: Greater than 95% in normal operations, reducing the need for metric collection
- **Under load**: Graduated throttling (10-50% throttle rates) prevents complete overload while allowing some queries through
- **Priority 0 queries**: Zero throttling overhead, allowing critical queries to bypass all checks

## Best practices

1. **Start with NoOp**: Begin with the `NoOp` strategy to ensure the throttler is working without impacting traffic
2. **Use priority carefully**: Reserve priority 0 for truly critical queries only
3. **Set graduated thresholds**: Use multiple threshold levels to gradually increase throttling as metrics worsen
4. **Monitor metrics**: Watch the `QueryThrottlerRequests` and `QueryThrottlerThrottled` metrics to understand throttling behavior
5. **Test in development**: Test throttling configurations in non-production environments first
6. **Combine with workload names**: Use `WORKLOAD_NAME` to track which workloads are being throttled most
7. **Adjust thresholds**: Start with conservative thresholds and adjust based on observed behavior

## See also

- [Tablet Throttler](../tablet-throttler/): For throttling outgoing operations
- [Comment Directives](../../../user-guides/configuration-advanced/comment-directives/): For using `PRIORITY` and `WORKLOAD_NAME`
- [Query Serving Metrics](../../query-serving/metrics/): For monitoring throttler behavior
