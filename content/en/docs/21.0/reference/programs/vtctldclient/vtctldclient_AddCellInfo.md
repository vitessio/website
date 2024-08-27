---
title: AddCellInfo
series: vtctldclient
commit: 4bc3b998941037e0446f5c0899587e4093d79f57
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
      --action_timeout duration              timeout to use for the command (default 1h0m0s)
      --compact                              use compact format for otherwise verbose outputs
      --server string                        server to use for the connection (required)
      --topo-global-root string              the path of the global topology data in the global topology server (default "/vitess/global")
      --topo-global-server-address strings   the address of the global topology server(s) (default [localhost:2379])
      --topo-implementation string           the topology implementation to use (default "etcd2")
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

