---
title: UpdateCellInfo
series: vtctldclient
commit: cd0c2b594b2d5178a9c8ac081eaee7d1b7eef28a
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

### Options Inherited from Parent Commands

```
      --action_timeout duration              timeout to use for the command (default 1h0m0s)
      --compact                              use compact format for otherwise verbose outputs
      --server string                        server to use for the connection (required)
      --topo-global-root string              the path of the global topology data in the global topology server (default "/vitess/global")
      --topo-global-server-address strings   the address of the global topology server(s) (default [localhost:2379])
      --topo-implementation string           the topology implementation to use (default "etcd2")
```

### See Also

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

