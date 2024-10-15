---
title: DistributedTransaction
series: vtctldclient
commit: 14b6873142558358a99a68d2b5ef0ec204f3776a
---
## vtctldclient DistributedTransaction

Perform commands on distributed transaction

### Options

```
  -h, --help   help for DistributedTransaction
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
* [vtctldclient DistributedTransaction conclude](./vtctldclient_distributedtransaction_conclude/)	 - Concludes the unresolved transaction by rolling back the prepared transaction on each participating shard and removing the transaction metadata record.
* [vtctldclient DistributedTransaction unresolved-list](./vtctldclient_distributedtransaction_unresolved-list/)	 - Retrieves unresolved transactions for the given keyspace.

