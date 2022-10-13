---
title: GetTablets
series: vtctldclient
---
## vtctldclient GetTablets

Looks up tablets according to filter criteria.

### Synopsis

Looks up tablets according to the filter criteria.

If --tablet-alias is passed, none of the other filters (keyspace, shard, cell) may
be passed, and tablets are looked up by tablet alias only.

If --keyspace is passed, then all tablets in the keyspace are retrieved. The
--shard flag may also be passed to further narrow the set of tablets to that
<keyspace/shard>. Passing --shard without also passing --keyspace will fail.

Passing --cell limits the set of tablets to those in the specified cells. The
--cell flag accepts a CSV argument (e.g. --cell "c1,c2") and may be repeated
(e.g. --cell "c1" --cell "c2").

Valid output formats are "awk" and "json".

```
vtctldclient GetTablets [--strict] [{--cell $c1 [--cell $c2 ...], --keyspace $ks [--shard $shard], --tablet-alias $alias}]
```

### Options

```
  -c, --cell strings           List of cells to filter tablets by.
      --format string          Output format to use; valid choices are (json, awk). (default "awk")
  -h, --help                   help for GetTablets
  -k, --keyspace string        Keyspace to filter tablets by.
  -s, --shard string           Shard to filter tablets by.
      --strict                 Require all cells to return successful tablet data. Without --strict, tablet listings may be partial.
  -t, --tablet-alias strings   List of tablet aliases to filter by.
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

