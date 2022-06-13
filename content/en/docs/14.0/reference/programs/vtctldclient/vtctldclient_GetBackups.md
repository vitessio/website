---
title: GetBackups
series: vtctldclient
description:
---
## vtctldclient GetBackups



```
vtctldclient GetBackups <keyspace/shard> [flags]
```

### Options

```
  -h, --help           help for GetBackups
  -j, --json           Output backup info in JSON format rather than a list of backups
  -l, --limit uint32   Retrieve only the most recent N backups
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.
