---
title: Reshard cancel
series: vtctldclient
commit: b9b567acbb1f36404f46b5daa168d37831dd137f
---
## vtctldclient Reshard cancel

Cancel a Reshard VReplication workflow.

```
vtctldclient Reshard cancel
```

### Examples

```
vtctldclient --server localhost:15999 Reshard --workflow cust2cust --target-keyspace customer cancel
```

### Options

```
  -h, --help   help for cancel
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

* [vtctldclient Reshard](../)	 - Perform commands related to resharding a keyspace.

