---
title: Tablet throttler
weight: 21
aliases: ['/docs/user-guides/tablet-throttler/','/docs/reference/tablet-throttler/']
---

VTTablet runs a throttling service (aka _the tablet throttler_), which observes the tablet's and the shard's load. The throttler serves internal flows such as `vreplication,` Online DDL, and others, and can push back if it determines the tablet or the shards are overloaded.

## Why throttling?

Some background jobs such as MoveTables, Materialize, Online DDL, and others, operate on mass amount of data. These involve duplicating and writing entire tables, as well as reading table and binary log data and potentially shipping it between tablets. This all amounts to increased load on the entire shard, that can manifest as one or more of the following:

- Increased replication lag. When faced with mass amount of writes, replicas might find it difficult to keep up with the primary, especially if they need to serve traffic. In such case, they will incur replication lag. Maintaining low replication lag is important in production for two main reasons:

  - A lagging replica may not be representative of the data on the primary. Reads from the replica reflect data that is not consistent with the data on the primary. This is noticeable on web services following read-after-write from the replica, and this can produce results not reflecting the write.
  - In case of a failover, whether planned or unplanned, having an up-to-date replica means a quicker operation. If all replicas are lagging, then a failover process must choose between waiting for a replica to catch up or losing data.

- Increased query contention. Reading/writing mass amounts of data thrashes the database buffer pool as well as the page cache. This both introduces more lock contention, and causes more disk I/O operations when serving production queries. In turn, this leads to query latency. In a snowball effect, this then typically increases the number of concurrent queries, which in turn can increase contention even more.

- Increased OS load. This can manifest as high CPU load, disk I/O saturation, etc.

The background jobs will typically run for a long time, sometimes measured by hours or even days. We acknowledge that these are not as time critical as normal production traffic and choose to de-prioritize them as needed, so as to keep the database or operating system load at reasonable margins.

The throttler is aware of various metrics, collected by all tablets of a shard. The throttler aggregates those metrics from production-facing tablets (normally `PRIMARY` and `REPLICA` tablet types), and compares those metrics with pre-defined thresholds. For example, it might determine that the most lagging replica only lags at `4s`, and below a `5s` pre-defined threshold, thereby deeming the shard to be in good shape as far as lag is concerned. Similarly, the throttler will determine the shard's state based on other metrics.

The throttler will then use these metrics (or some of them) to periodically push back some of the background processes, creating pauses that keep the overall workload within bounds.


## Concepts

### Tablets

The throttler runs as part of the tablet server. The throttler can be disabled or enabled, based on the tablet throttler configuration as part of `Keyspace` in the topo service. All tablets sharing the same keyspace read the same throttler configuration. Thus, all tablet throttlers are all enabled or all disabled, irrespective of shards and tablet types.

Tablets in the same shard collaborate. The `Primary` tablet polls the replica tablets, and replica tablets report and sometimes push throttler notifications to the `Primary`.

However, we limit the collaboration to specific tablet types, based on `--throttle_tablet_types` VTTablet flag. By default, the `Primary` only collaborates with `replica` tablet types, which means tablets such as `backup` do not affect any throttling behavior. The throttler routinely updates the roster of participating tablets.

### Metrics

The objective of the throttler is to push back work based on database load. Previously, this was done based on a single metric, which could be either the replication lag, or the result of a custom query. Now, the throttler collects multiple metrics. The current supported metrics are:

- Replication lag (`lag`), measured in seconds.
- Load average (`loadavg`), per core, on the tablet server/container.
- MySQL `Threads_running` value (`threads_running`).
- Custom query (`custom`) as defined by the user.

This list is expected to expand in the future.

All metrics are `float64` values, and are expected to be non-negative. Metrics are identified by names (`lag`, `loadavg`, etc.)

{{< info >}}
The `v21` throttler supports multi-metrics. Up till `v20`, the throttler would only monitor and operate by a single metric, which is either replication lag or a custom query. With `v21` multiple metrics are being monitored and used at the same time. `v21` and `v20` throttlers are compatible and a shard can run tablets of both versions at the same time.
{{</ info >}}

### Thresholds

A metric value can be _good_ or _bad_. Each metric is assigned a threshold. Below that threshold, the metric is _good_. As of the threshold (equal or higher), the metric is deemed _bad_. The higher the metric, the worse it is.

