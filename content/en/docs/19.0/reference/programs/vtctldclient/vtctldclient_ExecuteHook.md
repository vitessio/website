---
title: ExecuteHook
series: vtctldclient
commit: 0f751fbb7c64ca5280c5d4f58d038e1df5477c67
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
      --action_timeout duration   timeout to use for the command (default 1h0m0s)
      --compact                   use compact format for otherwise verbose outputs
      --server string             server to use for the connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

