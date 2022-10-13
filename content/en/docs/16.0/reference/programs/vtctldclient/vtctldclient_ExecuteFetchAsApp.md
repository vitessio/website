---
title: ExecuteFetchAsApp
series: vtctldclient
---
## vtctldclient ExecuteFetchAsApp

Executes the given query as the App user on the remote tablet.

```
vtctldclient ExecuteFetchAsApp [--max-rows <max-rows>] [--json|-j] [--use-pool] <tablet-alias> <query>
```

### Options

```
  -h, --help           help for ExecuteFetchAsApp
  -j, --json           Output the results in JSON instead of a human-readable table.
      --max-rows int   The maximum number of rows to fetch from the remote tablet. (default 10000)
      --use-pool       Use the tablet connection pool instead of creating a fresh connection.
```

### Options inherited from parent commands

```
      --action_timeout duration           timeout for the total command (default 1h0m0s)
      --emit_stats                        If set, emit stats to push-based monitoring and stats backends
      --server string                     server to use for connection (required)
      --stats_backend string              The name of the registered push-based monitoring/stats backend to use
      --stats_combine_dimensions string   List of dimensions to be combined into a single "all" value in exported stats vars
      --stats_common_tags strings         Comma-separated list of common tags for the stats backend. It provides both label and values. Example: label1:value1,label2:value2
      --stats_drop_variables string       Variables to be dropped from the list of exported variables.
      --stats_emit_period duration        Interval between emitting stats to all registered backends (default 1m0s)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

