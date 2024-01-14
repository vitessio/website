---
title: DeleteCellInfo
series: vtctldclient
commit: d3012c188ea0cfc6837917fc6642ea23be9bb1ff
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

