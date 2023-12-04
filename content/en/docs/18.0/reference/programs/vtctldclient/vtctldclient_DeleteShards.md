---
title: DeleteShards
series: vtctldclient
commit: 9a6f5262f7707ff80ce85c111d2ff686d85d29cc
---
## vtctldclient DeleteShards

Deletes the specified shards from the topology.

### Synopsis

Deletes the specified shards from the topology.

In recursive mode, it also deletes all tablets belonging to the shard.
Otherwise, the shard must be empty (have no tablets) or returns an error for
that shard.

```
vtctldclient DeleteShards [--recursive|-r] [--even-if-serving] [--force|-f] <keyspace/shard> [<keyspace/shard> ...]
```

### Options

```
      --even-if-serving   Remove the shard even if it is serving. Use with caution.
  -f, --force             Remove the shard even if it cannot be locked; this should only be used for cleanup operations.
  -h, --help              help for DeleteShards
  -r, --recursive         Also delete all tablets belonging to the shard. This is required to delete a non-empty shard.
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout to use for the command (default 1h0m0s)
      --compact                   use compact format for otherwise verbose outputs
      --server string             server to use for the connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

