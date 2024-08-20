---
title: Materialize stop
series: vtctldclient
commit: cd0c2b594b2d5178a9c8ac081eaee7d1b7eef28a
---

## vtctldclient Materialize stop

Stop a Materialize workflow.

```
vtctldclient Materialize stop
```

### Examples

```
vtctldclient --server localhost:15999 Materialize --workflow product_sales --target-keyspace customer stop
```

### Options

```
  -h, --help   help for stop
```

### Options Inherited from Parent Commands

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

### See Also

* [vtctldclient Materialize](../)	 - Perform commands related to materializing query results from the source keyspace into tables in the target keyspace.