Each metric has a "factory default" threshold, e.g.:

- `5` (5 seconds) for `lag`.
- `1.0` (per core) for `loadavg`.
- `100` for `threads_running`.

Thresholds are positive values. A threshold of `0` is considered _undefined_.

The user can set their own thresholds, overriding the factory defaults. The user defined thresholds are persisted as part of the throttler configuration under the `Keyspace` entry in the topo service.

### Scopes

We can observe metrics in two scopes: `self`, or `shard`.

Each tablet's throttler collects metrics from its own tablet and from the MySQL server operated by the tablet. Each tablet then refers to those metrics in the `self` scope.

The `Primary` tablet further collects metrics from shard tablets (limited by `throttle_tablet_types` flag as mentioned above). It then uses the maximum (read: worst) value collected, including its own, as the `shard` metric value.

We can therefore refer _scoped_ metrics. On any tablet, we can query for `self` or `shard` metrics:

- `self/loadavg`: the load average on a specific tablet.
- `self/lag`: the lag on a specific tablet. While this makes most sense to query on a replica, it's also an indicative value on the `Primary`. The throttler measures lag using heartbeat injection. In the case of extremely high workload, this value can be indicative of transaction commit latencies.
- `shard/lag`: when querying the `Primary`, this return the highest replication lag across the shard. A replica does not have the collective metrics across the shard, and the value effectively equals `self/lag`.

Each metric has a _default scope_:

- `lag` defaults to `shard` scope.
- All other metrics default to `self` scope.

Querying a `Primary` tablet for the `lag` metric is therefore equal to querying for `shard/lag`, and querying for `threads_running` equals to querying for `self/threads_running`.

For backwards compatibility, it is also possible to query for the `self` or for the `shard` metrics, in which case the result is based on either the `lag` metric (if `custom-query` is undefined) or the `custom` metric (if `custom-query` is defined).

### Apps

A client that connects to the throttler and asks for throttling advice identifies itself as an "app" (legacy term from a previous incarnation). Example apps are VReplication or the Table Lifecycle. Apps identify by name. Examples:

- `vreplication`: any VReplication workflow.
- `tablegc`: table lifecycle.
- `online-ddl`: any Online DDL operation, whether Vitess or `gh-ost`.
- `vplayer`: a submodule of VReplication.
- `schema-tracker`: the internal schema tracker.

Some app names are special:

- `vitess`: used by the throttlers themselves, when the `Primary` checks the shard replicas, or when a throttler checks itself.
- `always-throttled-app`: useful for testing/troubleshooting, an app whose checks the throttler will always reject.
- `test`: used in testing.
- `all`: a catch-all app, used by app rules and app metrics (see below). If defined, it applies to any app that doesn't have any explicit rules/metrics.

Clients can identify by multiple app names, separated with colon. For example, the name `vcopier:d666bbfc_169e_11ef_b0b3_0a43f95f28a3:vreplication:online-ddl` stands for:
- An Online DDL,
- That uses `vreplication` strategy,
- With a `d666bbfc_169e_11ef_b0b3_0a43f95f28a3` workflow ID,
- Currently issuing rowcopy via `vcopier`.

The throttler treats such an app as the combined check of multiple apps, to each it will apply app metric and app rules, as discussed below.

### Checks

A _check_ is a request made to the throttler, asking for go/no-go advice. The check identifies by an app name (defaults `vitess`). The throttler looks at the metrics assigned to the app (see below). If all of them are below their respective thresholds, the throttler accepts the request (returns an OK response). If any of those exceed their respective threshold, the throttler rejects the request (returns a non-OK response).

Checks are made internally by the various vitess components, and the responses are likewise analyzed internally. The user is also able to invoke a check, for automation or troubleshooting purposes. For example:

```shell
$ vtctldclient --server localhost:15999 CheckThrottler --app-name "vreplication" zone1-0000000101  | jq .
```
```json
{
  "status_code": 200,
  "value": 0.607775,
  "threshold": 5,
  "error": "",
  "message": "",
  "recently_checked": true,
  "metrics": {
    "lag": {
      "name": "lag",
      "status_code": 200,
      "value": 0.607775,
      "threshold": 5,
      "error": "",
      "message": "",
      "scope": "shard"
    }
  }
}
```

