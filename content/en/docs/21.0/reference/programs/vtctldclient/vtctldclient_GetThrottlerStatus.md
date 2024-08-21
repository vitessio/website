---
title: GetThrottlerStatus
series: vtctldclient
commit: 471ab1a20a1f7f1f333ddd378b3edc71ad6de7a3
---
## vtctldclient GetThrottlerStatus

Get the throttler status for the given tablet.

```
vtctldclient GetThrottlerStatus <tablet alias>
```

### Examples

```
GetThrottlerStatus zone1-0000000101
```

### Options

```
  -h, --help   help for GetThrottlerStatus
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

