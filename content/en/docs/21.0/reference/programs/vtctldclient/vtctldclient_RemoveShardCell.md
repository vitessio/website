---
title: RemoveShardCell
series: vtctldclient
commit: f52a0b141fd20db5af050f5d0e2d8724597b60c0
---
## vtctldclient RemoveShardCell

Remove the specified cell from the specified shard's Cells list.

```
vtctldclient RemoveShardCell [--force|-f] [--recursive|-r] <keyspace/shard> <cell>
```

### Options

```
  -f, --force       Proceed even if the cell's topology server cannot be reached. The assumption is that you turned down the entire cell, and just need to update the global topo data.
  -h, --help        help for RemoveShardCell
  -r, --recursive   Also delete all tablets in that cell beloning to the specified shard.
```

### Options inherited from parent commands

```
      --action_timeout duration              timeout to use for the command (default 1h0m0s)
      --compact                              use compact format for otherwise verbose outputs
      --server string                        server to use for the connection (required)
      --topo-global-root string              the path of the global topology data in the global topology server (default "/vitess/global")
      --topo-global-server-address strings   the address of the global topology server(s) (default [localhost:2379])
      --topo-implementation string           the topology implementation to use (default "etcd2")
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

