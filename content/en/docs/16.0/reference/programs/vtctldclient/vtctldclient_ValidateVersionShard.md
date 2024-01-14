---
title: ValidateVersionShard
series: vtctldclient
commit: 6c9f87de69a1fdbf6a68ff8375b32a1c2abba291
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
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

