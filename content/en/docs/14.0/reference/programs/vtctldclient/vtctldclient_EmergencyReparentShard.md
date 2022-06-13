---
title: EmergencyReparentShard
series: vtctldclient
description:
---
## vtctldclient EmergencyReparentShard



### Synopsis

Reparents the shard to the new primary. Assumes the old primary is dead and not responding

```
vtctldclient EmergencyReparentShard <keyspace/shard> [flags]
```

### Options

```
  -h, --help                             help for EmergencyReparentShard
  -i, --ignore-replicas strings          Comma-separated, repeated list of replica tablet aliases to ignore during the emergency reparent.
      --new-primary string               Alias of a tablet that should be the new primary. If not specified, the vtctld will select the best candidate to promote.
      --prevent-cross-cell-promotion     Only promotes a new primary from the same cell as the previous primary
      --wait-replicas-timeout duration   Time to wait for replicas to catch up in reparenting. (default 30s)
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.
