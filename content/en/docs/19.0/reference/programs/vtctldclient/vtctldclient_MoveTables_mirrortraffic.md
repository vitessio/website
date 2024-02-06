---
title: MoveTables mirrortraffic
series: vtctldclient
commit: 6eb2e70db701a94eab08ba8b4137a98b640f7511
---
## vtctldclient MoveTables mirrortraffic

Mirror traffic for a MoveTables VReplication workflow.

```
vtctldclient MoveTables mirrortraffic
```

### Examples

```
vtctldclient --server localhost:15999 MoveTables --workflow commerce2customer --target-keyspace customer mirrortraffic --percent 50.0
```

### Options

```
  -h, --help              help for mirrortraffic
      --percent float32   Percentage of traffic to mirror. (default 1)
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

