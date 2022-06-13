---
title: InitShardPrimary
series: vtctldclient
description:
---
## vtctldclient InitShardPrimary



```
vtctldclient InitShardPrimary <keyspace/shard> <primary alias> [flags]
```

### Options

```
      --force                            will force the reparent even if the provided tablet is not writable or the shard primary
  -h, --help                             help for InitShardPrimary
      --wait-replicas-timeout duration   time to wait for replicas to catch up in reparenting (default 30s)
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

