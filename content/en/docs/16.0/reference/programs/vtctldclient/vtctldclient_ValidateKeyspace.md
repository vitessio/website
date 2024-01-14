---
title: ValidateKeyspace
series: vtctldclient
commit: 6c9f87de69a1fdbf6a68ff8375b32a1c2abba291
---
## vtctldclient ValidateKeyspace

Validates that all nodes reachable from the specified keyspace are consistent.

```
vtctldclient ValidateKeyspace [--ping-tablets] <keyspace>
```

### Options

```
  -h, --help           help for ValidateKeyspace
  -p, --ping-tablets   Indicates whether all tablets should be pinged during the validation process.
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

