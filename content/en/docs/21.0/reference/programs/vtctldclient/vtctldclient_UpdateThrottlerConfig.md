---
title: UpdateThrottlerConfig
series: vtctldclient
commit: 471ab1a20a1f7f1f333ddd378b3edc71ad6de7a3
---
## vtctldclient UpdateThrottlerConfig

Update the tablet throttler configuration for all tablets in the given keyspace (across all cells)

```
vtctldclient UpdateThrottlerConfig [--enable|--disable] [--metric-name=<name>] [--threshold=<float64>] [--custom-query=<query>] [--throttle-app|unthrottle-app=<name>] [--throttle-app-ratio=<float, range [0..1]>] [--throttle-app-duration=<duration>] [--throttle-app-exempt=<bool>] [--app-name=<name> --app-metrics=<metrics>] <keyspace>
```

### Options

```
      --app-metrics strings              metrics to be used when checking the throttler for the app (requires --app-name). Empty to restore to default metrics. Example: --app-metrics=lag,custom,shard/loadavg
      --app-name string                  app name for which to assign metrics (requires --app-metrics)
      --custom-query string              custom throttler check query
      --disable                          Disable the throttler
      --enable                           Enable the throttler
  -h, --help                             help for UpdateThrottlerConfig
      --metric-name string               name of the metric for which we apply a new threshold (requires --threshold). If empty, the default (either 'lag' or 'custom') metric is used.
      --threshold float                  threshold for the either default check (replication lag seconds) or custom check
      --throttle-app string              an app name to throttle
      --throttle-app-duration duration   duration after which throttled app rule expires (app specififed in --throttled-app) (default 1h0m0s)
      --throttle-app-exempt              exempt this app from being at all throttled. WARNING: use with extreme care, as this is likely to push metrics beyond the throttler's threshold, and starve other apps
      --throttle-app-ratio float         ratio to throttle app (app specififed in --throttled-app) (default 1)
      --unthrottle-app string            an app name to unthrottle
```

### Options inherited from parent commands

```
      --action_timeout duration              timeout to use for the command (default 1h0m0s)
      --compact                              use compact format for otherwise verbose outputs
      --server string                        server to use for the connection (required)
      --topo-global-root string              the path of the global topology data in the global topology server (default "/vitess/global")
      --topo-global-server-address strings   the address of the global topology server(s) (default [localhost:2379])
      --topo-implementation string           the topology implementation to use (default "etcd2")
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

