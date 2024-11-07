---
title: ValidateVersionShard
series: vtctldclient
commit: d3ff5982ddbbb04da1c9ac3c0bff9b09c904c749
---
## vtctldclient ValidateVersionShard

Validates that the version on the primary matches all of the replicas.

```
vtctldclient ValidateVersionShard <keyspace/shard>
```

### Options

```
  -h, --help   help for ValidateVersionShard
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout to use for the command (default 1h0m0s)
      --compact                   use compact format for otherwise verbose outputs
      --server string             server to use for the connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

