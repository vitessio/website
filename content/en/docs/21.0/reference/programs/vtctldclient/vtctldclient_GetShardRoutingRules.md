---
title: GetShardRoutingRules
series: vtctldclient
commit: cd0c2b594b2d5178a9c8ac081eaee7d1b7eef28a
---
## vtctldclient GetShardRoutingRules

Displays the currently active shard routing rules as a JSON document.

### Synopsis

Displays the currently active shard routing rules as a JSON document.

See the documentation on shard level migrations[1] for more information.

[1]: https://vitess.io/docs/reference/vreplication/shardlevelmigrations/

```
vtctldclient GetShardRoutingRules
```

### Options

```
  -h, --help   help for GetShardRoutingRules
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

