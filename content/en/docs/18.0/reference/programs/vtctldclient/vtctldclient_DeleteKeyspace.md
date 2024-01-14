---
title: DeleteKeyspace
series: vtctldclient
commit: d3012c188ea0cfc6837917fc6642ea23be9bb1ff
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
      --action_timeout duration   timeout to use for the command (default 1h0m0s)
      --compact                   use compact format for otherwise verbose outputs
      --server string             server to use for the connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

