---
title: InitShardPrimary
series: vtctldclient
---
## vtctldclient InitShardPrimary

Sets the initial primary for the shard.

### Synopsis

This command has been deprecated. Please use PlannedReparentShard instead.

Sets the initial primary for the shard.

This will make all other tablets in the shard become replicas of the promoted tablet.
WARNING: this can cause data loss on an already-replicating shard.


```
vtctldclient InitShardPrimary <keyspace/shard> <primary alias>
```

### Options

```
      --force                            Force the reparent even if the provided tablet is not writable or the shard primary.
  -h, --help                             help for InitShardPrimary
      --wait-replicas-timeout duration   Time to wait for replicas to catch up in reparenting. (default 30s)
```

### Options Inherited from Parent Commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### See Also

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

