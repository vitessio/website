---
title: RemoveKeyspaceCell
series: vtctldclient
---
## vtctldclient RemoveKeyspaceCell

Removes the specified cell from the Cells list for all shards in the specified keyspace (by calling RemoveShardCell on every shard). It also removes the SrvKeyspace for that keyspace in that cell.

```
vtctldclient RemoveKeyspaceCell [--force|-f] [--recursive|-r] <keyspace> <cell>
```

### Options

```
  -f, --force       Proceed even if the cell's topology server cannot be reached. The assumption is that you turned down the entire cell, and just need to update the global topo data.
  -h, --help        help for RemoveKeyspaceCell
  -r, --recursive   Also delete all tablets in that cell beloning to the specified keyspace.
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

