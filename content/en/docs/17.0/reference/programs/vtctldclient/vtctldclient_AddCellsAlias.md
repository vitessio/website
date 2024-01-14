---
title: AddCellsAlias
series: vtctldclient
commit: 9a3628037518bc108c636220319f3c7385b2a559
---
## vtctldclient AddCellsAlias

Defines a group of cells that can be referenced by a single name (the alias).

### Synopsis

Defines a group of cells that can be referenced by a single name (the alias).

When routing query traffic, replica/rdonly traffic can be routed across cells
within the group (alias). Only primary traffic can be routed across cells not in
the same group (alias).

```
vtctldclient AddCellsAlias --cells <cell1,cell2,...> [--cells <cell3> ...] <alias>
```

### Options

```
  -c, --cells strings   The list of cell names that are members of this alias.
  -h, --help            help for AddCellsAlias
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

