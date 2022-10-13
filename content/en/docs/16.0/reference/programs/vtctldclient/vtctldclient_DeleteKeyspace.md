---
title: DeleteKeyspace
series: vtctldclient
---
## vtctldclient DeleteKeyspace

Deletes the specified keyspace from the topology.

### Synopsis

Deletes the specified keyspace from the topology.

In recursive mode, it also recursively deletes all shards in the keyspace.
Otherwise, the keyspace must be empty (have no shards), or returns an error.

```
vtctldclient DeleteKeyspace [--recursive|-r] [--force|-f] <keyspace>
```

### Options

```
  -f, --force       Delete the keyspace even if it cannot be locked; this should only be used for cleanup operations.
  -h, --help        help for DeleteKeyspace
  -r, --recursive   Recursively delete all shards in the keyspace, and all tablets in those shards.
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

