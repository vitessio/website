---
title: RebuildVSchemaGraph
series: vtctldclient
commit: 3ae5c005a75f782a004e8992be4a4fb95460458e
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
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

