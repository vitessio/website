---
title: ValidateKeyspace
series: vtctldclient
commit: 0f751fbb7c64ca5280c5d4f58d038e1df5477c67
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
      --action_timeout duration   timeout to use for the command (default 1h0m0s)
      --compact                   use compact format for otherwise verbose outputs
      --server string             server to use for the connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

