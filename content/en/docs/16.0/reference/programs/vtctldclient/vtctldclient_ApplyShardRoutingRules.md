---
title: ApplyShardRoutingRules
series: vtctldclient
---
## vtctldclient ApplyShardRoutingRules

Applies VSchema shard routing rules.

```
vtctldclient ApplyShardRoutingRules {--rules RULES | --rules-file RULES_FILE} [--cells=c1,c2,...] [--skip-rebuild] [--dry-run]
```

### Options

```
  -c, --cells strings       Limit the VSchema graph rebuilding to the specified cells. Ignored if --skip-rebuild is specified.
  -d, --dry-run             Validate the specified shard routing rules and note actions that would be taken, but do not actually apply the rules to the topo.
  -h, --help                help for ApplyShardRoutingRules
  -r, --rules string        Shard routing rules, specified as a string
  -f, --rules-file string   Path to a file containing shard routing rules specified as JSON
      --skip-rebuild        Skip rebuilding the SrvVSchema objects.
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

