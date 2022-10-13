---
title: PlannedReparentShard
series: vtctldclient
---
## vtctldclient PlannedReparentShard

Reparents the shard to a new primary, or away from an old primary. Both the old and new primaries must be up and running.

```
vtctldclient PlannedReparentShard <keyspace/shard>
```

### Options

```
      --avoid-primary string             Alias of a tablet that should not be the primary; i.e. "reparent to any other tablet if this one is the primary".
  -h, --help                             help for PlannedReparentShard
      --new-primary string               Alias of a tablet that should be the new primary.
      --wait-replicas-timeout duration   Time to wait for replicas to catch up on replication both before and after reparenting. (default 30s)
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

