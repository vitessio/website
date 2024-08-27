---
title: GenerateShardRanges
series: vtctldclient
commit: 4bc3b998941037e0446f5c0899587e4093d79f57
---
## vtctldclient GenerateShardRanges

Print a set of shard ranges assuming a keyspace with N shards.

```
vtctldclient GenerateShardRanges <num_shards>
```

### Options

```
  -h, --help   help for GenerateShardRanges
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

