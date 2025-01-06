---
title: DistributedTransaction get-info
series: vtctldclient
commit: d9ab9f7a1cf3cae19a1ea06963798a7646e8fb27
---
## vtctldclient DistributedTransaction get-info

Reads the state of the unresolved transaction by querying each participating shard.

```
vtctldclient DistributedTransaction get-info --dtid <dtid>
```

### Options

```
  -d, --dtid string   read transaction state for the given distributed transaction ID.
  -h, --help          help for get-info
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

