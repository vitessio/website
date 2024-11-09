---
title: RunHealthCheck
series: vtctldclient
commit: d3ff5982ddbbb04da1c9ac3c0bff9b09c904c749
---
## vtctldclient RunHealthCheck

Runs a healthcheck on the remote tablet.

```
vtctldclient RunHealthCheck <tablet_alias>
```

### Options

```
  -h, --help   help for RunHealthCheck
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout to use for the command (default 1h0m0s)
      --compact                   use compact format for otherwise verbose outputs
      --server string             server to use for the connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

