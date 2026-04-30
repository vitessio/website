---
title: ReloadSchemaShard
series: vtctldclient
commit: 3ae5c005a75f782a004e8992be4a4fb95460458e
---
## vtctldclient ReloadSchemaShard

Reloads the schema on all tablets in a shard. This is done on a best-effort basis.

```
vtctldclient ReloadSchemaShard [--concurrency=10] [--include-primary] <keyspace/shard>
```

### Options

```
      --concurrency uint32   Number of tablets to reload in parallel. Set to zero for unbounded concurrency. (default 10)
  -h, --help                 help for ReloadSchemaShard
      --include-primary      Also reload the primary tablet.
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout for the total command (default 1h0m0s)
      --server string             server to use for connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

