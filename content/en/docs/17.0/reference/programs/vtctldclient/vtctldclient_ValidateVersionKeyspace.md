---
title: ValidateVersionKeyspace
series: vtctldclient
commit: 9a3628037518bc108c636220319f3c7385b2a559
---
## vtctldclient ValidateVersionKeyspace

Validates that the version on the primary tablet of shard 0 matches all of the other tablets in the keyspace.

```
vtctldclient ValidateVersionKeyspace <keyspace>
```

### Options

```
  -h, --help   help for ValidateVersionKeyspace
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

