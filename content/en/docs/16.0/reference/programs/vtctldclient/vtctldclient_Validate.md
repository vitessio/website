---
title: Validate
series: vtctldclient
commit: 6c9f87de69a1fdbf6a68ff8375b32a1c2abba291
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
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

