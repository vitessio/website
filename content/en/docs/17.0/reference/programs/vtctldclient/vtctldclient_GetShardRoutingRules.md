---
title: GetShardRoutingRules
series: vtctldclient
commit: 9a3d0f4a69a840cfa2cb86654abd4afa0be6e0aa
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
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

