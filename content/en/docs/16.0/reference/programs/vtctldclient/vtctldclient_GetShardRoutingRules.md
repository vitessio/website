---
title: GetShardRoutingRules
series: vtctldclient
commit: 6c9f87de69a1fdbf6a68ff8375b32a1c2abba291
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

