---
title: ApplyShardRoutingRules
series: vtctldclient
---
## vtctldclient ApplyShardRoutingRules

Applies the provided shard routing rules. See the documentation on [shard level migrations](../../../vreplication/shardlevelmigrations/) for more information.

```
vtctldclient ApplyShardRoutingRules {--rules RULES | --rules-file RULES_FILE} [--skip-rebuild] [--dry-run]
```

### Options

```
  -h, --help               help for ApplyShardRoutingRules
      --rules RULES        JSON string of the shard routing rules to apply
      --rules-file         Path to a file containing the shard routing rules to apply as a JSON document
      --skip-rebuild       Don't rebuild the SrvVSchema after applying the rules (if you want to delay enforcement of the new rules)
      --dry-run            Don't actually apply the rules, just print informtion about the work that would be done
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

