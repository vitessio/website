---
title: DistributedTransaction unresolved-list
series: vtctldclient
commit: b0b79813f21f8ecbf409f558ad6f8864332637cf
---
## vtctldclient DistributedTransaction unresolved-list

Retrieves unresolved transactions for the given keyspace.

```
vtctldclient DistributedTransaction unresolved-list --keyspace <keyspace> --abandon-age <abandon_time_seconds>
```

### Options

```
  -a, --abandon-age int   unresolved transactions list which are older than the specified age(in seconds).
  -h, --help              help for unresolved-list
  -k, --keyspace string   unresolved transactions list for the given keyspace.
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

