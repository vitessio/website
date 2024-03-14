---
title: ShardReplicationFix
series: vtctldclient
commit: a7f80a82e5d99cf00c253c3902367bec5fa40e5d
---
## vtctldclient ShardReplicationFix

Walks through a ShardReplication object and fixes the first error encountered.

```
vtctldclient ShardReplicationFix <cell> <keyspace/shard>
```

### Options

```
  -h, --help   help for ShardReplicationFix
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

