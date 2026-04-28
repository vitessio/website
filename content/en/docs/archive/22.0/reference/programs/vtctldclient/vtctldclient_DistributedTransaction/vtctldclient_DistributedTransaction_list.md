---
title: DistributedTransaction list
series: vtctldclient
commit: 069651aed3c06088dc00f8f699a276665056e3d0
---
## vtctldclient DistributedTransaction list

Retrieves unresolved transactions for the given keyspace.

```
vtctldclient DistributedTransaction list <keyspace>
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

* [vtctldclient DistributedTransaction](../)	 - Perform commands on distributed transaction

