---
title: EmergencyReparentShard
series: vtctldclient
commit: 6cd09cce61fa79a1b7aacb36886b7dc44ae82a94
---
## vtctldclient EmergencyReparentShard

Reparents the shard to the new primary. Assumes the old primary is dead and not responding.

```
vtctldclient EmergencyReparentShard <keyspace/shard>
```

### Options

```
  -h, --help                             help for EmergencyReparentShard
  -i, --ignore-replicas strings          Comma-separated, repeated list of replica tablet aliases to ignore during the emergency reparent.
      --new-primary string               Alias of a tablet that should be the new primary. If not specified, the vtctld will select the best candidate to promote.
      --prevent-cross-cell-promotion     Only promotes a new primary from the same cell as the previous primary.
      --wait-for-all-tablets             Should ERS wait for all the tablets to respond. Useful when all the tablets are reachable.
      --wait-replicas-timeout duration   Time to wait for replicas to catch up in reparenting. (default 15s)
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

