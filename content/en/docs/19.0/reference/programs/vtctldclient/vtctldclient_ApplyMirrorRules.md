---
title: ApplyMirrorRules
series: vtctldclient
commit: 6eb2e70db701a94eab08ba8b4137a98b640f7511
---
## vtctldclient ApplyMirrorRules

Applies the VSchema mirror rules.

```
vtctldclient ApplyMirrorRules {--rules RULES | --rules-file RULES_FILE} [--cells=c1,c2,...] [--skip-rebuild] [--dry-run]
```

### Options

```
  -c, --cells strings       Limit the VSchema graph rebuilding to the specified cells. Ignored if --skip-rebuild is specified.
  -d, --dry-run             Load the specified mirror rules as a validation step, but do not actually apply the rules to the topo.
  -h, --help                help for ApplyMirrorRules
  -r, --rules string        Mirror rules, specified as a string.
  -f, --rules-file string   Path to a file containing mirror rules specified as JSON.
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

