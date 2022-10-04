---
title: GetShardRoutingRules
series: vtctldclient
---
## vtctldclient GetShardRoutingRules

Returns the currently active shard routing rules as a JSON document. See the documentation on [shard level migrations](../../../vreplication/shardlevelmigrations/) for more information.

```
vtctldclient GetShardRoutingRules
```

### Options

```
  -h, --help               help for GetShardRoutingRules
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

