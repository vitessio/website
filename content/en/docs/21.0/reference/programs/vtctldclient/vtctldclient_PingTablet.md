---
title: PingTablet
series: vtctldclient
commit: 477bb22995e2e6a6dbaf9b45cc8259c017cb95db
---
## vtctldclient PingTablet

Checks that the specified tablet is awake and responding to RPCs. This command can be blocked by other in-flight operations.

```
vtctldclient PingTablet <alias>
```

### Options

```
  -h, --help   help for PingTablet
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