The response includes:

- Status code (based on HTTP responses, ie `200` for "OK")
- Any error message
- The list of metrics checked; for each metric:
  - Its status code
  - Its threshold
  - The scope it was checked with

## How concepts are combined and used

### Metric thresholds

Each metric is assigned a threshold. Vitess supplies factory defaults for these thresholds, but the user may override them manually, like so:

```shell
$ vtctldclient UpdateThrottlerConfig --metric-name "loadavg" --threshold "2.5" commerce
```

In this example, the `loadavg` metric value is henceforth deemed _good_ if below `2.5`. The threshold is stored as part of the keyspace entry in the topo service:

```shell
$ vtctldclient GetKeyspace commerce | jq .keyspace.throttler_config.metric_thresholds
```
```json
{
  "loadavg": 2.5
}
```
The threshold applies to any check for that specific metric (see App Metrics, below) on any tablet in this keyspace. The value of the metric is also reflected in the throttler status:

```shell
$ vtctldclient GetThrottlerStatus zone1-0000000101  | jq .metric_thresholds
```
```json
{
  "config/loadavg": 2.5,
  "custom": 0,
  "default": 5,
  "lag": 5,
  "loadavg": 2.5,
  "threads_running": 100
}
```

Use a `0` threshold value to restore the threshold back to factory defaults.

### App Metrics

By default, when an app checks the throttler, the result is based on replication lag. If the custom query is set, then the result is based on the custom query result. It is possible to assign specific metrics to specific apps, like so:

```shell
$ vtctldclient UpdateThrottlerConfig --app-name "online-ddl" --app-metrics "lag,threads_running" commerce
```

From that moment on, Online DDL operations will throttle on **both** high `lag` as well as on high `threads_running`. If either these values exceeds its respective threshold, Online DDL gets throttled. However, it's important to note the _scope_ of the metrics, which is left to the defaults here. To elaborate, it is possible to further indicate metric scopes, for example:

```shell
$ vtctldclient UpdateThrottlerConfig --app-name "online-ddl" --app-metrics "lag,threads_running,shard/loadavg" commerce
```

In this example, Online DDL will throttle when:

