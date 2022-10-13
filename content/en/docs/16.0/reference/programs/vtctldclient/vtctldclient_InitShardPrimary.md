---
title: InitShardPrimary
series: vtctldclient
---
## vtctldclient InitShardPrimary

Sets the initial primary for the shard.

### Synopsis

Sets the initial primary for the shard.

This will make all other tablets in the shard become replicas of the promoted tablet.
WARNING: this can cause data loss on an already-replicating shard. PlannedReparentShard or
EmergencyReparentShard should be used instead.


```
vtctldclient InitShardPrimary <keyspace/shard> <primary alias>
```

### Options

```
      --force                            Force the reparent even if the provided tablet is not writable or the shard primary.
  -h, --help                             help for InitShardPrimary
      --wait-replicas-timeout duration   Time to wait for replicas to catch up in reparenting. (default 30s)
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

