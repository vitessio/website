---
title: Validate
series: vtctldclient
commit: fe3121946231107b737e319b680c9686396b9ce1
---
## vtctldclient Validate

Validates that all nodes reachable from the global replication graph, as well as all tablets in discoverable cells, are consistent.

```
vtctldclient Validate [--ping-tablets]
```

### Options

```
  -h, --help           help for Validate
  -p, --ping-tablets   Indicates whether all tablets should be pinged during the validation process.
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout to use for the command (default 1h0m0s)
      --compact                   use compact format for otherwise verbose outputs
      --server string             server to use for the connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

