---
title: GetTopologyPath
series: vtctldclient
commit: b0b79813f21f8ecbf409f558ad6f8864332637cf
---
## vtctldclient GetTopologyPath

Gets the value associated with the particular path (key) in the topology server.

```
vtctldclient GetTopologyPath <path>
```

### Options

```
      --data-as-json   If true, only the data is output and it is in JSON format rather than prototext.
  -h, --help           help for GetTopologyPath
      --version int    The version of the path's key to get. If not specified, the latest version is returned.
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

