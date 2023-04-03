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
- The throttler probes all `REPLICA` tablets for their replication lag. This is done by querying the `_vt.heartbeat` table.
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

It is _not possible_ to give an app more way than the throttler's standard behavior. That is, if the throttler is set to throttler at `5s` replication lag, it is _not possible_ to respond wih `HTTP 200` to a specific app with replication lag at `7s`.

## Configuration

{{< warning >}}
Configuration in v16 differs from v15 and earlier. Please note the different configuration options for your version.{{< /warning >}}

`v16` is backwards compliant with `v15` and still default to the `v15` configuration. We illustrate both configurations so that you understand how to transition from one to the other.

### v16 and forward

In `v16`, throttler configuration is found in the [local topology server](../../../concepts/topology-service/). There is one configuration per keyspace. All shards and all tablets in all cells have the same throttler configuration: they are all enabled or disabled, and all share the same threshold or custom query. Since configuration is stored outside the tablet, it survives tablet restarts.

`v16` is backward compliant with `v15` and therefore to use the new configuration you must opt-in with the `vttablet` flag `--throttler-config-via-topo` (boolean, disabled by default). With `--throttler-config-via-topo` set, the tablet will look for configuration in the topology server, and will watch and apply any changes made there.

Updating the throttler config is done via `vtctlclient` or `vtctldclient`. For example:

```sh
$ vtctlclient -- UpdateThrottlerConfig --enable --threshold 3.0 commerce
$ vtctldclient UpdateThrottlerConfig --disable commerce
```

