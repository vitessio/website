---
title: ExecuteHook
series: vtctldclient
commit: 3ae5c005a75f782a004e8992be4a4fb95460458e
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
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

