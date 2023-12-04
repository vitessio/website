---
title: RemoveShardCell
series: vtctldclient
commit: 9a6f5262f7707ff80ce85c111d2ff686d85d29cc
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
      --action_timeout duration   timeout to use for the command (default 1h0m0s)
      --compact                   use compact format for otherwise verbose outputs
      --server string             server to use for the connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

