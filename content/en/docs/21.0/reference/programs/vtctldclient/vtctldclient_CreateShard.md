---
title: CreateShard
series: vtctldclient
commit: 376c478ce7daca627d063f22af9121e173787e31
---
## vtctldclient CreateShard

Creates the specified shard in the topology.

```
vtctldclient CreateShard [--force|-f] [--include-parent|-p] <keyspace/shard>
```

### Options

```
  -f, --force            Overwrite an existing shard record, if one exists.
  -h, --help             help for CreateShard
  -p, --include-parent   Creates the parent keyspace record if does not already exist.
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

