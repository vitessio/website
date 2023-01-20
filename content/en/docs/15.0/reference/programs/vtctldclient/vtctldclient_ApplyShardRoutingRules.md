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
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

