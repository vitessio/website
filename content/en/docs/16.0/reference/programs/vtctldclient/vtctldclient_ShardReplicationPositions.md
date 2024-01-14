---
title: ShardReplicationPositions
series: vtctldclient
commit: 6c9f87de69a1fdbf6a68ff8375b32a1c2abba291
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
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

