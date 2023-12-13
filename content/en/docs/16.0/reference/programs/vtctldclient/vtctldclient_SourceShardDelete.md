---
title: SourceShardDelete
series: vtctldclient
commit: a7f80a82e5d99cf00c253c3902367bec5fa40e5d
---
## vtctldclient SourceShardDelete

Deletes the SourceShard record with the provided index. This should only be used for emergency cleanup. It does not call RefreshState for the shard primary.

```
vtctldclient SourceShardDelete <keyspace/shard> <uid>
```

### Options

```
  -h, --help   help for SourceShardDelete
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

