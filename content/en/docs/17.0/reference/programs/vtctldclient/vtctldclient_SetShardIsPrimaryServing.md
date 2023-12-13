---
title: SetShardIsPrimaryServing
series: vtctldclient
commit: 9a3d0f4a69a840cfa2cb86654abd4afa0be6e0aa
---
## vtctldclient SetShardIsPrimaryServing

Add or remove a shard from serving. This is meant as an emergency function. It does not rebuild any serving graphs; i.e. it does not run `RebuildKeyspaceGraph`.

```
vtctldclient SetShardIsPrimaryServing <keyspace/shard> <true/false>
```

### Options

```
  -h, --help   help for SetShardIsPrimaryServing
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

