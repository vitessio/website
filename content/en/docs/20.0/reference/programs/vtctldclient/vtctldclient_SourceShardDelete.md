---
title: SourceShardDelete
series: vtctldclient
commit: 3b906cf6a3cedd9d216eaee4e162025d408beee9
---
## vtctldclient SourceShardDelete

Deletes the SourceShard record with the provided index. This should only be used for emergency cleanup. It does not call RefreshState for the shard primary.

```
vtctldclient SourceShardDelete <keyspace/shard> <uid>
```

### Options

```
  -h, --help   help for SourceShardDelete
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

