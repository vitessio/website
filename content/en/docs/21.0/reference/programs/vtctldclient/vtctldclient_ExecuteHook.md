---
title: ExecuteHook
series: vtctldclient
commit: 14b6873142558358a99a68d2b5ef0ec204f3776a
---
## vtctldclient ExecuteHook

Runs the specified hook on the given tablet.

### Synopsis

Runs the specified hook on the given tablet.

A hook is an executable script that resides in the ${VTROOT}/vthook directory.
For ExecuteHook, this is on the tablet requested, not on the vtctld or the host
running the vtctldclient.

Any key-value pairs passed after the hook name will be passed as parameters to
the hook on the tablet.

Note: hook names may not contain slash (/) characters.


```
vtctldclient ExecuteHook <alias> <hook_name> [<param1=value1> ...]
```

### Options

```
  -h, --help   help for ExecuteHook
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

