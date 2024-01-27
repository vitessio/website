---
title: DeleteSrvVSchema
series: vtctldclient
commit: 6e3190ec7a07a2dbb095ea4e8c69368fa098d41f
---
## vtctldclient DeleteSrvVSchema

Deletes the SrvVSchema object in the given cell.

```
vtctldclient DeleteSrvVSchema <cell>
```

### Options

```
  -h, --help   help for DeleteSrvVSchema
```

### Options inherited from parent commands

```
      --action_timeout duration              timeout to use for the command (default 1h0m0s)
      --andrew-is-testing                    nothing to see here
      --compact                              use compact format for otherwise verbose outputs
      --server string                        server to use for the connection (required)
      --topo-global-root string              the path of the global topology data in the global topology server (default "/vitess/global")
      --topo-global-server-address strings   the address of the global topology server(s) (default [localhost:2379])
      --topo-implementation string           the topology implementation to use (default "etcd2")
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

