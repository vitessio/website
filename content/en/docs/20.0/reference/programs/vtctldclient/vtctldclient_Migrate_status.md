---
title: Migrate status
series: vtctldclient
commit: b539ce927ee86b723a94a627cdec1403dd4020f0
---
## vtctldclient Migrate status

Show the current status for a Migrate VReplication workflow.

```
vtctldclient Migrate status
```

### Examples

```
vtctldclient --server localhost:15999 Migrate --workflow import --target-keyspace customer status
```

### Options

```
  -h, --help   help for status
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

* [vtctldclient Migrate](./vtctldclient_migrate/)	 - Migrate is used to import data from an external cluster into the current cluster.

