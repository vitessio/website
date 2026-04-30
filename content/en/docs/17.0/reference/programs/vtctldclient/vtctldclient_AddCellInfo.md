---
title: AddCellInfo
series: vtctldclient
commit: 3ae5c005a75f782a004e8992be4a4fb95460458e
---
## vtctldclient AddCellInfo

Registers a local topology service in a new cell by creating the CellInfo.

### Synopsis

Registers a local topology service in a new cell by creating the CellInfo
with the provided parameters.

The address will be used to connect to the topology service, and Vitess data will
be stored starting at the provided root.

```
vtctldclient AddCellInfo --root <root> [--server-address <addr>] <cell>
```

### Options

```
  -h, --help                    help for AddCellInfo
  -r, --root string             The root path the topology server will use for this cell.
  -a, --server-address string   The address the topology server will connect to for this cell.
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

