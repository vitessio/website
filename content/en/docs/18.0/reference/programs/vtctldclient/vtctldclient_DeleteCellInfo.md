---
title: DeleteCellInfo
series: vtctldclient
commit: 9a6f5262f7707ff80ce85c111d2ff686d85d29cc
---
## vtctldclient DeleteCellInfo

Deletes the CellInfo for the provided cell.

### Synopsis

Deletes the CellInfo for the provided cell. The cell cannot be referenced by any Shard record.

```
vtctldclient DeleteCellInfo [--force] <cell>
```

### Options

```
  -f, --force   Proceeds even if the cell's topology server cannot be reached. The assumption is that you shut down the entire cell, and just need to update the global topo data.
  -h, --help    help for DeleteCellInfo
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout to use for the command (default 1h0m0s)
      --compact                   use compact format for otherwise verbose outputs
      --server string             server to use for the connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

