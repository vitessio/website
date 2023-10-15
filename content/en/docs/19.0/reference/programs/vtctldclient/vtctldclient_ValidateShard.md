---
title: ValidateShard
series: vtctldclient
commit: 314ebcf13923f98945595208d5099eca4a7184ea
---
## vtctldclient ValidateShard

Validates that all nodes reachable from the specified shard are consistent.

```
vtctldclient ValidateShard [--ping-tablets] <keyspace/shard>
```

### Options

```
  -h, --help           help for ValidateShard
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

