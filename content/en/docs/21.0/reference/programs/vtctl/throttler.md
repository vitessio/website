---
title: vtctl Throttler Command Reference
series: vtctl
docs_nav_title: Throttler
---

The following `vtctl` commands are available for controlling the tablet throttler

## Commands

### UpdateThrottlerConfig

Update tablet throttler configuration for all tablets of a given keyspace.

#### Usage

<pre class="command-example">UpdateThrottlerConfig -- [--enable|--disable] [--threshold=&lt;float64&gt;] [--custom-query=&lt;query&gt;] [--check-as-check-self|--check-as-check-shard] [--throttle-app|unthrottle-app=&lt;name&gt;] [--throttle-app-ratio=&lt;float, range [0..1]&gt;] [--throttle-app-duration=&lt;duration&gt;] &lt;keyspace&gt;</pre>

#### Examples

```UpdateThrottlerConfig -- --enable --threshold "3.0" commerce```

```UpdateThrottlerConfig -- --disable commerce```

```UpdateThrottlerConfig -- --throttle-app="vreplication" --throttle-app-ratio=0.5 --throttle-app-duration="30m" commerce```

```UpdateThrottlerConfig -- --unthrottle-app="vreplication" commerce```

#### Flags

| Name | Type | Definition |
| :-------- | :--------- | :--------- |
| `enable` | Boolean | enable the throttler. Once enabled, the throttler probes the MySQL servers for metrics, and responds to `check` requests according to those metrics |
| `disable` | Boolean | disables the throttler. Once disabled, the throttler responds to all `check` requests with `200 OK`. It will not probe the MySQL servers for metrics |
| `threshold` | Double | set a new threshold. Unless specified otherwise, the throttler measures replication lag by querying for heartbeat values, and the threshold stands for _seconds_ of lag (i.e. the value `2.5` stands for two and a half seconds) |
| `custom-query` | String | override the default replication lag measurement, and suggest a different query. Valid values are:<br />  - _empty_, meaning the throttler should use the default replication lag query<br />  - A `SELECT` that returns a single line, single column, floating point value<br />  - A `SHOW GLOBAL STATUS|VARIABLES LIKE '...'`, for example `show global status like 'threads_running'` |
| `check-as-check-shard` | Boolean | this is the default behavior. A `/throttler/check` request checks the shard health. When using the default replication lag query, this is the desired check: the primary tablet's throttler responds by evaluating the overall lag throughout the shard/replicas |
| `check-as-check-self` | Boolean | override default behavior, and this can be useful when a `--custom-query` is set. A `/throttler/check` request will only consider the tablet's own metrics, and not the overall shard metrics |

#### Arguments

* <code>&lt;keyspace&gt;</code> &ndash; Required. The keyspace for which to apply the throttler configuration. All tablets in all shards and cells assigned to this keyspace are affected.

#### Errors

Any error transporting the configuration to a cell's local topo server.

## See Also

* [vtctl command index](../../vtctl)
