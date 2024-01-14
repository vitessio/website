---
title: ReloadSchemaKeyspace
series: vtctldclient
commit: d3012c188ea0cfc6837917fc6642ea23be9bb1ff
---
## vtctldclient ReloadSchemaKeyspace

Reloads the schema on all tablets in a keyspace. This is done on a best-effort basis.

```
vtctldclient ReloadSchemaKeyspace [--concurrency=<concurrency>] [--include-primary] <keyspace>
```

### Options

```
      --concurrency uint32   Number of tablets to reload in parallel. Set to zero for unbounded concurrency. (default 10)
  -h, --help                 help for ReloadSchemaKeyspace
      --include-primary      Also reload the primary tablets.
```

### Options inherited from parent commands

```
      --action_timeout duration   timeout to use for the command (default 1h0m0s)
      --compact                   use compact format for otherwise verbose outputs
      --server string             server to use for the connection (required)
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

