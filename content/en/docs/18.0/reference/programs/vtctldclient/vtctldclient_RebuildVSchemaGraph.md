---
title: RebuildVSchemaGraph
series: vtctldclient
commit: 9a6f5262f7707ff80ce85c111d2ff686d85d29cc
---
## vtctldclient RebuildVSchemaGraph

Rebuilds the cell-specific SrvVSchema from the global VSchema objects in the provided cells (or all cells if none provided).

```
vtctldclient RebuildVSchemaGraph [--cells=c1,c2,...]
```

### Options

```
  -c, --cells strings   Specifies a comma-separated list of cells to look for tablets.
  -h, --help            help for RebuildVSchemaGraph
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout to use for the command (default 1h0m0s)
      --compact                   use compact format for otherwise verbose outputs
      --server string             server to use for the connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

