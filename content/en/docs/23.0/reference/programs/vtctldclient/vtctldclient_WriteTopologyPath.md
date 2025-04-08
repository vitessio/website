---
title: WriteTopologyPath
series: vtctldclient
---
## vtctldclient WriteTopologyPath

Copies a local file to the topology server at the given path.

```
vtctldclient WriteTopologyPath --server=local <path> <file>
```

### Options

```
      --cell string   Topology server cell to copy the file to. (default "global")
  -h, --help          help for WriteTopologyPath
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

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server or alternatively as a standalone binary using --server=internal.

