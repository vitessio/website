---
title: RemoveKeyspaceCell
series: vtctldclient
commit: a7f80a82e5d99cf00c253c3902367bec5fa40e5d
---
## vtctldclient RemoveKeyspaceCell

Removes the specified cell from the Cells list for all shards in the specified keyspace (by calling RemoveShardCell on every shard). It also removes the SrvKeyspace for that keyspace in that cell.

```
vtctldclient RemoveKeyspaceCell [--force|-f] [--recursive|-r] <keyspace> <cell>
```

### Options

```
  -f, --force       Proceed even if the cell's topology server cannot be reached. The assumption is that you turned down the entire cell, and just need to update the global topo data.
  -h, --help        help for RemoveKeyspaceCell
  -r, --recursive   Also delete all tablets in that cell beloning to the specified keyspace.
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

