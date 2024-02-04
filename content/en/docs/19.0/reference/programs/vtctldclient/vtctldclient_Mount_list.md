---
title: Mount list
series: vtctldclient
commit: cd4058933e3fe1cd7f2666eb9cce26af8969965a
---
## vtctldclient Mount list

List all mounted external Vitess Clusters.

```
vtctldclient Mount list
```

### Examples

```
vtctldclient --server localhost:15999 mount list
```

### Options

```
  -h, --help   help for list
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

* [vtctldclient Mount](./vtctldclient_mount/)	 - Mount is used to link an external Vitess cluster in order to migrate data from it.

