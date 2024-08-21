---
title: ApplyShardRoutingRules
series: vtctldclient
commit: 4bc3b998941037e0446f5c0899587e4093d79f57
---
## vtctldclient ApplyShardRoutingRules

Applies the provided shard routing rules.

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
      --action_timeout duration              timeout to use for the command (default 1h0m0s)
      --compact                              use compact format for otherwise verbose outputs
      --server string                        server to use for the connection (required)
      --topo-global-root string              the path of the global topology data in the global topology server (default "/vitess/global")
      --topo-global-server-address strings   the address of the global topology server(s) (default [localhost:2379])
      --topo-implementation string           the topology implementation to use (default "etcd2")
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

