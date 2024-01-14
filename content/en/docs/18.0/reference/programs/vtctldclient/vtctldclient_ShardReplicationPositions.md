---
title: ShardReplicationPositions
series: vtctldclient
commit: d3012c188ea0cfc6837917fc6642ea23be9bb1ff
---
## vtctldclient ShardReplicationPositions



### Synopsis

Shows the replication status of each tablet in the shard graph.
Output is sorted by tablet type, then replication position.
Use ctrl-C to interrupt the command and see partial results if needed.

```
vtctldclient ShardReplicationPositions <keyspace/shard>
```

### Options

```
  -h, --help   help for ShardReplicationPositions
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout to use for the command (default 1h0m0s)
      --compact                   use compact format for otherwise verbose outputs
      --server string             server to use for the connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

