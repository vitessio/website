---
title: PingTablet
series: vtctldclient
commit: d3012c188ea0cfc6837917fc6642ea23be9bb1ff
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
      --action_timeout duration   timeout to use for the command (default 1h0m0s)
      --compact                   use compact format for otherwise verbose outputs
      --server string             server to use for the connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

