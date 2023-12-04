---
title: DeleteKeyspace
series: vtctldclient
commit: 9a3d0f4a69a840cfa2cb86654abd4afa0be6e0aa
---
## vtctldclient DeleteKeyspace

Deletes the specified keyspace from the topology.

### Synopsis

Deletes the specified keyspace from the topology.

In recursive mode, it also recursively deletes all shards in the keyspace.
Otherwise, the keyspace must be empty (have no shards), or returns an error.

```
vtctldclient DeleteKeyspace [--recursive|-r] [--force|-f] <keyspace>
```

### Options

```
  -f, --force       Delete the keyspace even if it cannot be locked; this should only be used for cleanup operations.
  -h, --help        help for DeleteKeyspace
  -r, --recursive   Recursively delete all shards in the keyspace, and all tablets in those shards.
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

