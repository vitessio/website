---
title: PlannedReparentShard
series: vtctldclient
commit: c823b86a19bfeb9a6a411a75caf492464caf697e
---
## vtctldclient PlannedReparentShard

Reparents the shard to a new primary, or away from an old primary. Both the old and new primaries must be up and running.

```
vtctldclient PlannedReparentShard <keyspace/shard>
```

### Options

```
      --avoid-primary string             Alias of a tablet that should not be the primary; i.e. "reparent to any other tablet if this one is the primary".
  -h, --help                             help for PlannedReparentShard
      --new-primary string               Alias of a tablet that should be the new primary.
      --wait-replicas-timeout duration   Time to wait for replicas to catch up on replication both before and after reparenting. (default 15s)
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout to use for the command (default 1h0m0s)
      --compact                   use compact format for otherwise verbose outputs
      --server string             server to use for the connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