See [vtctl UpdateThrottlerConfig](../../programs/vtctl/throttler#updatethrottlerconfig).

To transition from a `v15` configuration to `v16`, first populate topo with a new throttler configuration. At the very least, set a `--threshold`. You likely also want to `--enable`. Then, reconfigure `vttablet`s with `--throttler-config-via-topo`, and restart them.

### v15 and before

In `v15` and earlier versions, the throttler is configured per tablet. Each tablet can have throttler enabled/disabled independently, or have different thresholds.

`v16` supports the `v15` configuration, but this support may be removed in `v17`.

- The throttler is **disabled** by default. Use the `vttablet` option `--enable-lag-throttler` to enable the throttler.
  When the throttler is disabled, it still serves `/throttler/check` and `/throttler/check-self` API endpoints, and responds with `HTTP 200 OK` to all requests.
  When the throttler is enabled, it implicitly also runs heartbeat injections.
- Use the `vttablet` flag `--throttle_threshold` to set a lag threshold value. The default threshold is `1sec` and is set upon tablet startup. For example, to set a half-second lag threshold, use the flag `--throttle_threshold=0.5s`.
- To set the tablet types that the throttler queries for lag, use the `vttablet` flag `--throttle_tablet_types="replica,rdonly"`. The default tablet type is `replica`; this type is always implicitly included in the tablet types list. You may add any other tablet type. Any type not specified is ignored by the throttler.
- To override the default lag evaluation, and measure a different metric, use `--throttle_metrics_query`. The query must be either of these forms:
  - `SHOW GLOBAL STATUS LIKE '<metric>'`
  - `SHOW GLOBAL VARIABLES LIKE '<metric>'`
  - `SELECT <single-column> FROM ...`, expecting single column, single row result
- To override the throttle threshold, use `--throttle_metrics_threshold`. Floating point values are accepted.
- Use `--throttle_check_as_check_self` to implicitly reroute any `/throttler/check` call into `/throttler/check-self`. This makes sense when the user supplies a custom query, and where the user wishes to throttle writes to the cluster based on the primary tablet's health, rather than the overall health of the cluster.

An example for custom query & threshold setup, using the MySQL metrics `Threads_running` (number of threads actively executing a query at a given time) on the primary, might look like:

```shell
$ vttablet
  -throttle_metrics_query "show global status like 'threads_running'"
  -throttle_metrics_threshold 150
  -throttle_check_as_check_self
```

## Heartbeat configuration

Enabling the lag throttler also automatically enables heartbeat injection. The follwing `vttablet` flags further control heartbeat behavior:

- `--heartbeat_interval` indicates how frequently heartbeats are injected. The interval should over-sample the `--throttle_threshold`. For example, if `--throttle_threshold` is `1s`, then `--heartbeat_interval` should be `250ms` or less.
- `--heartbeat_on_demand_duration` ensures heartbeats are only injected when needed (e.g. during active VReplication workflows such as MoveTables or OnlineDDL). Heartbeats are written to the binary logs, and can therefore bloat them. If this is a concern, configure for example: `--heartbeat_on_demand_duration 5s`. This setting means: any throttler request starts a `5s` lease of heartbeat writes.
  In normal times, heartbeats are not written. Once a throttle check is requested (e.g. by a running migration), the throttler asks the tablet to start a `5s` lease of heartbeats. that first check is likely to return a non-OK code, because heartbeats were stale. However, subsequent checks will soon pick up on the newly injected heartbeats. Checks made while the lease is held, further extend the lease time. In the scenario of a running migration, we can expect heartbeats to begin as soon as the migration begins, and terminate `5s` (in our example) after the migration completes.
  A recommended value is a multiple of `--throttle_threshold`. If `--throttle_threshold` is `1s`, reasonable values would be `5s` to `60s`.

## API & usage

Applications use these API endpoints:

### Checks

- `/throttler/check?app=<app-name>`, for apps that wish to write mass amounts of data to a shard, and wish to maintain the overall health of the shard. This check is only applicable on the `PRIMARY` tablet.
- `/throttler/check-self`, for apps that wish to perform some operation (e.g. a massive _read_) on a specific tablet and only wish to maintain the health of that tablet. This check is applicable on all tablets.

#### Examples:

- `gh-ost` uses this throttler endpoint: `/throttler/check?app=gh-ost&p=low`
- A data backfill application will identify as such, and use _normal_ priority: `/throttler/check?app=my_backfill` (priority not indicated in URL therefore assumed to be _normal_)
- An app reading a massive amount of data directly from a replica tablet will use `/throttler/check-self?app=my_data_reader`

A `HEAD` request is sufficient. A `GET` request also provides a `JSON` output. For example:

- `{"StatusCode":200,"Value":0.207709,"Threshold":1,"Message":""}`
- `{"StatusCode":429,"Value":3.494452,"Threshold":1,"Message":"Threshold exceeded"}`
- `{"StatusCode":404,"Value":0,"Threshold":0,"Message":"No such metric"}`

In the first two above examples we can see that the tablet is configured to throttle at `1sec`

### Instructions

- `/throttler/throttle-app?app=<name>&duration=<duration>[&ratio=<ratio>][&p=low]`: instructs the throttler to begin throttling requests from given app.
  - A mandatory `duration` value auto expires the throttling after indicated time. You may specify these units: `s` (seconds), `m` (minutes), `h` (hours) or combinations. Example values: `90s`, `30m`, `1h`, `1h30m`, etc.
  - An optional `ratio` value indicates the throttling intensity, ranging from `0` (no throttling at all) to `1.0` (the default, full throttle).
    With a value of `0.3`, for example, `3` out of `10`, on average, checks by the app, are flat out denied, regardless of present metrics and threshold. The remaining `7` out of `10` checks, will get a response that is based on the actual metrics and threshold (thereby, thay may be approved, or they may be rejected).
  - Applications may also declare themselves to be _low priority_ via `?p=low` param. Managed online schema migrations (`gh-ost`, `pt-online-schema-change`) do so, as does the table purge process.
- `/throttler/unthrottle-app?app=<name>`: instructs the throttler to stop throttling for the given app. This removes any previous throttling instruction for the app. the throttler still reserves the right to throttle the app based on cluster status.

#### Examples:

- `/throttler/throttle-app?app=vreplication&duration=2h` rejects all requests made by `vreplication` for the next `2` hours, after which the app is unthrottled.
- `/throttler/throttle-app?app=vreplication&duration=2h&ratio=0.25` rejects on average 1 out of 4 requests made by `vreplication` for the next `2` hours, after which the app is unthrottled.

{{< info >}}
If using `curl` from a shell prompt/script, make sure to enclose URL with quotes, like so:

```
$ curl -s 'http://localhost:15000/throttler/throttle-app?app=test&ratio=0.25'
```
{{< /info >}}

### Information

- `/throttler/status` endpoint. This is useful for monitoring and management purposes.
- `/throttler/throttled-apps` endpoint, listing all apps for which there's a throttling instruction

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


#### Example: throttled-apps

```sh
$ curl -s 'http://127.0.0.1:15100/throttler/throttled-apps'
```

```json
[
  {
    "AppName": "always-throttled-app",
    "ExpireAt": "2032-05-08T11:33:19.683767744Z",
    "Ratio": 1
  }
]
```

## Resources

- [freno](https://github.com/github/freno) project page
- [Mitigating replication lag and reducing read load with freno](https://github.blog/2017-10-13-mitigating-replication-lag-and-reducing-read-load-with-freno/), a GitHub Engineering blog post
