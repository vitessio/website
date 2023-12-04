---
title: GetBackups
series: vtctldclient
commit: 9a6f5262f7707ff80ce85c111d2ff686d85d29cc
---
## vtctldclient GetBackups

Lists backups for the given shard.

```
vtctldclient GetBackups [--limit <limit>] [--json] <keyspace/shard>
```

### Options

```
  -h, --help           help for GetBackups
  -j, --json           Output backup info in JSON format rather than a list of backups.
  -l, --limit uint32   Retrieve only the most recent N backups.
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout to use for the command (default 1h0m0s)
      --compact                   use compact format for otherwise verbose outputs
      --server string             server to use for the connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

