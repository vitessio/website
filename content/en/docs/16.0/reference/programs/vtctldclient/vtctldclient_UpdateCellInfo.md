---
title: UpdateCellInfo
series: vtctldclient
commit: a7f80a82e5d99cf00c253c3902367bec5fa40e5d
---
## vtctldclient UpdateCellInfo

Updates the content of a CellInfo with the provided parameters, creating the CellInfo if it does not exist.

### Synopsis

Updates the content of a CellInfo with the provided parameters, creating the CellInfo if it does not exist.

If a value is empty, it is ignored.

```
vtctldclient UpdateCellInfo [--root <root>] [--server-address <addr>] <cell>
```

### Options

```
  -h, --help                    help for UpdateCellInfo
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

