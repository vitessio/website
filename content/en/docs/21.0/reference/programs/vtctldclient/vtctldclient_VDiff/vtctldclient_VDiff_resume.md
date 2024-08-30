---
title: VDiff resume
series: vtctldclient
commit: bc454ac97c1b595141ae098cb8cd531f9c427404
---
## vtctldclient VDiff resume

Resume a VDiff.

```
vtctldclient VDiff resume
```

### Examples

```
vtctldclient --server localhost:15999 vdiff --workflow commerce2customer --target-keyspace customer resume a037a9e2-5628-11ee-8c99-0242ac120002
```

### Options

```
  -h, --help                    help for resume
      --target-shards strings   The target shards to resume the vdiff on; default is all shards.
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

* [vtctldclient VDiff](../)	 - Perform commands related to diffing tables involved in a VReplication workflow between the source and target.

