---
title: MoveTables reversetraffic
series: vtctldclient
commit: 6dba35de0eeeb6e86d22938f644ac8493d348413
---
## vtctldclient MoveTables reversetraffic

Reverse traffic for a MoveTables VReplication workflow.

```
vtctldclient MoveTables reversetraffic
```

### Examples

```
vtctldclient --server localhost:15999 MoveTables --workflow commerce2customer --target-keyspace customer reversetraffic
```

### Options

```
  -c, --cells strings                          Cells and/or CellAliases to switch traffic in.
      --dry-run                                Print the actions that would be taken and report any known errors that would have occurred.
      --enable-reverse-replication             Setup replication going back to the original source keyspace to support rolling back the traffic cutover. (default true)
  -h, --help                                   help for reversetraffic
      --max-replication-lag-allowed duration   Allow traffic to be switched only if VReplication lag is below this. (default 30s)
      --shards strings                         (Optional) Specifies a comma-separated list of shards to operate on.
      --tablet-types strings                   Tablet types to switch traffic for.
      --timeout duration                       Specifies the maximum time to wait, in seconds, for VReplication to catch up on primary tablets. The traffic switch will be cancelled on timeout. (default 30s)
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

* [vtctldclient MoveTables](../)	 - Perform commands related to moving tables from a source keyspace to a target keyspace.

