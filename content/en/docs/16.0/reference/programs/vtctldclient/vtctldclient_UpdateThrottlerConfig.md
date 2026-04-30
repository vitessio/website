---
title: UpdateThrottlerConfig
series: vtctldclient
commit: a7f80a82e5d99cf00c253c3902367bec5fa40e5d
---
## vtctldclient UpdateThrottlerConfig

Update the tablet throttler configuration for all tablets in the given keyspace (across all cells)

```
vtctldclient UpdateThrottlerConfig [--enable|--disable] [--threshold=<float64>] [--custom-query=<query>] [--check-as-check-self|--check-as-check-shard] <keyspace>
```

### Options

```
      --check-as-check-self    /throttler/check requests behave as is /throttler/check-self was called
      --check-as-check-shard   use standard behavior for /throttler/check requests
      --custom-query string    custom throttler check query
      --disable                Disable the throttler
      --enable                 Enable the throttler
  -h, --help                   help for UpdateThrottlerConfig
      --threshold float        threshold for the either default check (replication lag seconds) or custom check
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

