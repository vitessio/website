---
title: UpdateCellsAlias
series: vtctldclient
description:
---
## vtctldclient UpdateCellsAlias

Updates the content of a CellsAlias with the provided parameters, creating the CellsAlias if it does not exist.

### Synopsis

Updates the content of a CellsAlias with the provided parameters, creating the CellsAlias if it does not exist.

```
vtctldclient UpdateCellsAlias [--cells <cell1,cell2,...> [--cells <cell4> ...]] <alias>
```

### Options

```
  -c, --cells strings   The list of cell names that are members of this alias.
  -h, --help            help for UpdateCellsAlias
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.
