---
title: UpdateThrottlerConfig
series: vtctldclient
---
## vtctldclient UpdateThrottlerConfig

Update the tablet throttler configuration for all tablets in the given keyspace (across all cells)

```
vtctldclient UpdateThrottlerConfig [--enable|--disable] [--threshold=<float64>] [--custom-query=<query>] [--check-as-check-self|--check-as-check-shard] [--throttle-app|unthrottle-app=<name>] [--throttle-app-ratio=<float, range [0..1]>] [--throttle-app-duration=<duration>] <keyspace>
```

### Options

```
      --check-as-check-self             /throttler/check requests behave as is /throttler/check-self was called
      --check-as-check-shard            use standard behavior for /throttler/check requests
      --custom-query string             custom throttler check query
      --disable                         Disable the throttler
      --enable                          Enable the throttler
  -h, --help                            help for UpdateThrottlerConfig
      --threshold float                 threshold for the either default check (replication lag seconds) or custom check
      --throttle-app string             set a specific throttling rule for the given app
      --throttle-app-ratio float        set a throttling ratio for app indicated by --throttle-app. 0 means not throttled, 1.0 means fully throttled.
      --throttle-app-duration duration  time limit after which throttling rule expires. Set as 0 to cancel an existing rule
      --unthrottle-app string           expire any throttling rule for the given app
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

