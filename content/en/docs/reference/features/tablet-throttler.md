---
title: Tablet throttler
aliases: ['/docs/user-guides/tablet-throttler/','/docs/reference/tablet-throttler/']
---

VTTablet runs a cooperative throttling service, that probes the shard's MySQL topology and observes replication lag on servers. This throttler is derived from GitHub's [freno](https://github.com/github/freno).

## Why throttler

Vitess uses MySQL with asynchronous or semi-synchronous replication. In these modes, each shard has a primary that applies changes and logs them to the binary log. The replicas for that shard will get binary log entries from the primary, potentially acknowledge them (if semi-synchronous replication is enabled), and apply them. A running replica normally applies the entires as soon as possile, unless it is stopped or configured to delay. However, if the replica is busy (e.g. by serving traffic), then it may not have the resources (disk IO, CPU) to apply events in a timely fashion, and can therefore start lagging.

Maintaining low replication lag is important in production:

- A lagging replica may not be representative of the data on the primary. Reads from the replica reflect data that is not consistent with the primary's. This is noticeable on web services following read-after-write from the replica, and this then can produce results not reflecting the write.
- An up-to-date replica makes for a good failover experience. If all replicas are lagging, then a failover process must choose between waiting for a replica to catch up, or losing data.

Some common database operations include mass writes to the database:

- Online schema migrations, duplicating entire tables.
- Mass population of columns (e.g. following a `ADD COLUMN` migration, populate the new column with derived value).
- Purging of old data.
- Purging of tables as part of safe table `DROP` operation.

These operations can easily incur replication lag. However, these operations are typically not time-limited. It is possible to rate-limit them to reduce database load.

This is where a throttler gets in. A throttler can tell "replication lag is low, cluster is healthy, go ahead and do some work" or it may say "replication lag is high, please hold your next operation".

Applications are expected to break down their tasks into small sub-tasks (e.g. instead of deleting `1,000,000` rows, only delete `50` at a time), and check in with the throttler in-between.

The throttler is intended for use only for operations such as the above mass write cases. It should not be used for ongoing, normal OLTP queries.

## Throttler overview

Each `vttablet` runs an internal throttler service, and provides API endpoints to the throttler. Only the primary throttler is doing actual work at any given time. The throttlers on the replicas are mostly dormant, and wait for their turn to become "leaders", i.e. for the tablet to transition into `MASTER` (primary) type.

The primary tablet's throttler does the following things, continuously:

- Confirm it's still the primary tablet for its shard.
- Every `10sec`, use topology server to refresh the shard's tablets list
- Probe all `REPLICA` tablets for their replication lag. This is done by querying the `_vt.heartbeat` table.
  - Throttler begins in dormant probe mode. As long as no app/client is actually looking for metrics, it probes the servers in multi-second interval.
  - When apps check for throttle advice, it begins probing servers in subsecond intervals. It reverts to dormant probe mode if no requests are made in the duration of `1min`.
- Aggregate last probed value from all relevant tablets; this is _the cluster's metric _.

The cluster's metric is only as accurate as:

- The probe interval,
- The heartbeat injection interval, and
- The aggregation interval

The error margin is about the sum of the above values, plus additional overhead. Default probe interval is `100ms`, aggregation interval is `100ms` and default heartbeat interval is `250ms`. The latter may be overriden by the user via `-heartbeat_interval` flag to `vttablet`.

Thus, the aggregated interval can be off, by default, by some `500ms`. This makes it inaccurate for evaluations that require high resolution lag evaluation. Fortunately, for throttling purposes, this resolution is sufficient.

The throttler allows clients/apps to `check` for throttle advice. The check is a `HTTP` request, `HEAD` or `GET` method. Throttler returns a HTTP response code as an answer:

- `200` (OK): Application may write to data store. This is the desired response.
- `404` (Not Found): Unknown metric name. This can take place immediately upon startup or immediately after failover, and should resovle within 10 seconds.
- `417` (Expectation Failed): Requesting application is explicitly forbidden to write. Tablet throttler does not implement this at this time.
- `429` (Too Many Requests): Do not write. A normal, expected state indicating there is replication lag. This is the hint for apps/clients to withhold writes.
- `500` (Internal Server Error): Internal error. Do not write.

Normally, apps will see either `200` or `429`. An app should only ever proceed to write to the database when it receives a `200` response code.

The throttler chooses the response by comparing the replication lag with a pre-defined _threshold_. If the lag is lower than the threshold, response can be `200` (OK). If the lag is higher than the threshold, response would be `429` (Too Many Requests).

The throttler only collects and evaluates lag on a set of predefined tablet types. By default, this tablet type set is `REPLICA`. See configuration, below.

When the throttler sees no relevant replicas in the shard, the behavior is to allow writes (respond with `HTTP 200 OK`).

## Configuration


- The throttler is currently disabled by default. Use the `vttablet` option `-enable-lag-throttler` to enable the throttler.
  When the throttler is disabled, it still serves `/throttler/check` API and responds with `HTTP 200 OK` to all requests.
  When the throttler is enabled, it implicitly also runs heartbeat injections.
- Use the `vttablet` flag `-throttle_threshold` to set a lag threshold value, e.g. `-throttle_threshold=0.5s` for a half second. The default threshold is `1sec` and is set upon tablet startup.
- Use the `vttablet` flag `-throttle_tablet_types="replica,rdonly"` to set the tablet types which are queried for lag and considered by the throttler. `replica` is always implicitly included (and the default), and you may add any other tablet type. Any type not specified is ignored by the throttler.

## API & usage

Apps will use `/throttler/check`

- Apps may indicate their identity via `?app=<name>` param.
- Apps may further declare themselves to be _low priority_ via `?p=low` param. Managed online schema migrations (`gh-ost`, `pt-online-schema-change`) do so, as does the table purge process.

Examples:

- `gh-ost` uses this throttler endpoint: `/throttler/check?app=gh-ost&p=low`
- A data backfill app may use: `/throttler/check?app=backfill` (using _normal_ priority)

A `HEAD` request is sufficient. A `GET` request also provides a `JSON` output. Examples:

- `{"StatusCode":200,"Value":0.207709,"Threshold":1,"Message":""}`
- `{"StatusCode":429,"Value":3.494452,"Threshold":1,"Message":"Threshold exceeded"}`
- `{"StatusCode":404,"Value":0,"Threshold":0,"Message":"No such metric"}`

In the above we can see that the tablet is configured to throttle at `1sec`

Tablet also provides `/throttler/status` endpoint. This is useful for monitoring/management purposes. Examples:

On a `primary`, healthy tablet:

```shell
$ curl -s http://tablet1:15100/throttler/status | jq .
```
```json
{
  "Keyspace": "commerce",
  "Shard": "80-c0",
  "IsLeader": true,
  "IsOpen": true,
  "IsDormant": false,
  "AggregatedMetrics": {
    "mysql/local": {
      "Value": 0.193576
    }
  },
  "MetricsHealth": {}
}

```

Notable:

- `"IsLeader": true` indicates this tablet is active, is the `primary`, and is running probes
- `"IsDormant": false,` means an app has recently issued a `check`, and the throttler is probing for lag at high frequency.

On a `REPLICA` tablet:

```shell
$ curl -s http://tablet2:15100/throttler/status | jq .
```
```json
{
  "Keyspace": "commerce",
  "Shard": "80-c0",
  "IsLeader": false,
  "IsOpen": true,
  "IsDormant": true,
  "AggregatedMetrics": {},
  "MetricsHealth": {}
}
```


## Resources

- [freno](https://github.com/github/freno) project page
- [Mitigating replication lag and reducing read load with freno](https://github.blog/2017-10-13-mitigating-replication-lag-and-reducing-read-load-with-freno/), a GitHub Engineering blog post

