---
title: PingTablet
series: vtctldclient
description:
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
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

