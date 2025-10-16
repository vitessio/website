---
title: GenerateShardRanges
series: vtctldclient
---
## vtctldclient GenerateShardRanges

Print a set of shard ranges assuming a keyspace with N shards.

```
vtctldclient GenerateShardRanges <num_shards> [--hex-width=w]
```

### Options

```
  -h, --help            help for GenerateShardRanges
      --hex-width int   The number of hex characters to use for the shard range start and end. If not set or set to 0, it will be automatically computed based on the number of requested shards.
```

### Options inherited from parent commands

```
      --action-timeout duration              timeout to use for the command (default 1h0m0s)
      --compact                              use compact format for otherwise verbose outputs
      --server string                        server to use for the connection (required)
      --topo-global-root string              the path of the global topology data in the global topology server (default "/vitess/global")
      --topo-global-server-address strings   the address of the global topology server(s) (default [localhost:2379])
      --topo-implementation string           the topology implementation to use (default "etcd2")
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server or alternatively as a standalone binary using --server=internal.

