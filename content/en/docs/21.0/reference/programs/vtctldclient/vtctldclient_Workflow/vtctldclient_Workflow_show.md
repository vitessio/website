---
title: Workflow show
series: vtctldclient
commit: 14b6873142558358a99a68d2b5ef0ec204f3776a
---
## vtctldclient Workflow show

Show the details for a VReplication workflow.

```
vtctldclient Workflow show
```

### Examples

```
vtctldclient --server localhost:15999 workflow --keyspace customer show --workflow commerce2customer
```

### Options

```
  -h, --help              help for show
      --include-logs      Include recent logs for the workflow. (default true)
      --shards strings    (Optional) Specifies a comma-separated list of shards to operate on.
  -w, --workflow string   The workflow you want the details for.
```

### Options inherited from parent commands

```
      --action_timeout duration              timeout to use for the command (default 1h0m0s)
      --compact                              use compact format for otherwise verbose outputs
  -k, --keyspace string                      Keyspace context for the workflow.
      --server string                        server to use for the connection (required)
      --topo-global-root string              the path of the global topology data in the global topology server (default "/vitess/global")
      --topo-global-server-address strings   the address of the global topology server(s) (default [localhost:2379])
      --topo-implementation string           the topology implementation to use (default "etcd2")
```

### SEE ALSO

* [vtctldclient Workflow](../)	 - Administer VReplication workflows (Reshard, MoveTables, etc) in the given keyspace.

