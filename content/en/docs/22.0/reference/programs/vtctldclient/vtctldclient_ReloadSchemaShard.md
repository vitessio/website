---
title: ReloadSchemaShard
series: vtctldclient
commit: 76350bd01072921484303a16e9879f69d907f6f3
---
## vtctldclient ReloadSchemaShard

Reloads the schema on all tablets in a shard. This is done on a best-effort basis.

```
vtctldclient ReloadSchemaShard [--concurrency=10] [--include-primary] <keyspace/shard>
```

### Options

```
      --concurrency int32   Number of tablets to reload in parallel. Set to zero for unbounded concurrency. (default 10)
  -h, --help                help for ReloadSchemaShard
      --include-primary     Also reload the primary tablet.
```

### Options inherited from parent commands

```
      --action_timeout duration              timeout to use for the command (default 1h0m0s)
      --compact                              use compact format for otherwise verbose outputs
      --server string                        server to use for the connection (required)
      --topo-global-root string              the path of the global topology data in the global topology server (default "/vitess/global")
      --topo-global-server-address strings   the address of the global topology server(s) (default [localhost:2379])
      --topo-implementation string           the topology implementation to use (default "etcd2")
```

### SEE ALSO

* [vtctldclient](../)	 - Executes a cluster management command on the remote vtctld server.