- The highest `lag` value across all tablets in the shard exceeds the lag threshold (`lag`s default scope is `shard`), or
- The number of `threads_running` on the `Primary` exceeds its threshold (`threads_running`'s default scope is `self`), or
- The highest `loadavg` value in all shard tablets exceeds its threshold (`loadavg`'s default scope is `self`, but the assignment explicitly required `shard` scope).

It's possible to set metrics for the `all` app. Continuing our example setup, we now:
```shell
$ vtctldclient UpdateThrottlerConfig --app-name "all" --app-metrics "lag,custom" commerce
```

Checks made to the throttler by `online-ddl` or any multi-named app such as `vcopier:d666bbfc_169e_11ef_b0b3_0a43f95f28a3:vreplication:online-ddl`, throttle based on `lag,threads_running,shard/loadavg`, because that's an explicit assignment:

```shell
$ vtctldclient CheckThrottler --app-name online-ddl zone1-0000000100  | jq .
```
```json
{
  "status_code": 200,
  "value": 1.473868,
  "threshold": 5,
  "error": "",
  "message": "",
  "recently_checked": true,
  "metrics": {
    "lag": {
      "name": "lag",
      "status_code": 200,
      "value": 1.473868,
      "threshold": 5,
      "error": "",
      "message": "",
      "scope": "shard"
    },
    "loadavg": {
      "name": "loadavg",
      "status_code": 200,
      "value": 0.00375,
      "threshold": 2.5,
      "error": "",
      "message": "",
      "scope": "shard"
    },
    "threads_running": {
      "name": "threads_running",
      "status_code": 200,
      "value": 2,
      "threshold": 100,
      "error": "",
      "message": "",
      "scope": "self"
    }
  }
}
```

Checks made by other apps, e.g. `vreplication`, will now throttle based on `lag,custom`. `vreplication` does not have any assigned metrics, and therefore falls under `all`'s assignments.

```shell
$ vtctldclient --server localhost:15999 CheckThrottler --app-name vreplication zone1-0000000100  | jq .
```
```json
{
  "status_code": 429,
  "value": 20.973689,
  "threshold": 5,
  "error": "threshold exceeded",
  "message": "threshold exceeded",
  "recently_checked": true,
  "metrics": {
    "custom": {
      "name": "custom",
      "status_code": 200,
      "value": 0,
      "threshold": 0,
      "error": "",
      "message": "",
      "scope": "self"
    },
    "lag": {
      "name": "lag",
      "status_code": 429,
      "value": 20.973689,
      "threshold": 5,
      "error": "",
      "message": "threshold exceeded",
      "scope": "shard"
    }
  }
}
```

The assignments are visible in the throttler status:

```shell
$ vtctldclient GetThrottlerStatus zone1-0000000101  | jq .app_checked_metrics
```
```json
{
  "all": "lag,custom",
  "online-ddl": "lag,threads_running,shard/loadavg"
}
```

To deassign metrics from an app, supply an empty value like so:
```shell
$ vtctldclient UpdateThrottlerConfig --app-name "all" --app-metrics "" commerce
```

The special app `vitess` is internally assigned all known metrics, at all times.

### App rules

The user may impose additional throttling rules on any given app. A rule is limited by a duration (after which the rule expires and removed), and can:

- Further rejecting checks based on a rejection ratio (`0.0` for no extra rejection .. `1.0` for complete rejection) before even checking actual metrics/thresholds. This effectively "slows down" the app.
- Or, completely exempt the app: the throttler will always allow the app to proceed irrespective of metric values or assigned app metrics.

Examples:

Throttle `vreplication` app, so that 80% of its checks are denied before even consulting actual metrics. The rule auto-expires after `30` minutes. Note: the rest of 20% checks still need to comply with actual metrics/thresholds.

```shell
$ vtctldclient UpdateThrottlerConfig --throttle-app "vreplication" --throttle-app-ratio "0.8" --throttle-app-duration "30m" commerce
```

Exempt `vreplication` from being throttled, even if metrics exceed their thresholds (e.g. even if `lag` is high). Expire after `1` hour:

```shell
$ vtctldclient UpdateThrottlerConfig --throttle-app "vreplication" --throttle-app-duration "1h" --throttle-app-exempt commerce
```

The `all` app is accepted, and applies to all apps that do not otherwise have a specific rule. Examples:

```shell
$ vtctldclient UpdateThrottlerConfig --throttle-app "all" --throttle-app-ratio "0.25" --throttle-app-duration "1h" commerce
$ vtctldclient UpdateThrottlerConfig --throttle-app "online-ddl" --throttle-app-ratio "0.80" --throttle-app-duration "1h" commerce
```
In the above we push back 25% of checks for all apps, irrespective of actual metrics, except for `online-ddl` checks, where we reject 80% of its checks.

```shell
$ vtctldclient UpdateThrottlerConfig --throttle-app "all" --throttle-app-ratio "0.8" --throttle-app-duration "1h" commerce
$ vtctldclient UpdateThrottlerConfig --throttle-app "vreplication" --throttle-app-duration "1h" --throttle-app-exempt commerce
```

In the above we push back 80% of checks from all apps, except for `vreplication` which is completely exempted.

It is possible to expire (remove the rule) early via:
```shell
$ vtctldclient UpdateThrottlerConfig --unthrottle-app "vreplication" commerce
```

## Commands and flags

These are the `vtctldclient` commands to control or query the tablet throttler:

### UpdateThrottlerConfig

Enable or disable the throttler:

```shell
$ vtctldclient UpdateThrottlerConfig --enable commerce
$ vtctldclient UpdateThrottlerConfig --disable commerce
```

Set a metric threshold:

```shell
$ vtctldclient UpdateThrottlerConfig --metric-name "loadavg" --threshold "2.5" commerce
```
Clear a metric threshold (return to "factory defaults"):
```shell
$ vtctldclient UpdateThrottlerConfig --metric-name "loadavg" --threshold "0" commerce
```

Pre multi-metrics compliant, set the "default" threshold (applies to replication lag if custom query is undefined):
```shell
$ vtctldclient UpdateThrottlerConfig --threshold "10.0" commerce
```

Set a custom query:
```shell
$ vtctldclient UpdateThrottlerConfig --custom-query "show global status like 'Threads_connected'" commerce
```
This applies to the `custom` metric. In pre multi-metric throttlers, checks are validated against the custom value. In multi-metric throttlers, `lag` and `custom` are distinct metrics, and the user may assign different apps to different metrics as described in this doc.

Clear the custom query:
```shell
$ vtctldclient UpdateThrottlerConfig --custom-query "" commerce
```

Assign metrics to an app, use default metric scopes:

```shell
$ vtctldclient UpdateThrottlerConfig --app-name "online-ddl" --app-metrics "lag,threads_running" commerce
```

Assign metrics to an app, use explicit metric scopes:

```shell
$ vtctldclient UpdateThrottlerConfig --app-name "online-ddl" --app-metrics "lag,shard/threads_running" commerce
```

Remove assignment from app:

```shell
$ vtctldclient UpdateThrottlerConfig --app-name "online-ddl" --app-metrics "" commerce
```

Assign metrics to all apps, except for those which have an explicit assignment:

```shell
$ vtctldclient UpdateThrottlerConfig --app-name "all" --app-metrics "lag,shard/loadavg" commerce
```

Throttle an app:
```shell
$ vtctldclient UpdateThrottlerConfig --throttle-app "online-ddl" --throttle-app-ratio "0.80" --throttle-app-duration "1h" commerce
```

Unthrottle an app (expire early):
```shell
$ vtctldclient UpdateThrottlerConfig --unthrottle-app "online-ddl" commerce
```

Exempt an app:

```shell
$ vtctldclient UpdateThrottlerConfig --throttle-app "vreplication" --throttle-app-duration "1h" --throttle-app-exempt commerce
```

Unexempting an app is done by removing the rule:
```shell
$ vtctldclient UpdateThrottlerConfig --unthrottle-app "vreplication" commerce
```

Throttle all apps except those that already have a specific rule:
```shell
$ vtctldclient UpdateThrottlerConfig --throttle-app "all" --throttle-app-ratio=0.25 --throttle-app-duration "1h" commerce
```

### CheckThrottler

Issue a check on a tablet's throttler, optionally identify as some app. Use in automation or in troubleshooting.

Get the response is for a `vreplication` app check:
```shell
$ vtctldclient CheckThrottler --app-name "vreplication" zone1-0000000101
```

Normal checks do not renew heartbeat lease. Override to renew heartbeat lease:
```shell
$ vtctldclient CheckThrottler --app-name "vreplication" --requests-heartbeats zone1-0000000101
```

Check as `vitess` app:
```shell
$ vtctldclient CheckThrottler zone1-0000000101
```

Force a specific scope, overriding metric defaults or assigned metric scopes:
```shell
$ vtctldclient CheckThrottler --app-name "online-ddl" --scope "shard" zone1-0000000101
```

### GetThrottlerStatus

See the state of the throttler, including what the throttles perceives to be current metric values, metrics health, metric thresholds, assigned metrics, app rules, and more.

```shell
$ vtctldclient GetThrottlerStatus zone1-0000000101
```

<details>
  <summary>Response</summary>

```json
{
  "status": {
    "tablet_alias": "zone1-0000000101",
    "keyspace": "commerce",
    "shard": "0",
    "is_leader": true,
    "is_open": true,
    "is_enabled": true,
    "is_dormant": false,
    "lag_metric_query": "select unix_timestamp(now(6))-max(ts/1000000000) as replication_lag from _vt.heartbeat",
    "custom_metric_query": "",
    "default_threshold": 5,
    "metric_name_used_as_default": "lag",
    "aggregated_metrics": {
      "self": {
        "value": 0.826665,
        "error": ""
      },
      "self/custom": {
        "value": 0,
        "error": ""
      },
      "self/lag": {
        "value": 0.826665,
        "error": ""
      },
      "self/loadavg": {
        "value": 0.00625,
        "error": ""
      },
      "self/threads_running": {
        "value": 4,
        "error": ""
      },
      "shard": {
        "value": 0.826665,
        "error": ""
      },
      "shard/custom": {
        "value": 0,
        "error": ""
      },
      "shard/lag": {
        "value": 0.826665,
        "error": ""
      },
      "shard/loadavg": {
        "value": 0.00625,
        "error": ""
      },
      "shard/threads_running": {
        "value": 4,
        "error": ""
      }
    },
    "metric_thresholds": {
      "config/threads_running": 128,
      "custom": 0,
      "default": 5,
      "inventory/custom": 0,
      "inventory/default": 5,
      "inventory/lag": 5,
      "inventory/loadavg": 1,
      "inventory/threads_running": 100,
      "lag": 5,
      "loadavg": 1,
      "threads_running": 128
    },
    "metrics_health": {
      "self": {
        "last_healthy_at": {
          "seconds": "1720619807",
          "nanoseconds": 278074484
        },
        "seconds_since_last_healthy": "0"
      },
      "self/custom": {
        "last_healthy_at": {
          "seconds": "1720619807",
          "nanoseconds": 278024923
        },
        "seconds_since_last_healthy": "0"
      },
      "self/lag": {
        "last_healthy_at": {
          "seconds": "1720619807",
          "nanoseconds": 278040513
        },
        "seconds_since_last_healthy": "0"
      },
      "self/loadavg": {
        "last_healthy_at": {
          "seconds": "1720619807",
          "nanoseconds": 278039563
        },
        "seconds_since_last_healthy": "0"
      },
      "self/threads_running": {
        "last_healthy_at": {
          "seconds": "1720619807",
          "nanoseconds": 278009422
        },
        "seconds_since_last_healthy": "0"
      },
      "shard": {
        "last_healthy_at": {
          "seconds": "1720619807",
          "nanoseconds": 277998192
        },
        "seconds_since_last_healthy": "0"
      },
      "shard/custom": {
        "last_healthy_at": {
          "seconds": "1720619807",
          "nanoseconds": 278065014
        },
        "seconds_since_last_healthy": "0"
      },
      "shard/lag": {
        "last_healthy_at": {
          "seconds": "1720619807",
          "nanoseconds": 278050583
        },
        "seconds_since_last_healthy": "0"
      },
      "shard/loadavg": {
        "last_healthy_at": {
          "seconds": "1720619807",
          "nanoseconds": 278058054
        },
        "seconds_since_last_healthy": "0"
      },
      "shard/threads_running": {
        "last_healthy_at": {
          "seconds": "1720619807",
          "nanoseconds": 278077004
        },
        "seconds_since_last_healthy": "0"
      }
    },
    "throttled_apps": {
      "always-throttled-app": {
        "name": "always-throttled-app",
        "ratio": 1,
        "expires_at": {
          "seconds": "2035968723",
          "nanoseconds": 525835574
        },
        "exempt": false
      }
    },
    "app_checked_metrics": {
      "online-ddl": "lag,loadavg"
    },
    "recently_checked": true,
    "recent_apps": {
      "throttler-stimulator": {
        "checked_at": {
          "seconds": "1720619763",
          "nanoseconds": 589916194
        },
        "status_code": 200
      },
      "vcopier:408d0dab_3db6_11ef_b8a5_0a43f95f28a3:vreplication:online-ddl": {
        "checked_at": {
          "seconds": "1720619807",
          "nanoseconds": 220079844
        },
        "status_code": 200
      },
      "vitess": {
        "checked_at": {
          "seconds": "1720619807",
          "nanoseconds": 278086004
        },
        "status_code": 200
      }
    }
  }
}
```
</details>

### GetKeyspace

The throttler configuration is stored as part of the `Keyspace` or `SrvKeyspace`, and can be read via `vtctldclient GetKeyspace` or `vtctldclient GetSrvKeyspace` commands:

```shell
$ vtctldclient GetKeyspace commerce | jq .keyspace.throttler_config
```
```json
{
  "enabled": true,
  "threshold": 0,
  "custom_query": "",
  "check_as_check_self": false,
  "throttled_apps": {
    "online-ddl": {
      "name": "online-ddl",
      "ratio": 0,
      "expires_at": {
        "seconds": "0",
        "nanoseconds": 0
      },
      "exempt": false
    }
  },
  "app_checked_metrics": {
    "online-ddl": {
      "names": [
        "lag",
        "loadavg"
      ]
    }
  },
  "metric_thresholds": {
    "threads_running": 128
  }
}
```

## Additional notes

### Throttler operation

- Each tablet owns its own metrics (the `self` scope).
- In addition, the shard's `PRIMARY` is responsible for collecting metrics from all shard's tablet.
- The throttler begins in dormant probe mode. As long as no application or client is actually looking for metrics, it probes the servers at multi-second intervals.
- When applications check for throttle advice, the throttler begins probing servers in subsecond intervals. It reverts to dormant probe mode if no requests are made in the duration of `1min`.
- The throttler aggregates the last probed values from all relevant tablets, and considers the _highest_ (worst) value to be the `shard` scope value.

The cluster's metric is only as accurate as the following metrics:

- The probe interval and latency.
- For the lag metric, the heartbeat injection interval.
- The aggregation interval.

Combined, these normally total a subsecond value, which is deemed accurate enough.

{{< info >}}
It does not make much sense to use a lag threshold like `1s` due to the above resolution.
As a general guideline, it is also not useful to set the lag threshold above `30s` for operational reasons (Online DDL cut-over, plannet reparents, etc.)
{{</ info >}}

### Response codes

Throttler returns one of the following HTTP response codes in a check response:

- `200` (OK): The application may write to the data store. This is the desired response.
- `404` (Not Found): The check contains an unknown metric name. This can take place immediately upon startup or immediately after failover, and should resolve within 10 seconds.
- `417` (Expectation Failed): The requesting application is explicitly forbidden to write. The throttler does not implement this at this time.
- `429` (Too Many Requests): Do not write. A normal, expected state indicating there is replication lag. This is the hint for applications or clients to withhold writes.
- `500` (Internal Server Error): An internal error has occurred. Do not write.

### The custom query

The custom query can be either:

- A `show global status like '<var>'` that returns a single value.
- A `select` query with a single row, single column numeric result.

### Exempting apps

Exempting app should be done with caution. When an app is exempted, it had no controls and can negatively impact the shard's health. Moreover, it is likely that an exempted app will push one or more metrics beyond the configured threshold. For example, it may push replication lag beyond a `5s` threshold. In such scenario, no other app could may any progress whatsoever, leading to starvation of all unexempted apps.

Some internal Vitess apps are always exempted. These are critical for the ongoing operation of the cluster, and do not generate high load. An example is the schema tracker, which tails the binary logs for changes, but does not otherwise copy or write any data.

### Heartbeat configuration

{{< info >}}
Configuring heartbeats is not strictly required, as the throttler will initiate an on-demand heartbeat lease while serving requests.
{{< /info >}}

To measure replication lag, the throttler uses the heartbeat writer service in Vitess. We recommend enabling heartbeats via `--heartbeat_on_demand_duration` in conjunction with `--heartbeat_interval` as follows:

- `--heartbeat_interval` indicates how frequently heartbeats are injected. The interval should over-sample the `--throttle_threshold` by a factor of `2` to `4`. For example,if `--throttle_threshold` is `5s`, use a heartbeat interval of `1s` or `2s`.
- `--heartbeat_on_demand_duration` ensures heartbeats are only injected when needed (e.g. during active VReplication workflows such as MoveTables or Online DDL). Heartbeats are written to the binary logs, and can therefore bloat them. If this is a concern, configure for example: `--heartbeat_on_demand_duration 5s`. This setting means: any throttler request starts a `5s` lease of heartbeat writes.
  In normal times, heartbeats are not written. Once a throttle check is requested (e.g. by a running migration), the throttler asks the tablet to start a `5s` lease of heartbeats. that first check is likely to return a non-OK code, because heartbeats were stale. However, subsequent checks will soon pick up on the newly injected heartbeats. Checks made while the lease is held, further extend the lease time. In the scenario of a running migration, we can expect heartbeats to begin as soon as the migration begins, and terminate `5s` (in our example) after the migration completes.
  A recommended value is a multiple of `--throttle_threshold`. If `--throttle_threshold` is `5s`, reasonable values would be `10s` to `60s`.

Alternatively, you may choose to enable heartbeats unconditionally via `--heartbeat_enable`, again in conjunction with `--heartbeat_interval <duration>`.

There is no need to configure the heartbeats as it will by default perform heartbeats upon each throttler requests, leased on-demand for `10s`.

### API

The primary throttler uses `CheckThrottler` gRPC calls on the replicas. Apps internal to vitess use `ThrottlerClient` as a library client.

The throttler does also provide a HTTP endpoint for external apps such as `gh-ost` and `pt-online-schema-change`:

- `/throttler/check?app=<app-name>` is the equivalent of `vtctldclient CheckThrottler --app-name=<app-name>`.
- `/throttler/check-self`, is the equivalent of `vtctldclient CheckThrottler --scope="self"`.

### Metrics

The tablet throttler exports several metrics using the expvars interface. These are available at the `/debug/vars` endpoint of vttablet's http status pages. [More details can be found here](../../features/monitoring/#3-push-based-metrics-system).

#### Aggregated metrics

These are the metrics by which the throttler compares with the threshold and decides whether to accept or reject throttle checks.

##### `ThrottlerAggregatedSelf<metric>`

Gauge, the current metric value on the tablet. This is the result of a self-check, done continuously when the throttler is enabled. Available per metric:

- `ThrottlerAggregatedSelfCustom`
- `ThrottlerAggregatedSelfLag`
- `ThrottlerAggregatedSelfLoadavg`
- `ThrottlerAggregatedSelfThreads_running`


##### `ThrottlerAggregatedShard<metric>`

Gauge, on the `PRIMARY` tablet only, this is the aggregated collected metric value from all serving shard tables, including the `PRIMARY`. The value is the highest (aka _worst_) of all collected tablets. Available per metric:

- `ThrottlerAggregatedShardCustom`
- `ThrottlerAggregatedShardLag`
- `ThrottlerAggregatedShardLoadavg`
- `ThrottlerAggregatedShardThreads_running`
  
#### Check metrics

The throttler is checked by apps (`vreplication`, `online-ddl`, etc), and responds with status codes, "OK" for "good to proceed" or any other code for "hold off".

At this time the throttler only runs checks with the backend MySQL server. It has the potential to check other input sources.

##### `ThrottlerCheckAnyTotal`

Counter, number of times the throttler has been checked. Tracking this metrics shows the traffic the throttler receives. The value should only increase when an app uses the throttler.

This metric excludes some internal apps (e.g. the schema tracker) that are always on, but does include the throttler's self checks (see following).

##### `ThrottlerCheckAnyError`

Counter. Included in `ThrottlerCheckAnyTotal`, indicating how many times the throttler rejected a check.

##### `ThrottlerCheckShard<metric>Total`

Counter. Number of shard-checks this throttler made for a given metric. Included in `ThrottlerCheckAnyTotal`. Available per metric:

- `ThrottlerCheckShardLagTotal`
- etc.

##### `ThrottlerCheckShard<metric>Error`

Counter. Included in `ThrottlerCheckAnyError`, indicating how many times the shard-check resulted in rejection for the given metric. Available per metric:

- `ThrottlerCheckShardLagError`
- etc.

##### `ThrottlerCheckSelfSecondsSinceHealthy`

Gauge, number of seconds since the last good self-check across all metrics.

##### `ThrottlerCheckShardSecondsSinceHealthy`

Gauge, number of seconds since the last good shard-check across all metrics.

#### Internal throttler metrics

These metrics are helpful when analyzing the throttler behavior, how it interacts with other shard throttlers, its heartbeat mechanism.

##### `ThrottlerProbesTotal`

The throttler probes for metrics independently of checks. Once probed, the result metric is cached, and any further checks are based on that cached value. Further probes overwrite that cached value.

Counter. Total number of probes this throttler made. This includes self probes (e.g. to get the self MySQL metric) and, on `PRIMARY`, the shard probes (e.g. getting MySQL metrics from all serving replicas).

##### `ThrottlerProbesLatency`

Gauge. Time in nanoseconds of last probe. This serves as a general heuristic only for network latency.

##### `ThrottlerProbeRecentlyChecked`

Counter, on a `PRIMARY` tablet only, indicating when a replica probe responds with `RecentlyChecked: true`. In such case, the `PRIMARY` throttler proceeds to request a heartbeat lease.

##### `ThrottlerCheckRequest`

Counter. Number of times throttler was probed via `CheckRequest` gRPC.

##### `ThrottlerHeartbeatRequests`

Counter. Number of times the throttler has requested a heartbeat lease. Correlated with `HeartbeatWrites` metric, and specifically when `--heartbeat_on_demand_duration` is set, this helps diagnose throttler/heartbeat negotiation and behavior.

## Notes

The throttler is originally derived from GitHub's [freno](https://github.com/github/freno). Over time, its design has significantly diverged from `freno`.
