---
title: VDiff delete
series: vtctldclient
commit: 471ab1a20a1f7f1f333ddd378b3edc71ad6de7a3
---
## vtctldclient VDiff delete

Delete VDiffs.

```
vtctldclient VDiff delete
```

### Examples

```
vtctldclient --server localhost:15999 vdiff --workflow commerce2customer --target-keyspace customer delete a037a9e2-5628-11ee-8c99-0242ac120002
vtctldclient --server localhost:15999 vdiff --workflow commerce2customer --target-keyspace delete all
```

### Options

```
  -h, --help   help for delete
```

### Options inherited from parent commands

```
      --action_timeout duration              timeout to use for the command (default 1h0m0s)
      --compact                              use compact format for otherwise verbose outputs
      --format string                        The format of the output; supported formats are: text,json. (default "text")
      --server string                        server to use for the connection (required)
      --target-keyspace string               Target keyspace for this workflow.
      --topo-global-root string              the path of the global topology data in the global topology server (default "/vitess/global")
      --topo-global-server-address strings   the address of the global topology server(s) (default [localhost:2379])
      --topo-implementation string           the topology implementation to use (default "etcd2")
  -w, --workflow string                      The workflow you want to perform the command on.
```

### SEE ALSO

* [vtctldclient VDiff](./vtctldclient_vdiff/)	 - Perform commands related to diffing tables involved in a VReplication workflow between the source and target.

