---
title: Tablet throttler
weight: 21
aliases: ['/docs/user-guides/tablet-throttler/','/docs/reference/tablet-throttler/']
---

VTTablet runs a cooperative throttling service. This service probes the shard's MySQL topology and observes health, measure by replication lag, or by another metric delivered by custom query, on servers. The throttler is derived from GitHub's [freno](https://github.com/github/freno).

## Why throttler: maintaining shard health via low replication lag

Vitess uses MySQL with asynchronous or semi-synchronous replication. In these modes, each shard has a primary instance that applies changes and logs them to the binary log. The replicas for that shard will get binary log entries from the primary, potentially acknowledge them (if semi-synchronous replication is enabled), and apply them. A running replica normally applies the entries as soon as possible, unless it is stopped or configured to delay. However, if the replica is busy, then it may not have the resources to apply events in a timely fashion, and can therefore start lagging. For example, if the replica is serving traffic, it may lack the necessary disk I/O or CPU to avoid lagging behind the primary.

Maintaining low replication lag is important in production for two reasons:

- A lagging replica may not be representative of the data on the primary. Reads from the replica reflect data that is not consistent with the data on the primary. This is noticeable on web services following read-after-write from the replica, and this can produce results not reflecting the write.
- An up-to-date replica makes for a good failover experience. If all replicas are lagging, then a failover process must choose between waiting for a replica to catch up or losing data.

Some common database operations include mass writes to the database, including the following:

- Online schema migrations duplicating entire tables
- Mass population of columns, such as populating the new column with derived values following an `ADD COLUMN` migration
- Purging of old data
- Purging of tables as part of safe table `DROP` operation

Other operations include mass reads from the database:

- An ETL reading content of entire tables
- VReplication scanning an entire keyspace data and binary logs

These operations can easily incur replication lag. However, these operations are typically not time-limited. It is possible to rate-limit them to reduce database load.

This is where a throttler becomes useful. A throttler can detect when replication lag is low, a cluster is healthy, and operations can proceed. It can also detect when replication lag is high and advise applications to withhold the next operation.

Applications are expected to break down their tasks into small sub-tasks. For example, instead of deleting `1,000,000` rows, an application should only delete `50` at a time. Between these sub-tasks, the application should check in with the throttler.

The throttler is only intended for use with operations such as the above mass write/read cases. It should not be used for ongoing, normal OLTP queries.

## Throttler overview

Each `vttablet` runs an internal throttler service, and provides API endpoints to the throttler. Each tablet, including the primary, measures its own "self" health, discussed later. 

### Cluster health:

In addition, the primary tablet is responsible for the overall health of the cluster/shard:

- The throttler confirms it is still the primary tablet for its shard.
- Every `10sec`, the throttler uses the topology server to refresh the shard's tablets list.
- The throttler probes all `REPLICA` tablets (or other types of tablets, see [Configuration](#configuration)) for their own throttler metrics. This is done via gRPC.
  - The throttler begins in dormant probe mode. As long as no application or client is actually looking for metrics, it probes the servers at multi-second intervals.
  - When applications check for throttle advice, the throttler begins probing servers in subsecond intervals. It reverts to dormant probe mode if no requests are made in the duration of `1min`.
- The throttler aggregates the last probed values from all relevant tablets. This is _the cluster's metric_.

The cluster's metric is only as accurate as the following metrics:

- The probe interval
- The heartbeat injection interval
- The aggregation interval

The error margin equals approximately the sum of the above values, plus additional overhead. The defaults for these intervals are as follows:

+ Probe interval: `100ms`
+ Aggregation interval: `100ms`
+ Heartbeat interval: `250ms`

The user may override the heartbeat interval by sending `-heartbeat_interval` flag to `vttablet`.

Thus, the aggregated interval can be off, by default, by some `500ms`. This makes it inaccurate for evaluations that require high resolution lag evaluation. This resolution is sufficient for throttling purposes.

### Self health

Each tablet runs a local health check against its backend database, again in the form of evaluating replication lag from `_vt.heartbeat`. Intervals are identical to the cluster health interval illustrated above.

### Response codes

The throttler allows clients and applications to `check` for throttle advice. The check is an `HTTP` request, `HEAD` method, or `GET` method. Throttler returns one of the following HTTP response codes as an answer:

- `200` (OK): The application may write to the data store. This is the desired response.
- `404` (Not Found): The check contains an unknown metric name. This can take place immediately upon startup or immediately after failover, and should resolve within 10 seconds.
- `417` (Expectation Failed): The requesting application is explicitly forbidden to write. The throttler does not implement this at this time.
- `429` (Too Many Requests): Do not write. A normal, expected state indicating there is replication lag. This is the hint for applications or clients to withhold writes.
- `500` (Internal Server Error): An internal error has occurred. Do not write.

Normally, apps will see either `200` or `429`. An app should only ever proceed to write to the database when it receives a `200` response code.

The throttler chooses the response by comparing the replication lag with a pre-defined _threshold_. If the lag is lower than the threshold, response can be `200` (OK). If the lag is higher than the threshold, the response would be `429` (Too Many Requests).

The throttler only collects and evaluates lag on a set of predefined tablet types. By default, this tablet type set is `REPLICA`. See [Configuration](#configuration).

When the throttler sees no relevant replicas in the shard, it allows writes by responding with `HTTP 200 OK`.

## Custom metrics & queries

The default behavior is to measure replication lag and throttle based on that lag. Vitess allows the user to use custom metrics and thresholds for throttling.

Vitess only supports gauges for custom metrics: the user may define a query which returns a gauge value, an absolute metric by which Vitess can throttle. See [#Configuration](#configuration), below.

## App management

It is possible for the throttler to respond differently -- to some extent -- to different clients, or _apps_. When a client asks for the throttler's advice, it may identify itself by any arbitrary name, which the throttler terms the _app_. For example, `vreplication` workflows identify by the name "vreplication", and Online DDL operations use "online-ddl", etc.

It is possible to _restrict_ the throttler's response to one or more apps. For example, it's possible to completely throttle "vreplication" while still responding `HTTP 200` to other apps. This is typically used to give way or precedence to one or two apps, or otherwise to further reduce the incoming load from a specific app.

It is also possible to _exempt_ an app from throttling, even if the throttler is otherwise rejecting requests with metrics beyond the threshold. This is an advanced feature that users should treat with great care, and only in situations where they absolutely must give a specific workflow/migration the highest priority above all else. See discussion in examples, below.

## Configuration

Throttler configuration is found in the [local topology server](../../../concepts/topology-service/). There is one configuration per keyspace. All shards and all tablets in all cells have the same throttler configuration: they are all enabled or disabled, and all share the same threshold or custom query. Since configuration is stored outside the tablet, it survives tablet restarts.

The following flags have been removed in `v19`:

- `--throttle_threshold`
- `--throttle_metrics_query`
- `--throttle_metrics_threshold`
- `--throttle_check_as_check_self`
- `--throttler-config-via-topo`

The following flag was removed:

- `--enable_lag_throttler`

Updating the throttler config is done via `vtctldclient`. For example:

```sh
$ vtctldclient UpdateThrottlerConfig --enable --threshold 3.0 commerce
$ vtctldclient UpdateThrottlerConfig --disable commerce
$ vtctldclient UpdateThrottlerConfig --throttle-app "vreplication" --throttle-app-ratio 0.5 --throttle-app-duration "30m" commerce
```

See [vtctl UpdateThrottlerConfig](../../programs/vtctl/throttler#updatethrottlerconfig).

The list of tablet types included in the throttler's logic is dictated by `vttablet --throttle_tablet_types`. The value is a comma delimited list of tablet types. The default value is `"replica"`. You may, for example, set it to be `"replica,rdonly"`.

## Heartbeat configuration

To measure replication lag, the throttler uses the heartbeat writer service in Vitess. We recommend enabling heartbeats via `--heartbeat_on_demand_duration` in conjunction with `--heartbeat_interval` as follows:

- `--heartbeat_interval` indicates how frequently heartbeats are injected. The interval should over-sample the `--throttle_threshold` by a factor of `2` to `4`. Examples:
  - If `--throttle_threshold` (replication lag) is `1s`, use `--heartbeat_interval 250ms`.
  - If `--throttle_threshold` is `5s`, use an interval of `1s` or `2s`.
- `--heartbeat_on_demand_duration` ensures heartbeats are only injected when needed (e.g. during active VReplication workflows such as MoveTables or Online DDL). Heartbeats are written to the binary logs, and can therefore bloat them. If this is a concern, configure for example: `--heartbeat_on_demand_duration 5s`. This setting means: any throttler request starts a `5s` lease of heartbeat writes.
  In normal times, heartbeats are not written. Once a throttle check is requested (e.g. by a running migration), the throttler asks the tablet to start a `5s` lease of heartbeats. that first check is likely to return a non-OK code, because heartbeats were stale. However, subsequent checks will soon pick up on the newly injected heartbeats. Checks made while the lease is held, further extend the lease time. In the scenario of a running migration, we can expect heartbeats to begin as soon as the migration begins, and terminate `5s` (in our example) after the migration completes.
  A recommended value is a multiple of `--throttle_threshold`. If `--throttle_threshold` is `1s`, reasonable values would be `5s` to `60s`.

Alternatively, you may choose to enable heartbeats unconditionally via `--heartbeat_enable`, again in conjunction with `--heartbeat_interval <duration>`.

When the heartbeat writer is unconfigured, it still serves heartbeats at throttler requests, leased on-demand for `10s`. It is therefore not strictly necessary to configure the heartbeat writer.

## API & usage

Applications use these API endpoints:

### Checks

- `/throttler/check?app=<app-name>`, for apps that wish to write mass amounts of data to a shard, and wish to maintain the overall health of the shard. This check is only applicable on the `PRIMARY` tablet.
- `/throttler/check-self`, for apps that wish to perform some operation (e.g. a massive _read_) on a specific tablet and only wish to maintain the health of that tablet. This check is applicable on all tablets.

#### Examples:

- `gh-ost` uses this throttler endpoint: `/throttler/check?app=online-ddl:gh-ost:<migration-uuid>&p=low`
- An app reading a massive amount of data directly from a replica tablet will use `/throttler/check-self?app=my_data_reader`

A `HEAD` request is sufficient. A `GET` request also provides a `JSON` output. For example:

- `{"StatusCode":200,"Value":0.207709,"Threshold":1,"Message":""}`
- `{"StatusCode":429,"Value":3.494452,"Threshold":1,"Message":"Threshold exceeded"}`
- `{"StatusCode":404,"Value":0,"Threshold":0,"Message":"No such metric"}`

In the first two above examples we can see that the tablet is configured to throttle at `1sec`

### Control

All controls below apply to a given keyspace (`commerce` in the next examples). All of the keyspace's tablets, in all shards and cells, are affected.

Enable the throttler:

```sh
$ vtctldclient UpdateThrottlerConfig --enable commerce
```

Disable the throttler

```sh
$ vtctldclient UpdateThrottlerConfig --disable commerce
```

Enable and also set a replication lag threshold:

```sh
$ vtctldclient UpdateThrottlerConfig --enable --threshold 15.0 commerce
```

Set a custom query and a matching threshold. Does not affect enabled state:

```sh
$ vtctldclient UpdateThrottlerConfig --custom-query "show global status like 'threads_running'" --threshold 40 --check-as-check-self commerce
```

In the above, we use `--check-as-check-self` because we want the shard's `PRIMARY`'s metric (concurrent threads) to be the throttling factor.

Return to default throttling metric (replication lag):

```sh
$ vtctldclient UpdateThrottlerConfig --custom-query "" --threshold 15.0 --check-as-check-shard commerce
```

In the above, we use `--check-as-check-self` because we want the shard's replicas metric (lag) to be the throttling factor.

Throttle a specific app, `vreplication`, so that `80%` of its eligible requests are denied (slowing it down to `20%` potential speed), auto-expiring after `30` minutes:

```sh
$ vtctldclient UpdateThrottlerConfig --throttle-app "vreplication" --throttle-app-ratio=0.8 --throttle-app-duration "30m" commerce
```

Unthrottle an app:

```sh
$ vtctldclient UpdateThrottlerConfig --unthrottle-app "vreplication" commerce
```

An altrnative method to unthrottle is to set a throttling rule that expires immediately:

```sh
$ vtctldclient UpdateThrottlerConfig --throttle-app "vreplication" --throttle-app-duration 0 commerce
```

Fully throttle all Online DDL (schema changes) for the next hour and a half:

```sh
$ vtctldclient UpdateThrottlerConfig --throttle-app "online-ddl" --throttle-app-ratio=1.0 --throttle-app-duration "1h30m" commerce
```

Exempt `vreplication` from being throttled, even if otherwise the metrics are past the throttler threshold (e.g. replication lag is high):

```sh
$ vtctldclient UpdateThrottlerConfig --throttle-app "vreplication" --throttle-app-duration "30m" --throttle-app-exempt commerce
```

Use the above with great care. Exempting one app can cause starvation to all other apps. Consider, for example, the common use case where throttling is based on replication lag. By exempting `vreplication`, it is free to grab all the resources it wants. It is possible and likely that it will drive replication lag higher than the threshold, which means all other throttler clients will be fully throttled and with all requests rejected.

Exemption times out just as other throttling rules. To remove an exemption, any of the following will do:

```sh
$ vtctldclient UpdateThrottlerConfig --throttle-app "vreplication" --throttle-app-exempt=false commerce
$ vtctldclient UpdateThrottlerConfig --throttle-app "vreplication" --throttle-app-duration "0" commerce
$ vtctldclient UpdateThrottlerConfig --unthrottle-app "vreplication" commerce
```

### Information

Throttler configuration is part of the `Keyspace` entry:

```sh
$ vtctldclient GetKeyspace commerce
```

```json
{
  "name": "commerce",
  "keyspace": {
    "served_froms": [],
    "keyspace_type": 0,
    "base_keyspace": "",
    "snapshot_time": null,
    "durability_policy": "semi_sync",
    "throttler_config": {
      "enabled": true,
      "threshold": 15.0,
      "custom_query": "",
      "check_as_check_self": false,
      "throttled_apps": {
        "vreplication": {
          "name": "vreplication",
          "ratio": 0.5,
          "expires_at": {
            "seconds": "1687864412",
            "nanoseconds": 142717831
          }
        }
      }
    },
    "sidecar_db_name": "_vt"
  }
}
```

- `/throttler/status` endpoint. This is useful for monitoring and management purposes.

Vitess also accepts the SQL syntax:

- `SHOW VITESS_THROTTLER STATUS`: returns the status for all primary tables in the keyspace. See [MySQL Query Extensions](../mysql-query-extensions/#show-statements).

#### Example: Healthy primary tablet

The following command gets throttler status on a primary tablet hosted on `tablet1`, serving on port `15100`.

```shell
$ curl -s 'http://tablet1:15100/throttler/status' | jq .
```

This API call returns the following JSON object:

```json
{
  "Keyspace": "commerce",
  "Shard": "80-c0",
  "IsLeader": true,
  "IsOpen": true,
  "IsDormant": false,
  "Query": "select unix_timestamp(now(6))-max(ts/1000000000) as replication_lag from _vt.heartbeat",
  "Threshold": 1,
  "AggregatedMetrics": {
    "mysql/self": {
      "Value": 0.749837
    },
    "mysql/shard": {
      "Value": 0.749887
    }
  },
  "MetricsHealth": {
    "mysql/self": {
      "LastHealthyAt": "2021-01-24T19:03:19.141933727+02:00",
      "SecondsSinceLastHealthy": 0
    },
    "mysql/shard": {
      "LastHealthyAt": "2021-01-24T19:03:19.141974429+02:00",
      "SecondsSinceLastHealthy": 0
    }
  }
}
```

The primary tablet serves two types of metrics:

- `mysql/shard`: an aggregated lag on relevant replicas in this shard. This is the metric to check when writing massive amounts of data to this server.
- `mysql/self`: the health of the specific primary MySQL server backed by this tablet.

`"IsLeader": true` indicates this tablet is active, is the `primary`, and is running probes.
`"IsDormant": false,` means that an application has recently issued a `check`, and the throttler is probing for lag at high frequency.

#### Example: replica tablet

The following command gets throttler status on a replica tablet hosted on `tablet2`, serving on port `15100`.

```shell
$ curl -s 'http://tablet2:15100/throttler/status' | jq .
```

This API call returns the following JSON object:

```json
{
  "Keyspace": "commerce",
  "Shard": "80-c0",
  "IsLeader": false,
  "IsOpen": true,
  "IsDormant": false,
  "Query": "select unix_timestamp(now(6))-max(ts/1000000000) as replication_lag from _vt.heartbeat",
  "Threshold": 1,
  "AggregatedMetrics": {
    "mysql/self": {
      "Value": 0.346409
    }
  },
  "MetricsHealth": {
    "mysql/self": {
      "LastHealthyAt": "2021-01-24T19:04:25.038290475+02:00",
      "SecondsSinceLastHealthy": 0
    }
  }
}
```

The replica tablet only presents `mysql/self` metric (measurement of its own backend MySQL's lag). It does not serve checks for the shard in general.

### Metrics

The tablet throttler exports several metrics using the expvars interface. These are available at the `/debug/vars` endpoint of vttablet's http status pages. [More details can be found here](../../features/monitoring/#3-push-based-metrics-system).

#### Aggregated metrics

These are the metrics by which the throttler compares with the threshold and decides whether to accept or reject throttle checks.

##### `ThrottlerAggregatedMysqlSelf`

Gauge, the current metric value of the tablet. This is the result of a self-check, done continuously when the throttler is enabled.

##### `ThrottlerAggregatedMysqlShard`

Gauge, on the `PRIMARY` tablet only, this is the aggregated collected metric value from all serving shard tables, excluding the `PRIMARY`. The `PRIMARY` tablet continuously probes the serving tablets for this metric. As the default collected metric is replication lag, the aggregated value is the highest lag across the probed tablets.

#### Check metrics

The throttler is checked by apps (`vreplication`, `online-ddl`, etc), and responds with status codes, "OK" for "good to proceed" or any other code for "hold off".

At this time the throttler only runs checks with the backend MySQL server. It has the potential to check other input sources.

##### `ThrottlerCheckAnyTotal`

Counter, number of times the throttler has been checked. Tracking this metrics shows the traffic the throttler receives. The value should only increase when an app uses the throttler.

This metric excludes some internal apps (e.g. the schema tracker) that are always on, but does include the throttler's self checks (see following).

##### `ThrottlerCheckAnyError`

Counter. Included in `ThrottlerCheckAnyTotal`, indicating how many times the throttler rejected a check.

##### `ThrottlerCheckAnyMysqlSelfTotal`

Counter. Number of MySQL self-checks this throttler made. Included in `ThrottlerCheckAnyTotal`.

##### `ThrottlerCheckAnyMysqlSelfError`

Counter. Included in `ThrottlerCheckAnyMysqlSelfTotal`, indicating how many times the MySQL self-check resulted in rejection.

##### `ThrottlerCheckAnyMysqlShardTotal`

Counter. Number of MySQL shard-checks this throttler made. Included in `ThrottlerCheckAnyTotal`.

##### `ThrottlerCheckAnyMysqlShardError`

Counter. Included in `ThrottlerCheckAnyMysqlShardTotal`, indicating how many times the MySQL shard-check resulted in rejection.

##### `ThrottlerCheckMysqlSelfSecondsSinceHealthy`

Gauge, number of seconds since the last good MySQL self-check.

##### `ThrottlerCheckMysqlShardSecondsSinceHealthy`

Gauge, number of seconds since the last good MySQL shard-check.

#### Internal throttler metrics

These metrics are helpful when analyzing the throttler behavior, how it interacts with other shard throttlers, its heartbeat mechanism.

##### `ThrottlerProbesTotal`

The throttler probes for metrics independently of checks. Once probed, the result metric is cached, and any further checks are based on that cached value. Further probes overwrite that cached value.

Counter. Total number of probes this throttler made. This includes self probes (e.g. to get the self MySQL metric) and, on `PRIMARY`, the shard probes (e.g. getting MySQL metrics from all serving replicas).

##### `ThrottlerProbesLatency`

Gauge. Time in nanoseconds of last probe. This serves as a general heuristic only for network latency.

##### `ThrottlerRecentlyChecked`

Gauge, `0` or `1`, indicating whether a throttler was "recently" checked by some app. "Recent" is measured in a few seconds. A `PRIMARY` throttler that has been recently checked requests a heartbeat lease. A non `PRIMARY` throttler makes the `RecentlyChecked` information available in `CheckThrottlerResponse` response to `CheckThrottler` gRPC.

##### `ThrottlerProbeRecentlyChecked`

Gauge, `0` or `1`, on a `PRIMARY` tablet only, indicating when a replica probe responds with `RecentlyChecked: true`. In such case, the `PRIMARY` throttler proceeds to request a heartbeat lease.

##### `ThrottlerCheckRequest`

Counter. Number of times throttler was probed via `CheckRequest` gRPC.

##### `ThrottlerHeartbeatRequests`

Counter. Number of times the throttler has requested a heartbeat lease. Correlated with `HeartbeatWrites` metric, and specifically when `--heartbeat_on_demand_duration` is set, this helps diagnose throttler/heartbeat negotiation and behavior.

## Resources

- [freno](https://github.com/github/freno) project page
- [Mitigating replication lag and reducing read load with freno](https://github.blog/2017-10-13-mitigating-replication-lag-and-reducing-read-load-with-freno/), a GitHub Engineering blog post
