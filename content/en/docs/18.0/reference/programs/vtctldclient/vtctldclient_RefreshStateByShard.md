---
title: RefreshStateByShard
series: vtctldclient
commit: 9a6f5262f7707ff80ce85c111d2ff686d85d29cc
---
## vtctldclient RefreshStateByShard

Reloads the tablet record all tablets in the shard, optionally limited to the specified cells.

```
vtctldclient RefreshStateByShard [--cell <cell1> ...] <keyspace/shard>
```

### Options

```
  -c, --cells strings   If specified, only call RefreshState on tablets in the specified cells. If empty, all cells are considered.
  -h, --help            help for RefreshStateByShard
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout to use for the command (default 1h0m0s)
      --compact                   use compact format for otherwise verbose outputs
      --server string             server to use for the connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

