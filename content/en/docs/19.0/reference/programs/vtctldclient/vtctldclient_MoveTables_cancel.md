---
title: MoveTables cancel
series: vtctldclient
commit: f751c8323ff52c90f288481b0bd92192f1734973
---
## vtctldclient MoveTables cancel

Cancel a MoveTables VReplication workflow.

```
vtctldclient MoveTables cancel
```

### Examples

```
vtctldclient --server localhost:15999 MoveTables --workflow commerce2customer --target-keyspace customer cancel
```

### Options

```
  -h, --help                 help for cancel
      --keep-data            Keep the partially copied table data from the MoveTables workflow in the target keyspace.
      --keep-routing-rules   Keep the routing rules created for the MoveTables workflow.
      --shards strings       (Optional) Specifies a comma-separated list of shards to operate on.
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

* [vtctldclient MoveTables](./vtctldclient_movetables/)	 - Perform commands related to moving tables from a source keyspace to a target keyspace.

