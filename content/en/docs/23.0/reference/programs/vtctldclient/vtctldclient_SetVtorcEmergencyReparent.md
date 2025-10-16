---
title: SetVtorcEmergencyReparent
series: vtctldclient
---
## vtctldclient SetVtorcEmergencyReparent

Enable/disables the use of EmergencyReparentShard in VTOrc recoveries for a given keyspace or keyspace/shard.

```
vtctldclient SetVtorcEmergencyReparent [--enable|-e] [--disable|-d] <keyspace> <shard>
```

### Options

```
  -d, --disable   Disable the use of EmergencyReparentShard in recoveries.
  -e, --enable    Enable the use of EmergencyReparentShard in recoveries.
  -h, --help      help for SetVtorcEmergencyReparent
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

